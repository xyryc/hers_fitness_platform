import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { UpdateNotificationPreferenceDto } from '../dto/update-notification-preference.dto';

@Injectable()
export class NotificationPreferenceRepository {
    constructor(private readonly prisma: PrismaService) {}

    /** Returns the primary role name for a user (MEMBER | TRAINER | ADMIN | null) */
    async findUserRole(userId: string): Promise<string | null> {
        const userRole = await (this.prisma as any).userRole.findFirst({
            where: { userId },
            include: { role: { select: { name: true } } },
        });
        return userRole?.role?.name ?? null;
    }

    async findByUserId(userId: string): Promise<any | null> {
        return (this.prisma as any).userNotificationPreference.findUnique({
            where: { userId },
        });
    }

    async upsert(userId: string, updates: UpdateNotificationPreferenceDto): Promise<any> {
        const data: Record<string, boolean> = {};

        // Trainer-only
        if (updates.newBooking !== undefined)    data.newBooking    = updates.newBooking;
        if (updates.classCheckIn !== undefined)  data.classCheckIn  = updates.classCheckIn;
        if (updates.paymentReceived !== undefined) data.paymentReceived = updates.paymentReceived;

        // Member-only
        if (updates.bookingConfirmation !== undefined) data.bookingConfirmation = updates.bookingConfirmation;
        if (updates.bookingCancellation !== undefined) data.bookingCancellation = updates.bookingCancellation;
        if (updates.paymentConfirmation !== undefined)  data.paymentConfirmation  = updates.paymentConfirmation;
        if (updates.trainerMessage !== undefined)       data.trainerMessage       = updates.trainerMessage;

        // Shared
        if (updates.classReminder !== undefined)       data.classReminder       = updates.classReminder;
        if (updates.systemAnnouncements !== undefined) data.systemAnnouncements = updates.systemAnnouncements;
        if (updates.emailNotifications !== undefined)  data.emailNotifications  = updates.emailNotifications;
        if (updates.pushNotifications !== undefined)   data.pushNotifications   = updates.pushNotifications;

        return (this.prisma as any).userNotificationPreference.upsert({
            where: { userId },
            update: data,
            create: {
                userId,
                // Trainer defaults
                newBooking:          updates.newBooking          ?? true,
                classCheckIn:        updates.classCheckIn        ?? true,
                paymentReceived:     updates.paymentReceived     ?? true,
                // Member defaults
                bookingConfirmation: updates.bookingConfirmation ?? true,
                bookingCancellation: updates.bookingCancellation ?? true,
                paymentConfirmation: updates.paymentConfirmation  ?? true,
                trainerMessage:      updates.trainerMessage       ?? true,
                // Shared defaults
                classReminder:       updates.classReminder       ?? true,
                systemAnnouncements: updates.systemAnnouncements ?? false,
                emailNotifications:  updates.emailNotifications  ?? true,
                pushNotifications:   updates.pushNotifications   ?? true,
            },
        });
    }
}
