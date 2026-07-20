import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';

@Injectable()
export class FavoriteTrainerRepository {
    constructor(private readonly prisma: PrismaService) { }

    async create(memberUserId: string, trainerUserId: string) {
        return (this.prisma as any).favoriteTrainer.upsert({
            where: {
                uq_favorite_trainers_member_trainer: {
                    memberUserId,
                    trainerUserId,
                },
            },
            update: {},
            create: {
                memberUserId,
                trainerUserId,
            },
            include: this.getIncludePattern(),
        });
    }

    async delete(memberUserId: string, trainerUserId: string): Promise<boolean> {
        const result = await (this.prisma as any).favoriteTrainer.deleteMany({
            where: {
                memberUserId,
                trainerUserId,
            },
        });

        return result.count > 0;
    }

    async findByMember(memberUserId: string) {
        return (this.prisma as any).favoriteTrainer.findMany({
            where: {
                memberUserId,
            },
            include: this.getIncludePattern(),
            orderBy: {
                createdAt: 'desc',
            },
        });
    }

    private getIncludePattern() {
        return {
            trainer: {
                include: {
                    trainerProfile: true,
                },
            },
        };
    }
}
