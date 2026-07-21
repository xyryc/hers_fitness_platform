import { Injectable } from '@nestjs/common';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { Roles } from 'src/common/enums/roles.enum';
import { UserService } from '../user/user.service';
import { TrainerReviewRepository } from './domain/repositories/trainer-review.repository';
import { CreateTrainerReviewDto } from './dto/create-trainer-review.dto';
import { TrainerReviewAuthorResponseDto, TrainerReviewResponseDto, TrainerReviewSummaryResponseDto } from './dto/trainer-review-response.dto';
import { NotificationService, NotificationType } from '../notification/notification.service';

@Injectable()
export class ReviewService {
    constructor(
        private readonly trainerReviewRepository: TrainerReviewRepository,
        private readonly userService: UserService,
        private readonly notificationService: NotificationService,
    ) { }

    async createTrainerReview(
        memberUserId: string,
        trainerUserId: string,
        model: CreateTrainerReviewDto,
    ): Promise<TrainerReviewResponseDto> {
        if (memberUserId === trainerUserId) {
            throw new BadRequestAppException('Members cannot review their own trainer profile.', ['SELF_REVIEW_NOT_ALLOWED']);
        }

        const trainer = await this.userService.findById(trainerUserId);
        if (!trainer) {
            throw new NotFoundAppException('Trainer not found.', 'TRAINER_NOT_FOUND');
        }

        const roleNames = trainer.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Trainer)) {
            throw new BadRequestAppException('Review target must be a trainer.', ['TRAINER_REQUIRED']);
        }

        const review = await this.trainerReviewRepository.upsertReview(memberUserId, trainerUserId, model);
        await this.notificationService.notifyUser({
            userId: trainerUserId,
            type: NotificationType.TRAINER_REVIEW_RECEIVED,
            title: 'New review received',
            body: `${review.member.displayName ?? review.member.firstName ?? 'A member'} left you a ${review.rating}-star review.`,
            data: {
                reviewId: review.id,
                memberUserId,
                trainerUserId,
                rating: review.rating,
            },
        });

        return this.mapReview(review);
    }

    async findTrainerReviews(trainerUserId: string): Promise<TrainerReviewResponseDto[]> {
        const reviews = await this.trainerReviewRepository.findByTrainer(trainerUserId);
        return reviews.map((review: any) => this.mapReview(review));
    }

    async findMyTrainerReviews(memberUserId: string): Promise<TrainerReviewResponseDto[]> {
        const reviews = await this.trainerReviewRepository.findByMember(memberUserId);
        return reviews.map((review: any) => this.mapReview(review));
    }

    async getTrainerReviewSummary(trainerUserId: string): Promise<TrainerReviewSummaryResponseDto> {
        const summary = await this.trainerReviewRepository.getTrainerSummary(trainerUserId);
        return new TrainerReviewSummaryResponseDto({
            trainerUserId: summary.trainerUserId,
            averageRating: summary.averageRating == null ? null : Number(Number(summary.averageRating).toFixed(2)),
            reviewCount: summary.reviewCount,
        });
    }

    private mapReview(review: any): TrainerReviewResponseDto {
        return new TrainerReviewResponseDto({
            id: review.id,
            memberUserId: review.memberUserId,
            trainerUserId: review.trainerUserId,
            rating: review.rating,
            comment: review.comment,
            member: new TrainerReviewAuthorResponseDto({
                id: review.member.id,
                name: review.member.displayName ?? review.member.firstName ?? null,
                profileImageUrl: review.member.profileImageUrl ?? null,
            }),
            createdAt: review.createdAt,
            updatedAt: review.updatedAt ?? null,
        });
    }
}
