import { Expose, Type } from 'class-transformer';

export class TrainerReviewAuthorResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string | null;

    @Expose()
    profileImageUrl: string | null;

    constructor(partial: Partial<TrainerReviewAuthorResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerReviewResponseDto {
    @Expose()
    id: string;

    @Expose()
    memberUserId: string;

    @Expose()
    trainerUserId: string;

    @Expose()
    rating: number;

    @Expose()
    comment: string;

    @Expose()
    @Type(() => TrainerReviewAuthorResponseDto)
    member: TrainerReviewAuthorResponseDto;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    constructor(partial: Partial<TrainerReviewResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerReviewSummaryResponseDto {
    @Expose()
    trainerUserId: string;

    @Expose()
    averageRating: number | null;

    @Expose()
    reviewCount: number;

    constructor(partial: Partial<TrainerReviewSummaryResponseDto>) {
        Object.assign(this, partial);
    }
}
