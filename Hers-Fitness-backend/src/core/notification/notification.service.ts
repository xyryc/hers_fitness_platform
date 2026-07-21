import { Injectable } from '@nestjs/common';
import { NotificationRepository } from './domain/notification.repository';
import { NotificationPreferenceRepository } from './domain/notification-preference.repository';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { NotificationResponseDto, NotificationUnreadCountResponseDto } from './dto/notification-response.dto';
import {
    NotificationPreferenceResponseDto,
    DEFAULT_MEMBER_PREFERENCES,
    DEFAULT_TRAINER_PREFERENCES,
} from './dto/notification-preference.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';
import { FirebasePushService } from './firebase-push.service';

export enum NotificationType {
    BOOKING_CONFIRMED = 'BOOKING_CONFIRMED',
    BOOKING_PAYMENT_FAILED = 'BOOKING_PAYMENT_FAILED',
    BOOKING_RESCHEDULE_REQUESTED = 'BOOKING_RESCHEDULE_REQUESTED',
    BOOKING_RESCHEDULED = 'BOOKING_RESCHEDULED',
    BOOKING_COMPLETED = 'BOOKING_COMPLETED',
    BOOKING_CANCELLED = 'BOOKING_CANCELLED',
    CLASS_CANCELLED = 'CLASS_CANCELLED',
    CHAT_MESSAGE = 'CHAT_MESSAGE',
    TRAINER_REVIEW_RECEIVED = 'TRAINER_REVIEW_RECEIVED',
    FAVORITE_TRAINER_ADDED = 'FAVORITE_TRAINER_ADDED',
    ACCOUNT_VERIFICATION_APPROVED = 'ACCOUNT_VERIFICATION_APPROVED',
    ACCOUNT_VERIFICATION_REJECTED = 'ACCOUNT_VERIFICATION_REJECTED',
    HELP_TICKET_SUBMITTED = 'HELP_TICKET_SUBMITTED',
    HELP_TICKET_RESOLVED = 'HELP_TICKET_RESOLVED',
    TEST_PUSH = 'TEST_PUSH',
}

export interface SendNotificationInput {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    data?: Record<string, unknown>;
}

@Injectable()
export class NotificationService {
    constructor(
        private readonly notificationRepository: NotificationRepository,
        private readonly notificationPreferenceRepository: NotificationPreferenceRepository,
        private readonly firebasePushService: FirebasePushService,
    ) { }

    // ─── Notification Preferences ────────────────────────────────────────────────

    async getNotificationPreferences(userId: string): Promise<NotificationPreferenceResponseDto> {
        const [pref, role] = await Promise.all([
            this.notificationPreferenceRepository.findByUserId(userId),
            this.notificationPreferenceRepository.findUserRole(userId),
        ]);

        const isMember = role === 'MEMBER';

        if (!pref) {
            return new NotificationPreferenceResponseDto({
                role: isMember ? 'MEMBER' : 'TRAINER',
                ...(isMember ? DEFAULT_MEMBER_PREFERENCES : DEFAULT_TRAINER_PREFERENCES),
            });
        }

        return isMember
            ? new NotificationPreferenceResponseDto({
                role: 'MEMBER',
                bookingConfirmation: pref.bookingConfirmation,
                bookingCancellation: pref.bookingCancellation,
                classReminder:       pref.classReminder,
                paymentConfirmation: pref.paymentConfirmation,
                trainerMessage:      pref.trainerMessage,
                systemAnnouncements: pref.systemAnnouncements,
                pushNotifications:   pref.pushNotifications,
                emailNotifications:  pref.emailNotifications,
            })
            : new NotificationPreferenceResponseDto({
                role: 'TRAINER',
                newBooking:          pref.newBooking,
                classReminder:       pref.classReminder,
                classCheckIn:        pref.classCheckIn,
                paymentReceived:     pref.paymentReceived,
                systemAnnouncements: pref.systemAnnouncements,
                pushNotifications:   pref.pushNotifications,
                emailNotifications:  pref.emailNotifications,
            });
    }

    async updateNotificationPreferences(
        userId: string,
        model: UpdateNotificationPreferenceDto,
    ): Promise<NotificationPreferenceResponseDto> {
        const role = await this.notificationPreferenceRepository.findUserRole(userId);
        const updated = await this.notificationPreferenceRepository.upsert(userId, model);
        const isMember = role === 'MEMBER';

        return isMember
            ? new NotificationPreferenceResponseDto({
                role: 'MEMBER',
                bookingConfirmation: updated.bookingConfirmation,
                bookingCancellation: updated.bookingCancellation,
                classReminder:       updated.classReminder,
                paymentConfirmation: updated.paymentConfirmation,
                trainerMessage:      updated.trainerMessage,
                systemAnnouncements: updated.systemAnnouncements,
                pushNotifications:   updated.pushNotifications,
                emailNotifications:  updated.emailNotifications,
            })
            : new NotificationPreferenceResponseDto({
                role: 'TRAINER',
                newBooking:          updated.newBooking,
                classReminder:       updated.classReminder,
                classCheckIn:        updated.classCheckIn,
                paymentReceived:     updated.paymentReceived,
                systemAnnouncements: updated.systemAnnouncements,
                pushNotifications:   updated.pushNotifications,
                emailNotifications:  updated.emailNotifications,
            });
    }

    async registerDeviceToken(userId: string, model: RegisterDeviceTokenDto): Promise<{ token: string }> {
        const deviceToken = await this.notificationRepository.upsertDeviceToken(userId, model);
        return { token: deviceToken.token };
    }

    async removeDeviceToken(userId: string, token: string): Promise<{ token: string }> {
        await this.notificationRepository.deactivateDeviceToken(userId, token);
        return { token };
    }

    async findNotifications(userId: string, limit: number = 30, offset: number = 0): Promise<NotificationResponseDto[]> {
        const safeLimit = Math.min(Math.max(Number(limit) || 30, 1), 100);
        const safeOffset = Math.max(Number(offset) || 0, 0);
        const notifications = await this.notificationRepository.findNotifications(userId, safeLimit, safeOffset);
        return notifications.map((notification: any) => this.mapNotification(notification));
    }

    async getUnreadCount(userId: string): Promise<NotificationUnreadCountResponseDto> {
        const unreadCount = await this.notificationRepository.countUnread(userId);
        return new NotificationUnreadCountResponseDto({ unreadCount });
    }

    async markRead(userId: string, notificationId: string): Promise<{ notificationId: string }> {
        await this.notificationRepository.markRead(userId, notificationId);
        return { notificationId };
    }

    async markAllRead(userId: string): Promise<{ success: true }> {
        await this.notificationRepository.markAllRead(userId);
        return { success: true };
    }

    async deleteNotification(userId: string, notificationId: string): Promise<{ notificationId: string }> {
        await this.notificationRepository.deleteNotification(userId, notificationId);
        return { notificationId };
    }

    async deleteAllNotifications(userId: string): Promise<{ success: true }> {
        await this.notificationRepository.deleteAllNotifications(userId);
        return { success: true };
    }

    async notifyUser(input: SendNotificationInput): Promise<NotificationResponseDto> {
        const notification = await this.notificationRepository.createNotification(
            input.userId,
            input.type,
            input.title,
            input.body,
            input.data,
        );

        const tokens = await this.notificationRepository.findActiveDeviceTokens(input.userId);
        const result = await this.firebasePushService.sendToTokens(
            tokens,
            input.title,
            input.body,
            this.toFirebaseData(input.type, input.data),
        );

        await this.notificationRepository.deactivateDeviceTokens(result.invalidTokens);
        return this.mapNotification(notification);
    }

    private mapNotification(notification: any): NotificationResponseDto {
        return new NotificationResponseDto({
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            data: notification.data ?? null,
            readAt: notification.readAt ?? null,
            createdAt: notification.createdAt,
        });
    }

    private toFirebaseData(type: NotificationType, data?: Record<string, unknown>): Record<string, string> {
        const payload: Record<string, string> = {
            type,
        };

        Object.entries(data ?? {}).forEach(([key, value]) => {
            if (value !== undefined && value !== null) {
                payload[key] = String(value);
            }
        });

        return payload;
    }
}
