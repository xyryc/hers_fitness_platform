import { Expose } from 'class-transformer';

export class FavoriteTrainerResponseDto {
    @Expose()
    id: string;

    @Expose()
    trainerUserId: string;

    @Expose()
    name: string | null;

    @Expose()
    profileImageUrl: string | null;

    @Expose()
    phoneNumber: string | null;

    @Expose()
    bio: string | null;

    @Expose()
    classesTaught: string | null;

    @Expose()
    instructorExperience: string | null;

    @Expose()
    certifications: string | null;

    @Expose()
    classDeliveryMode: string | null;

    @Expose()
    isOnline: boolean;

    @Expose()
    createdAt: Date;

    constructor(partial: Partial<FavoriteTrainerResponseDto>) {
        Object.assign(this, partial);
    }
}
