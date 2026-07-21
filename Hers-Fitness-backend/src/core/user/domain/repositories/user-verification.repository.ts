import { Injectable } from '@nestjs/common';
import { Prisma } from 'prisma/generated/prisma/client';
import { PrismaService } from 'src/database/prisma.service';
import { CreateUserVerificationDto } from '../../dto/create-user-verification.dto';

@Injectable()
export class UserVerificationRepository {
    constructor(private readonly prisma: PrismaService) { }

    async findPending(roleName?: string) {
        return (this.prisma as any).userVerification.findMany({
            where: {
                verificationStatus: 'PENDING',
                user: roleName
                    ? {
                        roles: {
                            some: {
                                role: {
                                    name: roleName,
                                },
                            },
                        },
                    }
                    : {
                        roles: {
                            some: {
                                role: {
                                    name: {
                                        in: ['MEMBER', 'TRAINER'],
                                    },
                                },
                            },
                        },
                    },
            },
            include: {
                user: {
                    select: {
                        id: true,
                        email: true,
                        username: true,
                        firstName: true,
                        lastName: true,
                        displayName: true,
                        profileImageUrl: true,
                        roles: {
                            select: {
                                role: {
                                    select: {
                                        name: true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
            orderBy: {
                createdAt: 'asc',
            },
        });
    }

    async findByIdCardNumber(idCardNumber: string) {
        return (this.prisma as any).userVerification.findUnique({
            where: { idCardNumber },
        });
    }

    async findByUserId(userId: string) {
        return (this.prisma as any).userVerification.findUnique({
            where: { userId },
        });
    }

    async approve(userId: string, reviewedByUserId: string) {
        return (this.prisma as any).userVerification.update({
            where: { userId },
            data: {
                verificationStatus: 'APPROVED',
                reviewedByUserId,
                reviewedAt: new Date(),
                rejectionReason: null,
            },
        });
    }

    async create(
        tx: Prisma.TransactionClient,
        userId: string,
        data: CreateUserVerificationDto,
    ) {
        return (tx as any).userVerification.create({
            data: {
                userId,
                idCardType: data.idCardType,
                idCardNumber: data.idCardNumber,
                idCardFrontImageUrl: data.idCardFrontImageUrl,
                idCardBackImageUrl: data.idCardBackImageUrl,
                verificationStatus: 'PENDING',
            },
        });
    }
}
