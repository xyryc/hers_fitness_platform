import { Expose } from 'class-transformer';

export class UserTokenResponseDto {
    @Expose()
    id: string;

    @Expose()
    userId: string;

    @Expose()
    token: string;

    @Expose()
    type: string;

    @Expose()
    isUsed: boolean;

    @Expose()
    usedAt?: Date | null;

    @Expose()
    ipAddress?: string | null;

    @Expose()
    userAgent?: string | null;

    @Expose()
    createdAt: Date;

    @Expose()
    expiresAt: Date;

    constructor(partial: Partial<UserTokenResponseDto>) {
        Object.assign(this, partial);
    }
}