import { Injectable } from "@nestjs/common";
import { PrismaService } from "src/database/prisma.service";
import { CreateUserTokenDto } from "../../dto/create-user-token.dto";
import { UserTokenEntity } from "../entities/user-token.entity";
import { UserTokenType } from "src/common/enums/user-token-type.enum";
import { Prisma } from "prisma/generated/prisma/client";
import { UpdateUserTokenDto } from "../../dto/update-user-token.dto";

@Injectable()
export class UserTokenRepository {
    private readonly DEFAULT_TOKEN_EXPIRY_HOURS: number = 24;
    constructor(private readonly prisma: PrismaService) { }

    private getSelectPattern(): Prisma.UserTokenSelect {
        return {
            id: true,
            userId: true,
            token: true,
            type: true,
            isUsed: true,
            usedAt: true,
            ipAddress: true,
            userAgent: true,
            expiresAt: true,
            createdAt: true,
        };
    }

    /**
     * Finds the first user token that matches the given criteria.
     *
     * @param where - The criteria to match against.
     * @returns A promise that resolves to the UserTokenEntity if found, or null if not found.
     */
    async findFirst(where: Prisma.UserTokenWhereInput): Promise<UserTokenEntity | null> {
        const userToken = await this.prisma.userToken.findFirst({
            where: where,
            select: this.getSelectPattern()
        });

        return userToken ? this.mapToEntity(userToken) : null;
    }

    /**
     * Validates a user token by checking if it exists and is not used or expired.
     *
     * @param userId - The unique identifier of the user.
     * @param token - The token to validate.
     * @returns A promise that resolves to the UserTokenEntity if the token is valid, or null if not found or invalid.
     */
    async validateUserToken(userId: string, token: string, type: UserTokenType): Promise<UserTokenEntity | null> {
        const userToken = await this.prisma.userToken.findFirst({
            where: {
                userId: userId,
                token: token,
                isUsed: false,
                type: type,
                expiresAt: {
                    gte: new Date(),
                },
            },
            select: this.getSelectPattern()
        });

        return userToken ? this.mapToEntity(userToken) : null;
    }

    /**
     * Creates a new user token for a specific user.
     *
     * @param userId - The unique identifier of the user for whom the token is being created.
     * @param model - The data model containing the token details.
     * @returns A promise that resolves to the created UserTokenEntity, or null if creation fails.
     */
    async create(userId: string, model: CreateUserTokenDto): Promise<UserTokenEntity | null> {
        const { token, type, expiresAt, isUsed, ipAddress, userAgent } = model;
        const userToken = await this.prisma.userToken.create({
            data: {
                userId,
                token: token,
                type: type,
                isUsed: isUsed ?? false,
                expiresAt: expiresAt ?? new Date(Date.now() + this.DEFAULT_TOKEN_EXPIRY_HOURS * 60 * 60 * 1000),
                ipAddress: ipAddress ?? null,
                userAgent: userAgent ?? null,
            },
            select: this.getSelectPattern()
        });

        return userToken ? this.mapToEntity(userToken) : null;
    }

    /**
     * Updates an existing user token for a specific user.
     *
     * @param userId - The unique identifier of the user whose token is being updated.
     * @param model - The data model containing the updated token details.
     * @returns A promise that resolves to the updated UserTokenDto, or null if the update fails.
     */
    async update(userId: string, model: Partial<UpdateUserTokenDto>): Promise<UserTokenEntity | null> {
        const { token, type, expiresAt, isUsed, ipAddress, userAgent } = model;

        const existingToken = await this.findFirst({
            userId,
            token,
            isUsed: false,
        });

        if (!existingToken) return null;

        const data: Prisma.UserTokenUpdateInput = {
            type: type ?? existingToken.type,
            expiresAt: expiresAt ?? existingToken.expiresAt,
            isUsed: isUsed ?? existingToken.isUsed,
            usedAt: isUsed ? new Date() : existingToken.usedAt,
            ipAddress: ipAddress ?? existingToken.ipAddress,
            userAgent: userAgent ?? existingToken.userAgent,
        };

        const userToken = await this.prisma.userToken.update({
            where: {
                id: existingToken.id
            },
            data: data,
            select: this.getSelectPattern()
        });

        return userToken ? this.mapToEntity(userToken) : null;
    }

    /**
     * Maps a Prisma UserToken object to a UserTokenEntity object.
     *
     * @param userToken - The Prisma UserToken object to map.
     * @returns The mapped UserTokenEntity object.
     */
    private mapToEntity(userToken: Prisma.UserTokenGetPayload<{ select: { id: true, userId: true, token: true, type: true, isUsed: true, usedAt: true, ipAddress: true, userAgent: true, expiresAt: true, createdAt: true, } }>): UserTokenEntity {
        return {
            id: userToken.id,
            userId: userToken.userId,
            token: userToken.token,
            type: userToken.type,
            isUsed: userToken.isUsed,
            usedAt: userToken.usedAt || null,
            ipAddress: userToken.ipAddress || null,
            userAgent: userToken.userAgent || null,
            expiresAt: userToken.expiresAt,
            createdAt: userToken.createdAt,
        };
    }

}
