import { Expose } from 'class-transformer';

export class AdminTrainerListItemDto {
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
    specialties: string | null;

    @Expose()
    classCount: number;

    @Expose()
    verificationStatus: string | null;

    @Expose()
    status: string;

    @Expose()
    rating: number | null;

    constructor(partial: Partial<AdminTrainerListItemDto>) {
        Object.assign(this, partial);
    }
}
