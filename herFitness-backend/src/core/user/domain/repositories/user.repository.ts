import { Injectable } from '@nestjs/common';
import { AuthProvider, Prisma, User } from 'prisma/generated/prisma/client';
import { PrismaService } from 'src/database/prisma.service';
import { AuthProviderEnum } from 'src/common/enums/auth-provider.enum';
import { CreateUserDto } from '../../dto/create-user.dto';
import { UserEntity, UserRecentActivityEntity } from '../entities/user.entity';
import { getStaticContentLookupKeys } from '../../static-content.utils';

@Injectable()
export class UserRepository {
    constructor(private readonly prisma: PrismaService) { }

    private getRoleSelectPattern(): Prisma.RoleSelect {
        return {
            id: true,
            name: true,
            description: true,
        };
    }

    private getCountrySelectPattern(): Prisma.CountrySelect {
        return {
            name: true,
            code: true,
            codeIso3: true,
        };
    }

    private getUserIncludePattern(includeMemberFitnessAssessment: boolean = false) {
        return {
            roles: {
                select: {
                    role: {
                        select: this.getRoleSelectPattern(),
                    },
                },
            },
            country: {
                select: this.getCountrySelectPattern(),
            },
            verification: true,
            trainerProfile: true,
            memberFitnessAssessment: includeMemberFitnessAssessment
                ? true
                : {
                    select: {
                        id: true,
                    },
                },
        };
    }

    async findById(
        id: string,
        includePassword: boolean = false,
        includeMemberFitnessAssessment: boolean = false,
        includeRecentActivity: boolean = false,
    ): Promise<UserEntity | null> {
        const user = await this.prisma.user.findUnique({
            where: { id },
            include: this.getUserIncludePattern(includeMemberFitnessAssessment) as any,
        });

        if (!user) return null;

        const mappedUser = this.mapToEntity(user, includePassword);

        if (!includeRecentActivity) {
            return mappedUser;
        }

        const roleName = mappedUser.roles?.[0]?.name;
        if (!roleName) {
            return { ...mappedUser, recentActivity: [] };
        }

        const activityByUserId = await this.findRecentActivityByUserIds([mappedUser.id], roleName, 10);
        return {
            ...mappedUser,
            recentActivity: activityByUserId.get(mappedUser.id) ?? [],
        };
    }

    async findByEmail(email: string, includePassword: boolean = false): Promise<UserEntity | null> {
        const user = await this.prisma.user.findFirst({
            where: { email },
            include: this.getUserIncludePattern() as any,
        });

        if (!user) return null;

        return this.mapToEntity(user, includePassword);
    }

    async findByUsername(username: string, includePassword: boolean = false): Promise<UserEntity | null> {
        const user = await this.prisma.user.findFirst({
            where: { username },
            include: this.getUserIncludePattern() as any,
        });

        if (!user) return null;

        return this.mapToEntity(user, includePassword);
    }

    async findByEmailOrUsername(emailOrUsername: string, includePassword: boolean = false): Promise<UserEntity | null> {
        const user = await this.prisma.user.findFirst({
            where: {
                OR: [
                    { username: emailOrUsername },
                    { email: emailOrUsername },
                ],
            },
            include: this.getUserIncludePattern() as any,
        });

        if (!user) return null;

        return this.mapToEntity(user, includePassword);
    }

    async checkUsernameAvailability(username: string): Promise<boolean> {
        const existingUser = await this.prisma.user.findFirst({
            where: { username },
            select: { id: true },
        });

        return !existingUser;
    }

    async findAllByRole(
        roleName: string,
        includeRecentActivity: boolean = false,
        includeMemberFitnessAssessment: boolean = false,
    ): Promise<UserEntity[]> {
        const users = await this.prisma.user.findMany({
            where: {
                roles: {
                    some: {
                        role: {
                            name: roleName,
                        },
                    },
                },
            },
            include: this.getUserIncludePattern(includeMemberFitnessAssessment) as any,
            orderBy: {
                createdAt: 'desc',
            },
        });

        const mappedUsers = users.map((user) => this.mapToEntity(user));

        if (!includeRecentActivity || mappedUsers.length === 0) {
            return mappedUsers;
        }

        const activityByUserId = await this.findRecentActivityByUserIds(
            mappedUsers.map((user) => user.id),
            roleName,
        );

        return mappedUsers.map((user) => ({
            ...user,
            recentActivity: activityByUserId.get(user.id) ?? [],
        }));
    }

    async create(
        tx: Prisma.TransactionClient,
        data: CreateUserDto,
        username: string,
        hashedPassword: string,
        roleId: string,
        provider: AuthProvider,
    ): Promise<User> {
        return tx.user.create({
            data: {
                email: data.email || null,
                username: username || null,
                password: hashedPassword,
                firstName: data.firstName,
                lastName: data.lastName || null,
                phoneNumber: data.phoneNumber || null,
                gender: data.gender || null,
                isEmailVerified: data.isEmailVerified || false,
                isPhoneVerified: data.isPhoneVerified || false,
                provider,
                isActive: data.isActive ?? true,
            },
        });
    }

    async createMember(
        tx: Prisma.TransactionClient,
        data: { name: string; email: string; phoneNumber: string; state: string; location: string; timezone?: string | null; profileImageUrl: string },
        username: string,
        hashedPassword: string,
        provider: AuthProvider,
    ): Promise<User> {
        return tx.user.create({
            data: {
                email: data.email,
                username,
                password: hashedPassword,
                firstName: data.name,
                displayName: data.name,
                phoneNumber: data.phoneNumber,
                profileImageUrl: data.profileImageUrl,
                state: data.state,
                location: data.location,
                timezone: data.timezone ?? null,
                provider,
                isEmailVerified: false,
                isPhoneVerified: false,
                isActive: true,
            },
        });
    }

    async createTrainer(
        tx: Prisma.TransactionClient,
        data: { name: string; email: string; phoneNumber: string; state: string; location: string; timezone?: string | null; profileImageUrl: string },
        username: string,
        hashedPassword: string,
        provider: AuthProvider,
    ): Promise<User> {
        return tx.user.create({
            data: {
                email: data.email,
                username,
                password: hashedPassword,
                firstName: data.name,
                displayName: data.name,
                phoneNumber: data.phoneNumber,
                profileImageUrl: data.profileImageUrl,
                state: data.state,
                location: data.location,
                timezone: data.timezone ?? null,
                provider,
                isEmailVerified: false,
                isPhoneVerified: false,
                isActive: true,
            },
        });
    }

    async updatePassword(tx: Prisma.TransactionClient, id: string, password: string): Promise<User | null> {
        return tx.user.update({
            where: { id },
            data: { password },
        });
    }

    async updateMemberProfile(
        userId: string,
        userFields: { displayName?: string; phoneNumber?: string; state?: string; location?: string },
        assessmentFields?: { age?: number; weight?: number; weightUnit?: string; dietPreference?: string },
    ): Promise<void> {
        await (this.prisma as any).$transaction(async (tx: any) => {
            const hasUserFields = Object.keys(userFields).some((k) => (userFields as any)[k] !== undefined);
            if (hasUserFields) {
                const data: Record<string, any> = {};
                if (userFields.displayName !== undefined) data.displayName = userFields.displayName.trim();
                if (userFields.phoneNumber !== undefined) data.phoneNumber = userFields.phoneNumber;
                if (userFields.state !== undefined) data.state = userFields.state;
                if (userFields.location !== undefined) data.location = userFields.location;
                await tx.user.update({ where: { id: userId }, data });
            }

            if (assessmentFields && Object.keys(assessmentFields).some((k) => (assessmentFields as any)[k] !== undefined)) {
                const data: Record<string, any> = {};
                if (assessmentFields.age !== undefined) data.age = assessmentFields.age;
                if (assessmentFields.weight !== undefined) data.weight = assessmentFields.weight;
                if (assessmentFields.weightUnit !== undefined) data.weightUnit = assessmentFields.weightUnit;
                if (assessmentFields.dietPreference !== undefined) data.dietPreference = assessmentFields.dietPreference;
                await tx.memberFitnessAssessment.updateMany({ where: { userId }, data });
            }
        });
    }

    async updateUserImages(
        userId: string,
        fields: { profileImageUrl?: string; coverPhotoUrl?: string },
    ): Promise<void> {
        const data: Record<string, any> = {};
        if (fields.profileImageUrl !== undefined) data.profileImageUrl = fields.profileImageUrl;
        if (fields.coverPhotoUrl !== undefined) data.coverPhotoUrl = fields.coverPhotoUrl;
        if (Object.keys(data).length) {
            await (this.prisma as any).user.update({ where: { id: userId }, data });
        }
    }

    async findMemberTransactions(memberUserId: string): Promise<any[]> {
        return (this.prisma as any).bookingPayment.findMany({
            where: {
                memberUserId,
                status: 'PAID',
            },
            include: {
                fitnessClass: {
                    select: {
                        id: true,
                        name: true,
                        trainer: {
                            select: { displayName: true, firstName: true },
                        },
                    },
                },
            },
            orderBy: { paidAt: 'desc' },
        });
    }

    async findMemberCompletedBookingCountByYear(memberUserId: string): Promise<{ year: number; count: number }[]> {
        const rows: { scheduledDate: string }[] = await (this.prisma as any).booking.findMany({
            where: {
                memberUserId,
                paymentStatus: 'PAID',
                OR: [
                    { memberCompletedAt: { not: null } },
                    { completedAt: { not: null } },
                ],
            },
            select: { scheduledDate: true },
        });

        const countsByYear = new Map<number, number>();
        rows.forEach(({ scheduledDate }) => {
            const year = Number(scheduledDate.slice(0, 4));
            countsByYear.set(year, (countsByYear.get(year) ?? 0) + 1);
        });

        return Array.from(countsByYear.entries())
            .map(([year, count]) => ({ year, count }))
            .sort((a, b) => a.year - b.year);
    }

    async softDeleteUser(userId: string): Promise<void> {
        await (this.prisma as any).user.update({
            where: { id: userId },
            data: { isActive: false },
        });
    }

    async findStaticContent(key: string): Promise<{ key: string; title: string; content: string; updatedAt: Date | null } | null> {
        const keys = getStaticContentLookupKeys(key);
        const rows = await (this.prisma as any).staticContent.findMany({
            where: { key: { in: keys } },
        });

        return rows.find((row: any) => row.key === keys[0]) ?? rows[0] ?? null;
    }

    async findMemberCompletedBookingsByYear(memberUserId: string, year: number): Promise<{ scheduledDate: string }[]> {
        return (this.prisma as any).booking.findMany({
            where: {
                memberUserId,
                paymentStatus: 'PAID',
                scheduledDate: {
                    startsWith: `${year}-`,
                },
                OR: [
                    { memberCompletedAt: { not: null } },
                    { completedAt: { not: null } },
                ],
            },
            select: {
                scheduledDate: true,
            },
        });
    }

    async findMemberCompletedBookingsByMonth(
        memberUserId: string,
        year: number,
        month: number,
    ): Promise<{ scheduledDate: string }[]> {
        const paddedMonth = String(month).padStart(2, '0');
        return (this.prisma as any).booking.findMany({
            where: {
                memberUserId,
                paymentStatus: 'PAID',
                scheduledDate: {
                    startsWith: `${year}-${paddedMonth}-`,
                },
                OR: [
                    { memberCompletedAt: { not: null } },
                    { completedAt: { not: null } },
                ],
            },
            select: { scheduledDate: true },
        });
    }

    async findMemberCompletedBookingsByDateRange(
        memberUserId: string,
        startDate: string,
        endDate: string,
    ): Promise<{ scheduledDate: string }[]> {
        return (this.prisma as any).booking.findMany({
            where: {
                memberUserId,
                paymentStatus: 'PAID',
                scheduledDate: {
                    gte: startDate,
                    lte: endDate,
                },
                OR: [
                    { memberCompletedAt: { not: null } },
                    { completedAt: { not: null } },
                ],
            },
            select: {
                scheduledDate: true,
            },
        });
    }

    // ─── Trainer profile ────────────────────────────────────────────────────────

    async updateTrainerProfile(
        userId: string,
        userFields: { displayName?: string; phoneNumber?: string; state?: string; location?: string },
        profileFields: {
            bio?: string;
            classesTaught?: string;
            instructorExperience?: string;
            certifications?: string;
            classDeliveryMode?: string;
        },
    ): Promise<void> {
        await (this.prisma as any).$transaction(async (tx: any) => {
            const hasUserFields = Object.values(userFields).some((v) => v !== undefined);
            if (hasUserFields) {
                const data: Record<string, any> = {};
                if (userFields.displayName !== undefined) data.displayName = userFields.displayName.trim();
                if (userFields.phoneNumber !== undefined) data.phoneNumber = userFields.phoneNumber;
                if (userFields.state !== undefined) data.state = userFields.state;
                if (userFields.location !== undefined) data.location = userFields.location;
                await tx.user.update({ where: { id: userId }, data });
            }

            const hasProfileFields = Object.values(profileFields).some((v) => v !== undefined);
            if (hasProfileFields) {
                const data: Record<string, any> = {};
                if (profileFields.bio !== undefined) data.bio = profileFields.bio;
                if (profileFields.classesTaught !== undefined) data.classesTaught = profileFields.classesTaught;
                if (profileFields.instructorExperience !== undefined) data.instructorExperience = profileFields.instructorExperience;
                if (profileFields.certifications !== undefined) data.certifications = profileFields.certifications;
                if (profileFields.classDeliveryMode !== undefined) data.classDeliveryMode = profileFields.classDeliveryMode;
                await tx.trainerProfile.update({ where: { userId }, data });
            }
        });
    }

    async findTrainerTransactions(
        trainerUserId: string,
        opts: { page: number; limit: number; startDate?: string; endDate?: string },
    ): Promise<{ rows: any[]; total: number }> {
        const where: any = {
            status: 'PAID',
            fitnessClass: { trainerUserId },
        };

        if (opts.startDate || opts.endDate) {
            where.paidAt = {};
            if (opts.startDate) where.paidAt.gte = new Date(`${opts.startDate}T00:00:00.000Z`);
            if (opts.endDate) where.paidAt.lte = new Date(`${opts.endDate}T23:59:59.999Z`);
        }

        const [rows, total] = await Promise.all([
            (this.prisma as any).bookingPayment.findMany({
                where,
                include: {
                    fitnessClass: { select: { id: true, name: true } },
                    bookings: {
                        take: 1,
                        include: {
                            member: { select: { displayName: true, firstName: true, lastName: true } },
                        },
                    },
                },
                orderBy: { paidAt: 'desc' },
                skip: (opts.page - 1) * opts.limit,
                take: opts.limit,
            }),
            (this.prisma as any).bookingPayment.count({ where }),
        ]);

        return { rows, total };
    }

    async invalidateAllUserSessions(userId: string): Promise<void> {
        await (this.prisma as any).userSession.updateMany({
            where: { userId, isActive: true },
            data: { isActive: false },
        });
    }

    // ─── Static helpers ──────────────────────────────────────────────────────────

    static parseClassesTaught(raw: string | null): string[] {
        if (!raw) return [];
        // Support both JSON array storage and comma-separated legacy strings
        if (raw.trim().startsWith('[')) {
            try {
                return JSON.parse(raw);
            } catch {
                // fall through to comma split
            }
        }
        return raw.split(',').map((s) => s.trim()).filter(Boolean);
    }

    static serializeClassesTaught(arr: string[]): string {
        return JSON.stringify(arr);
    }

    static mapDeliveryModeToSessionFormat(mode: string | null): string | null {
        if (!mode) return null;
        switch (mode) {
            case 'ONLINE': return 'Online';
            case 'OFFLINE': return 'In person';
            case 'BOTH': return 'Both';
            default: return mode;
        }
    }

    static mapSessionFormatToDeliveryMode(format: string): string {
        switch (format) {
            case 'Online': return 'ONLINE';
            case 'In person': return 'OFFLINE';
            case 'Both': return 'BOTH';
            default: return format.toUpperCase();
        }
    }

    // ─── Private helpers ─────────────────────────────────────────────────────────

    private mapToEntity(
        user: any,
        includePassword: boolean = false,
    ): UserEntity {
        return {
            id: user.id,
            email: user.email,
            username: user.username,
            password: includePassword ? user.password : undefined,
            firstName: user.firstName,
            lastName: user.lastName,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            profileImageUrl: user.profileImageUrl,
            coverPhotoUrl: user.coverPhotoUrl ?? null,
            state: user.state,
            location: user.location,
            idCardType: user.verification?.idCardType ?? null,
            idCardNumber: user.verification?.idCardNumber ?? null,
            idCardFrontImageUrl: user.verification?.idCardFrontImageUrl ?? null,
            idCardBackImageUrl: user.verification?.idCardBackImageUrl ?? null,
            verificationStatus: user.verification?.verificationStatus ?? null,
            classesTaught: user.trainerProfile?.classesTaught ?? null,
            fitnessClasses: UserRepository.parseClassesTaught(user.trainerProfile?.classesTaught ?? null),
            instructorExperience: user.trainerProfile?.instructorExperience ?? null,
            instructorDuration: user.trainerProfile?.instructorExperience ?? null,
            certifications: user.trainerProfile?.certifications ?? null,
            classDeliveryMode: user.trainerProfile?.classDeliveryMode ?? null,
            sessionFormat: UserRepository.mapDeliveryModeToSessionFormat(user.trainerProfile?.classDeliveryMode ?? null),
            baseLocationLat: user.trainerProfile?.baseLocationLat ?? null,
            baseLocationLng: user.trainerProfile?.baseLocationLng ?? null,
            liveLocationLat: user.trainerProfile?.liveLocationLat ?? null,
            liveLocationLng: user.trainerProfile?.liveLocationLng ?? null,
            isOnline: user.trainerProfile?.isOnline ?? false,
            lastSeen: user.trainerProfile?.lastSeen ?? null,
            stripeConnectAccountId: user.trainerProfile?.stripeConnectAccountId ?? null,
            stripeConnectOnboardingComplete: user.trainerProfile?.stripeConnectOnboardingComplete ?? false,
            stripeChargesEnabled: user.trainerProfile?.stripeChargesEnabled ?? false,
            stripePayoutsEnabled: user.trainerProfile?.stripePayoutsEnabled ?? false,
            stripeDetailsSubmitted: user.trainerProfile?.stripeDetailsSubmitted ?? false,
            stripeConnectUpdatedAt: user.trainerProfile?.stripeConnectUpdatedAt ?? null,
            payoutReady: Boolean(
                user.trainerProfile?.stripeConnectAccountId
                && user.trainerProfile?.stripeConnectOnboardingComplete
                && user.trainerProfile?.stripeChargesEnabled
                && user.trainerProfile?.stripePayoutsEnabled,
            ),
            currentLat: user.currentLat ?? null,
            currentLng: user.currentLng ?? null,
            locationUpdatedAt: user.locationUpdatedAt ?? null,
            hasCompletedMemberFitnessAssessment: Boolean(user.memberFitnessAssessment?.id),
            memberFitnessAssessment: this.mapMemberFitnessAssessment(user.memberFitnessAssessment),
            provider: user.provider as AuthProviderEnum,
            providerId: user.providerId,
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.isPhoneVerified,
            isActive: user.isActive,
            timezone: user.timezone,
            locale: user.locale,
            metadata: typeof user.metadata === 'object' && user.metadata !== null ? (user.metadata as Record<string, any>) : {},
            bio: user.trainerProfile?.bio ?? null,
            dob: user.dob,
            gender: user.gender,
            tagline: user.tagline,
            website: user.website,
            countryCodeIso3: user.countryCodeIso3,
            roles: user.roles.map((role) => role.role),
            recentActivity: user.recentActivity ?? undefined,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
        };
    }

    private mapMemberFitnessAssessment(assessment: any) {
        if (!assessment?.fitnessGoal) {
            return assessment?.id ? null : null;
        }

        return {
            id: assessment.id,
            userId: assessment.userId,
            fitnessGoal: assessment.fitnessGoal,
            weight: assessment.weight,
            weightUnit: assessment.weightUnit,
            age: assessment.age,
            hasPreviousFitnessExperience: assessment.hasPreviousFitnessExperience,
            physicalLimitations: assessment.physicalLimitations ?? null,
            dietPreference: assessment.dietPreference,
            takingSupplements: assessment.takingSupplements,
            supplements: assessment.supplements ?? [],
            calorieGoal: assessment.calorieGoal,
            calorieUnit: assessment.calorieUnit,
            sleepQuality: assessment.sleepQuality,
            createdAt: assessment.createdAt,
            updatedAt: assessment.updatedAt,
        };
    }

    private async findRecentActivityByUserIds(
        userIds: string[],
        roleName: string,
        limitPerUser: number = 5,
    ): Promise<Map<string, UserRecentActivityEntity[]>> {
        const activityByUserId = new Map<string, UserRecentActivityEntity[]>();
        userIds.forEach((userId) => activityByUserId.set(userId, []));

        const [
            users,
            memberBookings,
            trainerBookings,
            trainerClasses,
            chatMessages,
            memberAssessments,
        ] = await Promise.all([
            this.prisma.user.findMany({
                where: { id: { in: userIds } },
                select: {
                    id: true,
                    createdAt: true,
                    updatedAt: true,
                    locationUpdatedAt: true,
                },
            }),
            roleName === 'MEMBER'
                ? (this.prisma as any).booking.findMany({
                    where: { memberUserId: { in: userIds } },
                    select: this.getActivityBookingSelectPattern(),
                    orderBy: { createdAt: 'desc' },
                    take: userIds.length * limitPerUser,
                })
                : Promise.resolve([]),
            roleName === 'TRAINER'
                ? (this.prisma as any).booking.findMany({
                    where: { trainerUserId: { in: userIds } },
                    select: this.getActivityBookingSelectPattern(),
                    orderBy: { createdAt: 'desc' },
                    take: userIds.length * limitPerUser,
                })
                : Promise.resolve([]),
            roleName === 'TRAINER'
                ? (this.prisma as any).fitnessClass.findMany({
                    where: { trainerUserId: { in: userIds } },
                    select: {
                        id: true,
                        trainerUserId: true,
                        name: true,
                        status: true,
                        createdAt: true,
                    },
                    orderBy: { createdAt: 'desc' },
                    take: userIds.length * limitPerUser,
                })
                : Promise.resolve([]),
            (this.prisma as any).chatMessage.findMany({
                where: { senderUserId: { in: userIds } },
                select: {
                    id: true,
                    senderUserId: true,
                    messageType: true,
                    text: true,
                    attachmentType: true,
                    createdAt: true,
                    conversationId: true,
                },
                orderBy: { createdAt: 'desc' },
                take: userIds.length * limitPerUser,
            }),
            roleName === 'MEMBER'
                ? (this.prisma as any).memberFitnessAssessment.findMany({
                    where: { userId: { in: userIds } },
                    select: {
                        id: true,
                        userId: true,
                        fitnessGoal: true,
                        createdAt: true,
                        updatedAt: true,
                    },
                    orderBy: { updatedAt: 'desc' },
                    take: userIds.length * limitPerUser,
                })
                : Promise.resolve([]),
        ]);

        for (const user of users) {
            this.addActivity(activityByUserId, user.id, {
                type: 'ACCOUNT_REGISTERED',
                title: 'Account registered',
                description: 'User account was created.',
                occurredAt: user.createdAt,
                metadata: {},
            });

            if (user.updatedAt && user.updatedAt.getTime() !== user.createdAt.getTime()) {
                this.addActivity(activityByUserId, user.id, {
                    type: 'PROFILE_UPDATED',
                    title: 'Profile updated',
                    description: 'User profile information was updated.',
                    occurredAt: user.updatedAt,
                    metadata: {},
                });
            }

            if (user.locationUpdatedAt) {
                this.addActivity(activityByUserId, user.id, {
                    type: 'LOCATION_UPDATED',
                    title: 'Location updated',
                    description: 'User shared an updated current location.',
                    occurredAt: user.locationUpdatedAt,
                    metadata: {},
                });
            }
        }

        for (const booking of memberBookings) {
            this.addBookingActivity(activityByUserId, booking.memberUserId, booking, 'Member booked a class');
        }

        for (const booking of trainerBookings) {
            this.addBookingActivity(activityByUserId, booking.trainerUserId, booking, 'Trainer received a booking');
        }

        for (const fitnessClass of trainerClasses) {
            this.addActivity(activityByUserId, fitnessClass.trainerUserId, {
                type: 'CLASS_CREATED',
                title: 'Class created',
                description: `${fitnessClass.name} was created.`,
                occurredAt: fitnessClass.createdAt,
                metadata: {
                    fitnessClassId: fitnessClass.id,
                    className: fitnessClass.name,
                    status: fitnessClass.status,
                },
            });
        }

        for (const message of chatMessages) {
            this.addActivity(activityByUserId, message.senderUserId, {
                type: 'CHAT_MESSAGE_SENT',
                title: 'Chat message sent',
                description: message.messageType === 'TEXT'
                    ? this.truncateText(message.text ?? 'Text message sent.')
                    : `${message.attachmentType ?? 'Attachment'} message sent.`,
                occurredAt: message.createdAt,
                metadata: {
                    messageId: message.id,
                    conversationId: message.conversationId,
                    messageType: message.messageType,
                },
            });
        }

        for (const assessment of memberAssessments) {
            this.addActivity(activityByUserId, assessment.userId, {
                type: 'FITNESS_ASSESSMENT_COMPLETED',
                title: 'Fitness assessment completed',
                description: `Fitness goal: ${assessment.fitnessGoal}.`,
                occurredAt: assessment.updatedAt ?? assessment.createdAt,
                metadata: {
                    assessmentId: assessment.id,
                    fitnessGoal: assessment.fitnessGoal,
                },
            });
        }

        for (const [userId, activities] of activityByUserId.entries()) {
            activityByUserId.set(
                userId,
                activities
                    .sort((left, right) => right.occurredAt.getTime() - left.occurredAt.getTime())
                    .slice(0, limitPerUser),
            );
        }

        return activityByUserId;
    }

    private getActivityBookingSelectPattern() {
        return {
            id: true,
            memberUserId: true,
            trainerUserId: true,
            fitnessClassId: true,
            availabilitySlotId: true,
            scheduledDate: true,
            startTime: true,
            endTime: true,
            bookingStatus: true,
            paymentStatus: true,
            confirmedAt: true,
            createdAt: true,
            fitnessClass: {
                select: {
                    id: true,
                    name: true,
                    classType: true,
                },
            },
        };
    }

    private addBookingActivity(
        activityByUserId: Map<string, UserRecentActivityEntity[]>,
        userId: string,
        booking: any,
        title: string,
    ): void {
        const occurredAt = booking.confirmedAt ?? booking.createdAt;
        const statusLabel = booking.confirmedAt ? 'confirmed' : booking.bookingStatus.toLowerCase();

        this.addActivity(activityByUserId, userId, {
            type: booking.confirmedAt ? 'BOOKING_CONFIRMED' : 'BOOKING_CREATED',
            title,
            description: `${booking.fitnessClass?.name ?? 'Class'} booking ${statusLabel}.`,
            occurredAt,
            metadata: {
                bookingId: booking.id,
                fitnessClassId: booking.fitnessClassId,
                fitnessClassName: booking.fitnessClass?.name ?? null,
                availabilitySlotId: booking.availabilitySlotId,
                scheduledDate: booking.scheduledDate,
                startTime: booking.startTime,
                endTime: booking.endTime,
                bookingStatus: booking.bookingStatus,
                paymentStatus: booking.paymentStatus,
            },
        });
    }

    private addActivity(
        activityByUserId: Map<string, UserRecentActivityEntity[]>,
        userId: string,
        activity: UserRecentActivityEntity,
    ): void {
        const activities = activityByUserId.get(userId);
        if (!activities) return;

        activities.push(activity);
    }

    private truncateText(text: string, maxLength: number = 120): string {
        if (text.length <= maxLength) {
            return text;
        }

        return `${text.slice(0, maxLength - 3)}...`;
    }
}
