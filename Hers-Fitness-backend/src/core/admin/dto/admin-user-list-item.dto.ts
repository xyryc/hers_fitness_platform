import { Expose } from 'class-transformer';

export class AdminUserListItemDto {
    @Expose()
    id: string;

    @Expose()
    email: string | null;

    @Expose()
    username: string | null;

    @Expose()
    firstName: string | null;

    @Expose()
    lastName: string | null;

    @Expose()
    displayName: string | null;

    @Expose()
    profileImageUrl: string | null;

    @Expose()
    verificationStatus: string | null;

    @Expose()
    status: string | null;

    @Expose()
    createdAt: Date;

    constructor(partial: Partial<AdminUserListItemDto>) {
        Object.assign(this, partial);
    }
}
