export interface UserSessionEntity {
    id: string;
    userId: string;
    token: string;
    ipAddress?: string | null;
    userAgent?: string | null;
    expiresAt: Date;
    isActive: boolean;
    createdAt: Date;
    lastUsedAt?: Date | null;
}