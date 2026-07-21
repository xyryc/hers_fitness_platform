export interface UserTokenEntity {
    id: string;
    userId: string;
    token: string;
    type: string;
    isUsed: boolean;
    usedAt?: Date | null;
    ipAddress?: string | null;
    userAgent?: string | null;
    createdAt: Date;
    expiresAt: Date;
}