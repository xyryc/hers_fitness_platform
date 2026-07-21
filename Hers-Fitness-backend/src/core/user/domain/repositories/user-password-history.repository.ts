import { Injectable } from "@nestjs/common";
import { PrismaService } from "src/database/prisma.service";
import { UserPasswordHistoryEntity } from "../entities/user-password-history.entity";
import { Prisma, UserPasswordHistory } from "prisma/generated/prisma/client";

@Injectable()
export class UserPasswordHistoryRepository {

    private readonly PASSWORD_HISTORY_LIMIT: number = 5;
    constructor(private readonly prisma: PrismaService) { }

    private getSelectPattern(): Prisma.UserPasswordHistorySelect {
        return {
            id: true,
            userId: true,
            passwordHash: true,
            createdAt: true,
        };
    }

    /**
     * Retrieves the password history for a specific user.
     *
     * @param userId - The unique identifier of the user.
     * @param limit - The maximum number of password history entries to retrieve.
     * @returns A promise that resolves to an array of `UserPasswordHistoryEntity` objects.
     */
    async getPasswordHistoryByUserId(userId: string, limit: number = this.PASSWORD_HISTORY_LIMIT): Promise<UserPasswordHistoryEntity[]> {
        const histories = await this.prisma.userPasswordHistory.findMany({
            where: {
                userId,
            },
            select: this.getSelectPattern(),
            orderBy: {
                createdAt: 'desc',
            },
            take: limit,
        });

        return histories.map((history) => this.mapToEntity(history));
    }

    /**
     * Adds a new password history entry for a specific user.
     *
     * @param tx - The Prisma transaction client.
     * @param userId - The unique identifier of the user.
     * @param passwordHash - The hashed password to add to the history.
     * @returns A promise that resolves to the newly created `UserPasswordHistory` record.
     */
    async addPasswordHistory(tx: Prisma.TransactionClient, userId: string, passwordHash: string): Promise<UserPasswordHistory> {

        return tx.userPasswordHistory.create({
            data: {
                userId,
                passwordHash,
            }
        });
    }


    /**
     * Maps a Prisma UserPasswordHistory object to a UserPasswordHistoryEntity object.
     *
     * @param userPasswordHistory - The Prisma UserPasswordHistory object to map.
     * @returns The mapped UserPasswordHistoryEntity object.
     */
    private mapToEntity(userPasswordHistory: Prisma.UserPasswordHistoryGetPayload<{
        select: {
            id: true,
            userId: true,
            passwordHash: true,
            createdAt: true,
        }
    }>): UserPasswordHistoryEntity {
        return {
            id: userPasswordHistory.id,
            userId: userPasswordHistory.userId,
            passwordHash: userPasswordHistory.passwordHash,
            createdAt: userPasswordHistory.createdAt,
        };
    }
}
