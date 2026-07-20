import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { CreateTrainerReviewDto } from '../../dto/create-trainer-review.dto';

@Injectable()
export class TrainerReviewRepository {
    constructor(private readonly prisma: PrismaService) { }

    async upsertReview(memberUserId: string, trainerUserId: string, model: CreateTrainerReviewDto) {
        return (this.prisma as any).trainerReview.upsert({
            where: {
                uq_trainer_reviews_member_trainer: {
                    memberUserId,
                    trainerUserId,
                },
            },
            update: {
                rating: model.rating,
                comment: model.comment.trim(),
            },
            create: {
                memberUserId,
                trainerUserId,
                rating: model.rating,
                comment: model.comment.trim(),
            },
            include: this.getReviewIncludePattern(),
        });
    }

    async findByTrainer(trainerUserId: string) {
        return (this.prisma as any).trainerReview.findMany({
            where: { trainerUserId },
            include: this.getReviewIncludePattern(),
            orderBy: { createdAt: 'desc' },
        });
    }

    async findByMember(memberUserId: string) {
        return (this.prisma as any).trainerReview.findMany({
            where: { memberUserId },
            include: this.getReviewIncludePattern(),
            orderBy: { createdAt: 'desc' },
        });
    }

    async getTrainerSummary(trainerUserId: string) {
        const [aggregate, count] = await Promise.all([
            (this.prisma as any).trainerReview.aggregate({
                where: { trainerUserId },
                _avg: { rating: true },
            }),
            (this.prisma as any).trainerReview.count({
                where: { trainerUserId },
            }),
        ]);

        return {
            trainerUserId,
            averageRating: aggregate._avg.rating,
            reviewCount: count,
        };
    }

    private getReviewIncludePattern() {
        return {
            member: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                },
            },
        };
    }
}
