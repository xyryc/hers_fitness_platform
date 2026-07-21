import { Expose } from 'class-transformer';

export class UserSessionResponseDto {
    @Expose()
    id: string;

    @Expose()
    userId: string;

    @Expose()
    token: string;

    @Expose()
    ipAddress?: string | null;

    @Expose()
    userAgent?: string | null;

    @Expose()
    expiresAt: Date;

    @Expose()
    isActive: boolean;

    @Expose()
    createdAt: Date;

    @Expose()
    lastUsedAt?: Date | null;

    constructor(partial: Partial<UserSessionResponseDto>) {
        Object.assign(this, partial);
    }
}