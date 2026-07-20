import { Expose } from 'class-transformer';

export class PasswordHistoryResponseDto {
    @Expose()
    id: string;

    @Expose()
    userId: string;

    @Expose()
    passwordHash: string;

    @Expose()
    createdAt: Date;

    constructor(partial: Partial<PasswordHistoryResponseDto>) {
        Object.assign(this, partial);
    }
}