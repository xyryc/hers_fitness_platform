import { Injectable } from "@nestjs/common";
import { PrismaService } from "src/database/prisma.service";
import { UserSessionEntity } from "../entities/user-session.entity";
import { Prisma } from "prisma/generated/prisma/client";

@Injectable()
export class UserSessionRepository {
    constructor(private readonly prisma: PrismaService) { }

    private getSelectPattern(): Prisma.UserSessionSelect {
        return {
            id: true,
            userId: true,
            token: true,
            ipAddress: true,
            userAgent: true,
            expiresAt: true,
            isActive: true,
            createdAt: true,
            lastUsedAt: true,
        };
    }

    /**
     * Retrieves a user session by user ID and session ID.
     *
     * @param userId - The ID of the user to retrieve the session for.
     * @param sessionId - The ID of the session to retrieve.
     * @returns A promise that resolves to a `UserSessionEntity` if the session is found, or `null` if not found.
     */
    async getUserSessionById(userId: string, sessionId: string): Promise<UserSessionEntity | null> {
        const session = await this.prisma.userSession.findUnique({
            where: {
                id: sessionId,
                userId: userId,
                expiresAt: {
                    gte: new Date(),
                },
                isActive: true,
            },
            select: this.getSelectPattern()
        });

        return session ? this.mapToEntity(session) : null;
    }

    /**
     * Retrieves a user session by user ID and token.
     *
     * @param userId - The ID of the user to retrieve the session for.
     * @param token - The token of the session to retrieve.
     * @returns A promise that resolves to a `UserSessionEntity` if the session is found, or `null` if not found.
     */
    async getUserSessionByToken(userId: string, token: string): Promise<UserSessionEntity | null> {
        const session = await this.prisma.userSession.findUnique({
            where: {
                userId: userId,
                token: token,
                expiresAt: {
                    gte: new Date(),
                },
                isActive: true,
            },
            select: this.getSelectPattern()
        });

        return session ? this.mapToEntity(session) : null;
    }

    /**
     * Saves a new user session to the database.
     *
     * @param userId - The unique identifier of the user for whom the session is being created.
     * @param token - The session token to be saved.
     * @param ip - The IP address of the user at the time of session creation.
     * @param userAgent - The user agent string of the user's device.
     * @param expiresAt - The expiration date and time of the session.
     * @returns A promise that resolves to a UserSessionDto representing the newly created session.
     */
    async saveUserSession(userId: string, token: string, ip: string, userAgent: string, expiresAt: Date): Promise<UserSessionEntity | null> {
        const session = await this.prisma.userSession.create({
            data: {
                userId,
                token,
                ipAddress: ip,
                userAgent,
                expiresAt,
                isActive: true,
                createdAt: new Date(),
                lastUsedAt: new Date(),
            },
            select: this.getSelectPattern()
        });

        return session ? this.mapToEntity(session) : null;
    }

    /**
     * Deletes a user session by user ID and token.
     *
     * @param userId - The unique identifier of the user whose session is to be deleted.
     * @param token - The session token to delete.
     * @returns A promise that resolves to the deleted UserSessionDto if successful, or null if no session was found.
     */
    async deleteUserSession(userId: string, token: string): Promise<UserSessionEntity | null> {

        const session = await this.prisma.userSession.delete({
            where: {
                userId,
                token,
            },
            select: this.getSelectPattern()
        });

        return session ? this.mapToEntity(session) : null;
    }

    /**
     * Deletes a user session by user ID and session ID.
     *
     * @param userId - The unique identifier of the user whose session is to be deleted.
     * @param sessionId - The session ID to delete.
     * @returns A promise that resolves to the deleted UserSessionDto if successful, or null if no session was found.
     */
    async deleteUserSessionById(userId: string, sessionId: string): Promise<UserSessionEntity | null> {

        const session = await this.prisma.userSession.delete({
            where: {
                id: sessionId,
                userId: userId,
            },
            select: this.getSelectPattern()
        });

        return session ? this.mapToEntity(session) : null;
    }


    /**
     * Maps a Prisma UserSession object to a UserSessionEntity object.
     *
     * @param session - The Prisma UserSession object to map.
     * @returns The mapped UserSessionEntity object.
     */
    private mapToEntity(session: Prisma.UserSessionGetPayload<{
        select: {
            id: true,
            userId: true,
            token: true,
            ipAddress: true,
            userAgent: true,
            expiresAt: true,
            isActive: true,
            createdAt: true,
            lastUsedAt: true,
        }
    }>): UserSessionEntity {
        return {
            id: session.id,
            userId: session.userId,
            token: session.token,
            ipAddress: session.ipAddress || null,
            userAgent: session.userAgent || null,
            expiresAt: session.expiresAt,
            isActive: session.isActive,
            createdAt: session.createdAt,
            lastUsedAt: session.lastUsedAt || null,
        };
    }

}
