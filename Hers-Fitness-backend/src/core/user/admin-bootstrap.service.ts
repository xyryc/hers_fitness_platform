import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { AppConfig } from 'src/config/app.config';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthProviderEnum } from 'src/common/enums/auth-provider.enum';
import { PrismaService } from 'src/database/prisma.service';
import PasswordUtils from 'src/utils/password.utils';

@Injectable()
export class AdminBootstrapService implements OnModuleInit {
    private readonly logger = new Logger(AdminBootstrapService.name);

    constructor(
        private readonly prisma: PrismaService,
        private readonly appConfig: AppConfig,
    ) { }

    async onModuleInit(): Promise<void> {
        const adminConfig = this.appConfig.admin;

        await this.ensureRole(Roles.Admin, 'Administrator with full access');
        await this.ensureRole(Roles.Trainer, 'Trainer account');
        await this.ensureRole(Roles.Member, 'Member account');

        const adminRole = await this.prisma.role.findFirst({
            where: { name: Roles.Admin },
            select: { id: true },
        });

        if (!adminRole) {
            this.logger.error('Admin role could not be created.');
            return;
        }

        const hashedPassword = await PasswordUtils.hashPassword(adminConfig.password);
        const username = adminConfig.email.split('@')[0];
        const displayName = `${adminConfig.firstName} ${adminConfig.lastName}`.trim();

        const admin = await this.prisma.user.upsert({
            where: { email: adminConfig.email },
            update: {
                password: hashedPassword,
                firstName: adminConfig.firstName,
                lastName: adminConfig.lastName,
                displayName,
                isEmailVerified: true,
                isActive: true,
            },
            create: {
                email: adminConfig.email,
                username,
                password: hashedPassword,
                firstName: adminConfig.firstName,
                lastName: adminConfig.lastName,
                displayName,
                provider: AuthProviderEnum.CREDENTIALS,
                isEmailVerified: true,
                isPhoneVerified: true,
                isActive: true,
            },
            select: { id: true },
        });

        await this.prisma.userRole.upsert({
            where: {
                userId_roleId: {
                    userId: admin.id,
                    roleId: adminRole.id,
                },
            },
            update: {},
            create: {
                userId: admin.id,
                roleId: adminRole.id,
            },
        });
    }

    private async ensureRole(name: Roles, description: string): Promise<void> {
        const existingRole = await this.prisma.role.findFirst({
            where: { name },
            select: { id: true },
        });

        if (existingRole) return;

        await this.prisma.role.create({
            data: {
                name,
                description,
                isActive: true,
            },
        });
    }
}
