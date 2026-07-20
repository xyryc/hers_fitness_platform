import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { RegisterDeviceTokenDto } from '../dto/register-device-token.dto';

@Injectable()
export class NotificationRepository {
    constructor(private readonly prisma: PrismaService) { }

    async createNotification(userId: string, type: string, title: string, body: string, data?: Record<string, unknown>) {
        return (this.prisma as any).userNotification.create({
            data: {
                userId,
                type,
                title,
                body,
                data: data ?? undefined,
            },
        });
    }

    async findNotifications(userId: string, take: number, skip: number) {
        return (this.prisma as any).userNotification.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take,
            skip,
        });
    }

    async countUnread(userId: string): Promise<number> {
        return (this.prisma as any).userNotification.count({
            where: {
                userId,
                readAt: null,
            },
        });
    }

    async markRead(userId: string, notificationId: string) {
        return (this.prisma as any).userNotification.updateMany({
            where: {
                id: notificationId,
                userId,
                readAt: null,
            },
            data: {
                readAt: new Date(),
            },
        });
    }

    async markAllRead(userId: string) {
        return (this.prisma as any).userNotification.updateMany({
            where: {
                userId,
                readAt: null,
            },
            data: {
                readAt: new Date(),
            },
        });
    }

    async deleteNotification(userId: string, notificationId: string) {
        return (this.prisma as any).userNotification.deleteMany({
            where: {
                id: notificationId,
                userId,
            },
        });
    }

    async deleteAllNotifications(userId: string) {
        return (this.prisma as any).userNotification.deleteMany({
            where: {
                userId,
            },
        });
    }

    async upsertDeviceToken(userId: string, model: RegisterDeviceTokenDto) {
        return (this.prisma as any).userDeviceToken.upsert({
            where: {
                token: model.token,
            },
            update: {
                userId,
                platform: model.platform,
                deviceId: model.deviceId?.trim() || null,
                isActive: true,
                lastSeenAt: new Date(),
            },
            create: {
                userId,
                token: model.token,
                platform: model.platform,
                deviceId: model.deviceId?.trim() || null,
                isActive: true,
                lastSeenAt: new Date(),
            },
        });
    }

    async deactivateDeviceToken(userId: string, token: string) {
        return (this.prisma as any).userDeviceToken.updateMany({
            where: {
                userId,
                token,
            },
            data: {
                isActive: false,
            },
        });
    }

    async deactivateDeviceTokens(tokens: string[]) {
        if (!tokens.length) return;

        await (this.prisma as any).userDeviceToken.updateMany({
            where: {
                token: {
                    in: tokens,
                },
            },
            data: {
                isActive: false,
            },
        });
    }

    async findActiveDeviceTokens(userId: string): Promise<string[]> {
        const records = await (this.prisma as any).userDeviceToken.findMany({
            where: {
                userId,
                isActive: true,
            },
            select: {
                token: true,
            },
        });

        return records.map((record: any) => record.token);
    }
}
