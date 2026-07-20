import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { RoleEntity } from '../entities/role-entity';
import { Prisma, UserRole } from 'prisma/generated/prisma/client';

@Injectable()
export class RoleRepository {
    constructor(private readonly prisma: PrismaService) { }

    private getRoleSelectPattern(): Prisma.RoleSelect {
        return {
            id: true,
            name: true,
            description: true,
        };
    }

    /**
     * Retrieves all roles.
     *
     * @returns A promise that resolves to an array of `RoleEntity` objects.
     */
    async findAll(): Promise<RoleEntity[]> {
        const roles = await this.prisma.role.findMany({
            select: this.getRoleSelectPattern(),
        });

        return roles.map((role) => this.mapToEntity(role));
    }

    /**
     * Retrieves a role by unique identifier.
     *
     * @param id - The unique identifier of the role to retrieve.
     * @returns A promise that resolves to a `RoleEntity` if the role is found, or `null` if not found.
     */
    async findById(id: string): Promise<RoleEntity | null> {
        const role = await this.prisma.role.findUnique({
            where: { id },
            select: this.getRoleSelectPattern(),
        });

        if (!role) return null;

        return this.mapToEntity(role);
    }

    /**
     * Retrieves a role by name.
     *
     * @param name - The name of the role to retrieve.
     * @returns A promise that resolves to a `RoleEntity` if the role is found, or `null` if not found.
     */
    async findByName(name: string): Promise<RoleEntity | null> {
        const role = await this.prisma.role.findFirst({
            where: { name },
            select: this.getRoleSelectPattern(),
        });

        if (!role) return null;

        return this.mapToEntity(role);
    }

    /**
     * Retrieves all roles associated with a user.
     *
     * @param userId - The unique identifier of the user to retrieve roles for.
     * @returns A promise that resolves to an array of `RoleEntity` objects.
     */
    async findRolesByUserId(userId: string): Promise<RoleEntity[] | null> {
        const roles = await this.prisma.userRole.findMany({
            where: { userId },
            select: {
                role: {
                    select: this.getRoleSelectPattern(),
                },
            },
        });

        if (!roles) return null;

        return roles.map((role) => this.mapToEntity(role.role));
    }

    /**
     * Maps a role to a user.
     *
     * @param tx - The Prisma transaction client.
     * @param roleId - The unique identifier of the role to map.
     * @param userId - The unique identifier of the user to map.
     * @returns A promise that resolves to the mapped `UserRole` object.
     */
    async mapRoleWithUser(tx: Prisma.TransactionClient, roleId: string, userId: string): Promise<UserRole> {
        return tx.userRole.create({
            data: {
                userId,
                roleId,
            }
        });
    }

    /**
     * Maps a Prisma Role object to a RoleEntity object.
     *
     * @param role - The Prisma Role object to map.
     * @returns The mapped RoleEntity object.
     */
    private mapToEntity(role: Prisma.RoleGetPayload<{
        select: {
            id: true,
            name: true,
            description: true,
        }
    }>): RoleEntity {
        return {
            id: role.id,
            name: role.name,
            description: role.description,
        };
    }

}
