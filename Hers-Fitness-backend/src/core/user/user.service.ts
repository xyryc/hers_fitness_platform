import { Injectable } from '@nestjs/common';
import { UserRepository } from './domain/repositories/user.repository';
import { UserResponseDto } from './dto/user-response.dto';
import { UserTokenRepository } from './domain/repositories/user-token.repository';
import { UserSessionRepository } from './domain/repositories/user-session.repository';
import { UserSessionResponseDto } from './dto/user-session-response.dto';
import { UserTokenType } from 'src/common/enums/user-token-type.enum';
import { UserTokenResponseDto } from './dto/user-token-response.dto';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import Miscellaneous from 'src/utils/miscellaneous.utils';
import { CreateUserDto } from './dto/create-user.dto';
import PasswordUtils from 'src/utils/password.utils';
import { AuthProviderEnum } from 'src/common/enums/auth-provider.enum';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { UserPasswordHistoryRepository } from './domain/repositories/user-password-history.repository';
import { PrismaService } from 'src/database/prisma.service';
import { RoleRepository } from './domain/repositories/role.repository';
import { CreateUserTokenDto } from './dto/create-user-token.dto';
import { UpdateUserTokenDto } from './dto/update-user-token.dto';
import { UserEntity } from './domain/entities/user.entity';
import { RoleResponseDto } from './dto/role-response.dto';
import { Roles } from 'src/common/enums/roles.enum';
import { RegisterMemberDto } from '../auth/dto/register-member.dto';
import { CloudinaryStorageService } from 'src/infrastructure/storage/cloudinary/cloudinary-storage.service';
import { CreateMemberDto } from './dto/create-member.dto';
import { RegisterTrainerDto } from '../auth/dto/register-trainer.dto';
import { CreateTrainerDto } from './dto/create-trainer.dto';
import { UserVerificationRepository } from './domain/repositories/user-verification.repository';
import { TrainerProfileRepository } from './domain/repositories/trainer-profile.repository';
import { CreateUserVerificationDto } from './dto/create-user-verification.dto';
import { CreateTrainerProfileDto } from './dto/create-trainer-profile.dto';
import { EmailService } from 'src/infrastructure/email/email.service';
import { MemberFitnessAssessmentRepository } from './domain/repositories/member-fitness-assessment.repository';
import { UpsertMemberFitnessAssessmentDto } from './dto/upsert-member-fitness-assessment.dto';
import { MemberFitnessAssessmentResponseDto } from './dto/member-fitness-assessment-response.dto';
import { randomBytes } from 'crypto';
import { FavoriteTrainerRepository } from './domain/repositories/favorite-trainer.repository';
import { FavoriteTrainerResponseDto } from './dto/favorite-trainer-response.dto';
import { AdminUserListItemDto } from './dto/admin-user-list-item.dto';
import { AdminTrainerListItemDto } from './dto/admin-trainer-list-item.dto';
import { AdminVerificationRequestDto } from './dto/admin-verification-request.dto';
import { MemberMonthlyActivityItemDto, MemberMonthlyActivityResponseDto } from './dto/member-monthly-activity-response.dto';
import { MemberWeeklyActivityItemDto, MemberWeeklyActivityResponseDto } from './dto/member-weekly-activity-response.dto';
import { MemberYearlyActivityItemDto, MemberYearlyActivityResponseDto } from './dto/member-yearly-activity-response.dto';
import { MemberTransactionResponseDto } from './dto/member-transaction-response.dto';
import { MemberDailyActivityItemDto, MemberDailyActivityResponseDto } from './dto/member-daily-activity-response.dto';
import { MemberReferralResponseDto } from './dto/member-referral-response.dto';
import { StaticContentResponseDto } from './dto/static-content-response.dto';
import { UpdateMemberProfileDto } from './dto/update-member-profile.dto';
import { UpdateTrainerProfileDto } from './dto/update-trainer-profile.dto';
import { TrainerTransactionResponseDto } from './dto/trainer-transaction-response.dto';
import { normalizeStaticContentKey } from './static-content.utils';

@Injectable()
export class UserService {
    constructor(
        private readonly prisma: PrismaService,
        private readonly userRepository: UserRepository,
        private readonly roleRepository: RoleRepository,
        private readonly userTokenRepository: UserTokenRepository,
        private readonly userSessionRepository: UserSessionRepository,
        private readonly userPasswordHistoryRepository: UserPasswordHistoryRepository,
        private readonly userVerificationRepository: UserVerificationRepository,
        private readonly trainerProfileRepository: TrainerProfileRepository,
        private readonly memberFitnessAssessmentRepository: MemberFitnessAssessmentRepository,
        private readonly favoriteTrainerRepository: FavoriteTrainerRepository,
        private readonly cloudinaryStorageService: CloudinaryStorageService,
        private readonly emailService: EmailService,
    ) { }

    /**
     * Retrieves a user by unique identifier.
     *
     * @param id - The unique identifier of the user to retrieve.
     * @returns A promise that resolves to a `UserResponseDto` if the user is found, or `null` if not found.
     */
    async findById(id: string): Promise<UserResponseDto | null> {
        const user = await this.userRepository.findById(id);
        if (!user) return null;
        return new UserResponseDto(user);
    }

    async findCurrentUser(id: string): Promise<UserResponseDto | null> {
        const user = await this.userRepository.findById(id, false, true);
        if (!user) return null;
        const assessment = user.memberFitnessAssessment as any;
        return new UserResponseDto({
            ...user,
            age: assessment?.age ?? null,
            weight: assessment?.weight ?? null,
            weightUnit: assessment?.weightUnit ?? null,
            dietPreference: assessment?.dietPreference ?? null,
        });
    }

    async updateMemberProfile(userId: string, model: UpdateMemberProfileDto): Promise<UserResponseDto> {
        await this.userRepository.updateMemberProfile(
            userId,
            {
                displayName: model.displayName,
                phoneNumber: model.phoneNumber,
                state: model.state,
                location: model.location,
            },
            {
                age: model.age,
                weight: model.weight,
                weightUnit: model.weightUnit,
                dietPreference: model.dietPreference,
            },
        );
        const updated = await this.findCurrentUser(userId);
        if (!updated) throw new NotFoundAppException('User not found', 'USER_NOT_FOUND');
        return updated;
    }

    async uploadMemberProfileImages(
        userId: string,
        files: { profileImage?: Express.Multer.File; coverImage?: Express.Multer.File },
    ): Promise<UserResponseDto> {
        const updates: { profileImageUrl?: string; coverPhotoUrl?: string } = {};

        if (files.profileImage) {
            const upload = await this.cloudinaryStorageService.uploadImage(files.profileImage, 'users/profile-images');
            if (!upload.secureUrl) throw new BadRequestAppException('Profile image upload failed', ['FILE_UPLOAD_ERROR']);
            updates.profileImageUrl = upload.secureUrl;
        }

        if (files.coverImage) {
            const upload = await this.cloudinaryStorageService.uploadImage(files.coverImage, 'users/cover-photos');
            if (!upload.secureUrl) throw new BadRequestAppException('Cover photo upload failed', ['FILE_UPLOAD_ERROR']);
            updates.coverPhotoUrl = upload.secureUrl;
        }

        await this.userRepository.updateUserImages(userId, updates);
        const updated = await this.findCurrentUser(userId);
        if (!updated) throw new NotFoundAppException('User not found', 'USER_NOT_FOUND');
        return updated;
    }

    async findMemberTransactions(memberUserId: string): Promise<MemberTransactionResponseDto[]> {
        const payments = await this.userRepository.findMemberTransactions(memberUserId);
        return payments.map((payment: any) => new MemberTransactionResponseDto({
            id: payment.id,
            fitnessClassId: payment.fitnessClassId,
            className: payment.fitnessClass?.name ?? null,
            trainerName: payment.fitnessClass?.trainer?.displayName
                ?? payment.fitnessClass?.trainer?.firstName
                ?? null,
            totalAmount: payment.totalAmount?.toString?.() ?? String(payment.totalAmount),
            currency: payment.currency ?? 'USD',
            couponCode: payment.couponCode ?? null,
            paymentMethod: payment.paymentMethod ?? null,
            provider: payment.provider ?? null,
            status: payment.status,
            paidAt: payment.paidAt ?? null,
            createdAt: payment.createdAt,
        }));
    }

    async findMemberYearlyActivity(memberUserId: string): Promise<MemberYearlyActivityResponseDto> {
        const yearCounts = await this.userRepository.findMemberCompletedBookingCountByYear(memberUserId);
        const max = Math.max(...yearCounts.map((y) => y.count), 0);
        const total = yearCounts.reduce((sum, y) => sum + y.count, 0);

        return new MemberYearlyActivityResponseDto({
            totalCompletedSessions: total,
            maxYearlyCompletedSessions: max,
            years: yearCounts.map((y) => new MemberYearlyActivityItemDto({
                year: y.year,
                completedSessions: y.count,
                activityPercentage: max ? Math.round((y.count / max) * 100) : 0,
            })),
        });
    }

    async deleteMemberAccount(userId: string): Promise<void> {
        await this.userRepository.softDeleteUser(userId);
    }

    // ─── Trainer settings ────────────────────────────────────────────────────────

    async updateTrainerProfile(userId: string, model: UpdateTrainerProfileDto): Promise<UserResponseDto> {
        const classDeliveryMode = model.sessionFormat
            ? UserRepository.mapSessionFormatToDeliveryMode(model.sessionFormat)
            : undefined;

        const classesTaught = model.fitnessClasses
            ? UserRepository.serializeClassesTaught(model.fitnessClasses)
            : undefined;

        await this.userRepository.updateTrainerProfile(
            userId,
            {
                displayName: model.displayName,
                phoneNumber: model.phoneNumber,
                state: model.state,
                location: model.location,
            },
            {
                bio: model.bio,
                classesTaught,
                instructorExperience: model.instructorDuration,
                certifications: model.certifications,
                classDeliveryMode,
            },
        );

        const updated = await this.findCurrentUser(userId);
        if (!updated) throw new NotFoundAppException('User not found', 'USER_NOT_FOUND');
        return updated;
    }

    async uploadTrainerProfileImages(
        userId: string,
        files: { profileImage?: Express.Multer.File; coverImage?: Express.Multer.File },
    ): Promise<{ imageUrl: string | null; coverPhotoUrl: string | null }> {
        if (!files.profileImage && !files.coverImage) {
            throw new BadRequestAppException(
                'At least one image (profileImage or coverImage) must be provided.',
                ['NO_IMAGE_PROVIDED'],
            );
        }

        const updates: { profileImageUrl?: string; coverPhotoUrl?: string } = {};

        if (files.profileImage) {
            const upload = await this.cloudinaryStorageService.uploadImage(files.profileImage, 'trainers/profile-images');
            if (!upload.secureUrl) throw new BadRequestAppException('Profile image upload failed', ['FILE_UPLOAD_ERROR']);
            updates.profileImageUrl = upload.secureUrl;
        }

        if (files.coverImage) {
            const upload = await this.cloudinaryStorageService.uploadImage(files.coverImage, 'trainers/cover-photos');
            if (!upload.secureUrl) throw new BadRequestAppException('Cover photo upload failed', ['FILE_UPLOAD_ERROR']);
            updates.coverPhotoUrl = upload.secureUrl;
        }

        await this.userRepository.updateUserImages(userId, updates);

        return {
            imageUrl: updates.profileImageUrl ?? null,
            coverPhotoUrl: updates.coverPhotoUrl ?? null,
        };
    }

    async deleteTrainerAccount(userId: string): Promise<void> {
        // Cancel / notify for upcoming classes
        const upcomingBookings = await this.prisma.booking.findMany({
            where: {
                trainerUserId: userId,
                bookingStatus: { in: ['CONFIRMED', 'HELD'] },
                scheduledDate: { gte: new Date().toISOString().slice(0, 10) },
            },
            select: { id: true },
        });

        if (upcomingBookings.length > 0) {
            const ids = upcomingBookings.map((b) => b.id);
            await (this.prisma as any).booking.updateMany({
                where: { id: { in: ids } },
                data: { bookingStatus: 'CANCELLED', cancelledAt: new Date() },
            });
        }

        // Invalidate all active sessions
        await this.userRepository.invalidateAllUserSessions(userId);

        // Soft-delete
        await this.userRepository.softDeleteUser(userId);
    }

    async findTrainerTransactions(
        trainerUserId: string,
        opts: { page: number; limit: number; startDate?: string; endDate?: string },
    ): Promise<{ data: TrainerTransactionResponseDto[]; meta: { total: number; page: number; limit: number } }> {
        const { rows, total } = await this.userRepository.findTrainerTransactions(trainerUserId, opts);

        const data = rows.map((payment: any) => {
            const booking = payment.bookings?.[0];
            const member = booking?.member;
            const memberName = member?.displayName ?? member?.firstName
                ?? (member?.firstName && member?.lastName ? `${member.firstName} ${member.lastName}` : null)
                ?? null;

            return new TrainerTransactionResponseDto({
                id: payment.id,
                className: payment.fitnessClass?.name ?? null,
                memberName,
                amount: payment.totalAmount?.toString?.() ?? String(payment.totalAmount),
                currency: payment.currency ?? 'USD',
                status: payment.status,
                paidAt: payment.paidAt ?? null,
                createdAt: payment.createdAt,
            });
        });

        return { data, meta: { total, page: opts.page, limit: opts.limit } };
    }

    getMemberReferral(userId: string): MemberReferralResponseDto {
        const code = userId.replace(/-/g, '').substring(0, 8).toUpperCase();
        return new MemberReferralResponseDto({
            referralCode: code,
            referralLink: `https://heba.app/join?ref=${code}`,
        });
    }

    async getStaticContent(key: string): Promise<StaticContentResponseDto> {
        const canonicalKey = normalizeStaticContentKey(key);
        if (!canonicalKey) throw new NotFoundAppException('Content not found', 'CONTENT_NOT_FOUND');

        const content = await this.userRepository.findStaticContent(canonicalKey);
        if (!content) throw new NotFoundAppException('Content not found', 'CONTENT_NOT_FOUND');
        return new StaticContentResponseDto({ ...content, key: canonicalKey });
    }

    /**
     * Retrieves a user by email address.
     *
     * @param email - The email address of the user to retrieve.
     * @param includePassword - Whether to include the user's password in the response.
     * @returns A promise that resolves to a `UserResponseDto` if the user is found, or `null` if not found.
     */
    async findByEmail(email: string, includePassword: boolean = false): Promise<UserResponseDto | null> {
        const user = await this.userRepository.findByEmail(email, includePassword);
        if (!user) return null;
        return new UserResponseDto(user);
    }

    async findMemberMonthlyActivity(memberUserId: string, year?: number): Promise<MemberMonthlyActivityResponseDto> {
        const resolvedYear = this.resolveActivityYear(year);
        const bookings = await this.userRepository.findMemberCompletedBookingsByYear(memberUserId, resolvedYear);
        const monthCounts = Array.from({ length: 12 }, () => 0);

        bookings.forEach((booking) => {
            const month = Number(booking.scheduledDate.slice(5, 7));
            if (month >= 1 && month <= 12) {
                monthCounts[month - 1] += 1;
            }
        });

        const totalCompletedSessions = monthCounts.reduce((sum, count) => sum + count, 0);
        const maxMonthlyCompletedSessions = Math.max(...monthCounts, 0);
        const monthLabels = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
        ];

        return new MemberMonthlyActivityResponseDto({
            year: resolvedYear,
            totalCompletedSessions,
            maxMonthlyCompletedSessions,
            months: monthCounts.map((completedSessions, index) => new MemberMonthlyActivityItemDto({
                month: index + 1,
                label: monthLabels[index],
                shortLabel: monthLabels[index][0],
                completedSessions,
                activityPercentage: maxMonthlyCompletedSessions
                    ? Math.round((completedSessions / maxMonthlyCompletedSessions) * 100)
                    : 0,
            })),
        });
    }

    async findMemberDailyActivity(memberUserId: string, month?: number, year?: number): Promise<MemberDailyActivityResponseDto> {
        const resolvedYear = this.resolveActivityYear(year);
        const now = new Date();
        const resolvedMonth = month ?? (now.getMonth() + 1);

        if (!Number.isInteger(resolvedMonth) || resolvedMonth < 1 || resolvedMonth > 12) {
            throw new BadRequestAppException('Invalid month. Must be between 1 and 12.', ['INVALID_ACTIVITY_MONTH']);
        }

        const bookings = await this.userRepository.findMemberCompletedBookingsByMonth(
            memberUserId,
            resolvedYear,
            resolvedMonth,
        );

        // Number of calendar days in the requested month
        const daysInMonth = new Date(resolvedYear, resolvedMonth, 0).getDate();
        const dayCounts = Array.from({ length: daysInMonth }, () => 0);

        bookings.forEach((booking) => {
            const day = Number(booking.scheduledDate.slice(8, 10));
            if (day >= 1 && day <= daysInMonth) {
                dayCounts[day - 1] += 1;
            }
        });

        const totalCompletedSessions = dayCounts.reduce((sum, count) => sum + count, 0);
        const maxDailyCompletedSessions = Math.max(...dayCounts, 0);
        const paddedMonth = String(resolvedMonth).padStart(2, '0');

        return new MemberDailyActivityResponseDto({
            month: resolvedMonth,
            year: resolvedYear,
            totalCompletedSessions,
            days: dayCounts.map((completedSessions, index) => {
                const day = index + 1;
                const paddedDay = String(day).padStart(2, '0');
                return new MemberDailyActivityItemDto({
                    date: `${resolvedYear}-${paddedMonth}-${paddedDay}`,
                    day,
                    completedSessions,
                    activityPercentage: maxDailyCompletedSessions
                        ? Math.round((completedSessions / maxDailyCompletedSessions) * 100)
                        : 0,
                });
            }),
        });
    }

    async findMemberWeeklyActivity(memberUserId: string, date?: string): Promise<MemberWeeklyActivityResponseDto> {
        const weekStartDate = this.resolveWeekStartDate(date);
        const weekDates = Array.from({ length: 7 }, (_, index) => {
            const day = new Date(weekStartDate);
            day.setUTCDate(weekStartDate.getUTCDate() + index);
            return day;
        });
        const weekStart = this.formatDateOnly(weekDates[0]);
        const weekEnd = this.formatDateOnly(weekDates[6]);
        const bookings = await this.userRepository.findMemberCompletedBookingsByDateRange(
            memberUserId,
            weekStart,
            weekEnd,
        );
        const countsByDate = new Map<string, number>();

        bookings.forEach((booking) => {
            countsByDate.set(booking.scheduledDate, (countsByDate.get(booking.scheduledDate) ?? 0) + 1);
        });

        const dailyCounts = weekDates.map((day) => countsByDate.get(this.formatDateOnly(day)) ?? 0);
        const totalCompletedSessions = dailyCounts.reduce((sum, count) => sum + count, 0);
        const maxDailyCompletedSessions = Math.max(...dailyCounts, 0);
        const dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

        return new MemberWeeklyActivityResponseDto({
            weekStart,
            weekEnd,
            totalCompletedSessions,
            maxDailyCompletedSessions,
            days: weekDates.map((day, index) => {
                const completedSessions = dailyCounts[index];

                return new MemberWeeklyActivityItemDto({
                    date: this.formatDateOnly(day),
                    dayOfWeek: index + 1,
                    label: dayLabels[index],
                    shortLabel: dayLabels[index][0],
                    completedSessions,
                    activityPercentage: maxDailyCompletedSessions
                        ? Math.round((completedSessions / maxDailyCompletedSessions) * 100)
                        : 0,
                });
            }),
        });
    }

    /**
     * Retrieves a user by username.
     *
     * @param username - The username of the user to retrieve.
     * @param includePassword - Whether to include the user's password in the response.
     * @returns A promise that resolves to a `UserResponseDto` if the user is found, or `null` if not found.
     */
    async findByUsername(username: string, includePassword: boolean = false): Promise<UserResponseDto | null> {
        const user = await this.userRepository.findByUsername(username, includePassword);
        if (!user) return null;
        return new UserResponseDto(user);
    }

    /**
     * Retrieves a user by email or username.
     *
     * @param emailOrUsername - The email or username of the user to retrieve.
     * @param includePassword - Whether to include the user's password in the response.
     * @returns A promise that resolves to a `UserResponseDto` if the user is found, or `null` if not found.
     */
    async findByEmailOrUsername(emailOrUsername: string, includePassword: boolean = false): Promise<UserResponseDto | null> {
        const user = await this.userRepository.findByEmailOrUsername(emailOrUsername, includePassword);
        if (!user) return null;
        return new UserResponseDto(user);
    }

    /**
     * Retrieves a user by email or username.
     *
     * @param emailOrUsername - The email or username of the user to retrieve.
     * @param includePassword - Whether to include the user's password in the response.
     * @returns A promise that resolves to a `UserEntity` if the user is found, or `null` if not found.
     */
    async findByEmailOrUsernameForLogin(emailOrUsername: string, includePassword: boolean = true): Promise<UserEntity | null | null> {
        return await this.userRepository.findByEmailOrUsername(emailOrUsername, includePassword);
    }

    /**
     * Compares a password with a user's password.
     *
     * @param plainTextPassword - The password to compare.
     * @param hashedPassword - The user's password to compare against.
     * @returns A promise that resolves to `true` if the passwords match, or `false` otherwise.
     */
    async comparePassword(plainTextPassword: string, hashedPassword: string) {
        return await PasswordUtils.comparePassword(plainTextPassword, hashedPassword);
    }

    /**
     * Generates a unique username based on the user's first name, last name, and email.
     *
     * @param firstName - The user's first name.
     * @param lastName - The user's last name.
     * @param email - The user's email address.
     * @returns A promise that resolves to the generated username.
     */
    async generateUniqueUsername(firstName: string, lastName: string, email: string) {
        // 1. Create a "Base" username
        // Fallback to email handle if names are missing
        let baseUsername = '';

        if (firstName || lastName) {
            if (firstName && lastName) {
                baseUsername = `${Miscellaneous.sanitize(firstName)}.${Miscellaneous.sanitize(lastName)}`;
            } else {
                baseUsername = Miscellaneous.sanitize(firstName || lastName);
            }
        } else {
            baseUsername = Miscellaneous.sanitize(email.split('@')[0]);
        }

        // 2. Define retry limits
        let isUnique = false;
        let attempt = 0;
        let finalUsername = baseUsername;
        const maxRetries = 5;

        while (!isUnique && attempt < maxRetries) {
            try {
                // 3. Logic: First attempt = clean name. Subsequent attempts = name + random suffix
                if (attempt > 0) {
                    finalUsername = `${baseUsername}${Miscellaneous.generateSuffix()}`;
                }

                // 4. Check existence (Soft Check)
                const existingUser = await this.userRepository.findByUsername(finalUsername);
                if (!existingUser) {
                    // 5. If null, the username is free!
                    isUnique = true;
                    return finalUsername;
                }

                // If found, loop continues and adds a suffix
                attempt++;

            } catch (error) {
                // Log error and break to prevent infinite loops
                console.error("Error generating username:", error);
                break;
            }
        }

        // Fallback if loop fails (very unlikely) -> Use timestamp
        return `${baseUsername}${Date.now()}`;
    }

    /**
     * Creates a new user with the specified data and role.
     *
     * @param data - The user data required for creation, including email, password, and personal details.
     * @param role - The role to assign to the new user.
     * @returns A promise that resolves to the created user's DTO, or null if creation fails.
     */
    async create(data: CreateUserDto, roleName: string): Promise<UserResponseDto> {

        const hashedPassword = await PasswordUtils.hashPassword(data.password);
        const username = await this.generateUniqueUsername(data.firstName, data.lastName || "", data.email);

        const role = await this.roleRepository.findByName(roleName);
        if (!role) {
            throw new BadRequestAppException('Invalid role.', ['INVALID_ROLE']);
        }

        const user = await this.prisma.$transaction(async (tx) => {
            const user = await this.userRepository.create(tx, data, username, hashedPassword, role.id, AuthProviderEnum.CREDENTIALS);
            await this.roleRepository.mapRoleWithUser(tx, role.id, user.id);
            return user;
        });

        if (!user) {
            throw new BadRequestAppException('Failed to create user.', ['USER_CREATION_FAILED']);
        }

        const finalUser = await this.findById(user.id);
        if (!finalUser) {
            throw new BadRequestAppException('Failed to create user.', ['USER_CREATION_FAILED']);
        }

        return finalUser;
    }

    async registerMember(
        data: RegisterMemberDto,
        files: {
            image?: Express.Multer.File[];
            idCardFrontImage?: Express.Multer.File[];
            idCardBackImage?: Express.Multer.File[];
        },
    ): Promise<UserResponseDto> {
        const profileImage = files.image?.[0];
        const idCardFrontImage = files.idCardFrontImage?.[0];
        const idCardBackImage = files.idCardBackImage?.[0];

        if (!profileImage) {
            throw new BadRequestAppException('Profile image is required.', ['PROFILE_IMAGE_REQUIRED']);
        }

        if (!idCardFrontImage) {
            throw new BadRequestAppException('ID card front image is required.', ['ID_CARD_FRONT_IMAGE_REQUIRED']);
        }

        if (!idCardBackImage) {
            throw new BadRequestAppException('ID card back image is required.', ['ID_CARD_BACK_IMAGE_REQUIRED']);
        }

        const existingUser = await this.userRepository.findByEmail(data.email);
        if (existingUser) {
            throw new BadRequestAppException('Email is already registered.', ['EMAIL_ALREADY_EXISTS']);
        }

        const existingIdCard = await this.userVerificationRepository.findByIdCardNumber(data.idCardNumber);
        if (existingIdCard) {
            throw new BadRequestAppException('ID card number is already registered.', ['ID_CARD_NUMBER_ALREADY_EXISTS']);
        }

        const hashedPassword = await PasswordUtils.hashPassword(data.password);
        const username = await this.generateUniqueUsername(data.name, '', data.email);

        const uploadedProfileImageUrl = await this.uploadRegistrationImage(
            profileImage,
            'members/profile-images/',
            'profile image',
        );
        const uploadedIdCardFrontImageUrl = await this.uploadRegistrationImage(
            idCardFrontImage,
            'members/id-cards/',
            'ID card front image',
        );
        const uploadedIdCardBackImageUrl = await this.uploadRegistrationImage(
            idCardBackImage,
            'members/id-cards/',
            'ID card back image',
        );

        const role = await this.roleRepository.findByName(Roles.Member);
        if (!role) {
            throw new BadRequestAppException('Member role is not configured.', ['MEMBER_ROLE_NOT_FOUND']);
        }

        const memberData: CreateMemberDto = {
            name: data.name,
            email: data.email,
            phoneNumber: data.phoneNumber,
            state: data.state,
            location: data.location,
            timezone: data.timezone ?? null,
            profileImageUrl: uploadedProfileImageUrl,
        };

        const verificationData: CreateUserVerificationDto = {
            idCardType: data.idCardType,
            idCardNumber: data.idCardNumber,
            idCardFrontImageUrl: uploadedIdCardFrontImageUrl,
            idCardBackImageUrl: uploadedIdCardBackImageUrl,
        };

        const user = await this.prisma.$transaction(async (tx) => {
            const createdUser = await this.userRepository.createMember(
                tx,
                memberData,
                username,
                hashedPassword,
                AuthProviderEnum.CREDENTIALS,
            );

            await this.userVerificationRepository.create(tx, createdUser.id, verificationData);
            await this.roleRepository.mapRoleWithUser(tx, role.id, createdUser.id);

            return createdUser;
        });

        // Generate and send verification code
        const verificationCode = Miscellaneous.generateSuffix(6);
        await this.userTokenRepository.create(user.id, {
            token: verificationCode,
            type: UserTokenType.EMAIL_VERIFICATION,
            expiresAt: new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
        });

        await this.emailService.sendVerificationCode(user.email || '', verificationCode);

        const finalUser = await this.findById(user.id);
        if (!finalUser) {
            throw new BadRequestAppException('Failed to create user.', ['USER_CREATION_FAILED']);
        }

        return finalUser;
    }

    async registerTrainer(
        data: RegisterTrainerDto,
        files: {
            image?: Express.Multer.File[];
            idCardFrontImage?: Express.Multer.File[];
            idCardBackImage?: Express.Multer.File[];
        },
    ): Promise<UserResponseDto> {
        const profileImage = files.image?.[0];
        const idCardFrontImage = files.idCardFrontImage?.[0];
        const idCardBackImage = files.idCardBackImage?.[0];

        if (!profileImage) {
            throw new BadRequestAppException('Profile image is required.', ['PROFILE_IMAGE_REQUIRED']);
        }

        if (!idCardFrontImage) {
            throw new BadRequestAppException('ID card front image is required.', ['ID_CARD_FRONT_IMAGE_REQUIRED']);
        }

        if (!idCardBackImage) {
            throw new BadRequestAppException('ID card back image is required.', ['ID_CARD_BACK_IMAGE_REQUIRED']);
        }

        const existingUser = await this.userRepository.findByEmail(data.email);
        if (existingUser) {
            throw new BadRequestAppException('Email is already registered.', ['EMAIL_ALREADY_EXISTS']);
        }

        const existingIdCard = await this.userVerificationRepository.findByIdCardNumber(data.idCardNumber);
        if (existingIdCard) {
            throw new BadRequestAppException('ID card number is already registered.', ['ID_CARD_NUMBER_ALREADY_EXISTS']);
        }

        const hashedPassword = await PasswordUtils.hashPassword(data.password);
        const username = await this.generateUniqueUsername(data.name, '', data.email);

        const uploadedProfileImageUrl = await this.uploadRegistrationImage(
            profileImage,
            'trainers/profile-images/',
            'profile image',
        );
        const uploadedIdCardFrontImageUrl = await this.uploadRegistrationImage(
            idCardFrontImage,
            'trainers/id-cards/',
            'ID card front image',
        );
        const uploadedIdCardBackImageUrl = await this.uploadRegistrationImage(
            idCardBackImage,
            'trainers/id-cards/',
            'ID card back image',
        );

        const role = await this.roleRepository.findByName(Roles.Trainer);
        if (!role) {
            throw new BadRequestAppException('Trainer role is not configured.', ['TRAINER_ROLE_NOT_FOUND']);
        }

        const trainerData: CreateTrainerDto = {
            name: data.name,
            email: data.email,
            phoneNumber: data.phoneNumber,
            state: data.state,
            location: data.location,
            timezone: data.timezone ?? null,
            profileImageUrl: uploadedProfileImageUrl,
        };

        const verificationData: CreateUserVerificationDto = {
            idCardType: data.idCardType,
            idCardNumber: data.idCardNumber,
            idCardFrontImageUrl: uploadedIdCardFrontImageUrl,
            idCardBackImageUrl: uploadedIdCardBackImageUrl,
        };

        const trainerProfileData: CreateTrainerProfileDto = {
            bio: data.bio,
            classesTaught: data.classesTaught,
            instructorExperience: data.instructorExperience,
            certifications: data.certifications,
            classDeliveryMode: data.classDeliveryMode,
        };

        const user = await this.prisma.$transaction(async (tx) => {
            const createdUser = await this.userRepository.createTrainer(
                tx,
                trainerData,
                username,
                hashedPassword,
                AuthProviderEnum.CREDENTIALS,
            );

            await this.userVerificationRepository.create(tx, createdUser.id, verificationData);
            await this.trainerProfileRepository.create(tx, createdUser.id, trainerProfileData);
            await this.roleRepository.mapRoleWithUser(tx, role.id, createdUser.id);

            return createdUser;
        });

        // Generate and send verification code
        const verificationCode = Miscellaneous.generateSuffix(6);
        await this.userTokenRepository.create(user.id, {
            token: verificationCode,
            type: UserTokenType.EMAIL_VERIFICATION,
            expiresAt: new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
        });

        await this.emailService.sendVerificationCode(user.email || '', verificationCode);

        const finalUser = await this.findById(user.id);
        if (!finalUser) {
            throw new BadRequestAppException('Failed to create trainer.', ['USER_CREATION_FAILED']);
        }

        return finalUser;
    }

    /**
     * Updates a user's password.
     *
     * @param id - The unique identifier of the user whose password is to be updated.
     * @param newPassword - The new password to set for the user.
     * @returns A promise that resolves to the updated user's DTO, or null if the user was not found.
     */
    async updatePassword(id: string, newPassword: string, currentPassword?: string): Promise<boolean | null> {
        const existingUser = await this.userRepository.findById(id);

        if (!existingUser) {
            throw new NotFoundAppException(`User with ID '${id}' not found.`, 'USER_NOT_FOUND');
        }

        const hashedPassword = await PasswordUtils.hashPassword(newPassword);

        if (currentPassword && !(await PasswordUtils.comparePassword(currentPassword, existingUser.password || ''))) {
            throw new BadRequestAppException('Current password is incorrect.', ['INCORRECT_CURRENT_PASSWORD']);
        }

        //check if this password is same as old password
        if (await PasswordUtils.comparePassword(newPassword, existingUser.password || '')) {
            throw new BadRequestAppException('New password cannot be the same as the old password.', ['PASSWORD_SAME_AS_OLD']);
        }

        //check if new password is strong enough
        if (!PasswordUtils.isStrongPassword(newPassword)) {
            throw new BadRequestAppException('New password is not strong enough.', ['WEAK_PASSWORD']);
        }

        //check if the new password not used in last 5 passwords
        const last5Passwords = await this.userPasswordHistoryRepository.getPasswordHistoryByUserId(id);

        const passwordChecks = await Promise.all(
            last5Passwords.map(async (history) => {
                const passwordResult = await PasswordUtils.comparePassword(newPassword, history.passwordHash || '');
                return passwordResult;
            })
        );

        const isPasswordUsed = passwordChecks.includes(true);

        if (isPasswordUsed) {
            throw new BadRequestAppException('Your new password must be different from your 5 most recent passwords', ['PASSWORD_USED_IN_LAST_5_PASSWORDS']);
        }

        await this.prisma.$transaction(async (tx) => {
            await this.userRepository.updatePassword(tx, id, hashedPassword);
            await this.userPasswordHistoryRepository.addPasswordHistory(tx, id, hashedPassword);
        });

        return true;
    }

    /**
     * Retrieves all roles associated with a user.
     *
     * @param userId - The unique identifier of the user to retrieve roles for.
     * @returns A promise that resolves to an array of `RoleResponseDto` objects.
     */
    async findRolesByUserId(userId: string): Promise<RoleResponseDto[] | null> {
        const roles = await this.roleRepository.findRolesByUserId(userId);
        if (!roles) return null;
        return roles.map((role) => new RoleResponseDto(role));
    }

    /**
     * Validates a user token by checking if it exists and is not used or expired.
     *
     * @param userId - The unique identifier of the user.
     * @param token - The token to validate.
     * @returns A promise that resolves to the UserTokenDto if the token is valid, or null if not found or invalid.
     */
    async validateUserToken(userId: string, token: string, type: UserTokenType): Promise<UserTokenResponseDto | null> {
        const userToken = await this.userTokenRepository.validateUserToken(userId, token, type);

        if (!userToken) {
            throw new BadRequestAppException('Invalid or expired token.', ['TOKEN_INVALID_OR_EXPIRED']);
        }

        return new UserTokenResponseDto(userToken);
    }

    /**
     * Creates a new user token for a specific user.
     *
     * @param userId - The unique identifier of the user for whom the token is being created.
     * @param model - The data model containing the token details.
     * @returns A promise that resolves to the created UserTokenDto, or null if creation fails.
     */
    async createUserToken(userId: string, model: CreateUserTokenDto): Promise<UserTokenResponseDto | null> {
        const token = await this.userTokenRepository.create(userId, model);

        if (!token) {
            throw new BadRequestAppException('Failed to create token.', ['TOKEN_CREATION_FAILED']);
        }

        return new UserTokenResponseDto(token);
    }

    /**
     * Updates an existing user token for a specific user.
     *
     * @param userId - The unique identifier of the user whose token is being updated.
     * @param model - The data model containing the updated token details.
     * @returns A promise that resolves to the updated UserTokenDto, or null if the update fails.
     */
    async updateUserToken(userId: string, model: Partial<UpdateUserTokenDto>): Promise<UserTokenResponseDto | null> {
        const { token, type, expiresAt, isUsed, ipAddress, userAgent } = model;

        const existingToken = await this.userTokenRepository.findFirst({
            userId,
            token,
            isUsed: false,
        });

        if (!existingToken) {
            throw new NotFoundAppException(`Token not found for user '${userId}'.`, 'TOKEN_NOT_FOUND');
        }

        const data: UpdateUserTokenDto = {
            type: (type !== undefined ? type : existingToken.type as UserTokenType) ?? existingToken.type as UserTokenType,
            expiresAt: (expiresAt !== undefined ? expiresAt : existingToken.expiresAt) ?? existingToken.expiresAt,
            isUsed: (isUsed !== undefined ? isUsed : existingToken.isUsed) ?? existingToken.isUsed,
            ipAddress: ipAddress !== undefined ? ipAddress : existingToken.ipAddress,
            userAgent: userAgent !== undefined ? userAgent : existingToken.userAgent,
            token: existingToken.token,
        };

        const userToken = await this.userTokenRepository.update(userId, data);

        if (!userToken) {
            throw new BadRequestAppException('Failed to update token.', ['TOKEN_UPDATE_FAILED']);
        }

        return new UserTokenResponseDto(userToken);
    }

    /**
     * Retrieves a user session by user ID and session ID.
     *
     * @param userId - The unique identifier of the user.
     * @param sessionId - The session ID to search for.
     * @returns A promise that resolves to a UserSessionResponseDto if the session is found, or null if not found.
     */
    async getUserSessionById(userId: string, sessionId: string): Promise<UserSessionResponseDto | null> {
        const session = await this.userSessionRepository.getUserSessionById(userId, sessionId);

        if (!session) return null;
        return new UserSessionResponseDto(session);
    }

    /**
     * Retrieves a user session by user ID and token.
     *
     * @param userId - The unique identifier of the user.
     * @param token - The session token to search for.
     * @returns A promise that resolves to a UserSessionResponseDto if the session is found, or null if not found.
     */
    async getUserSessionByToken(userId: string, token: string): Promise<UserSessionResponseDto | null> {
        const session = await this.userSessionRepository.getUserSessionByToken(userId, token);

        if (!session) return null;
        return new UserSessionResponseDto(session);
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
    async saveUserSession(userId: string, token: string, ip: string, userAgent: string, expiresAt: Date): Promise<UserSessionResponseDto> {
        const session = await this.userSessionRepository.saveUserSession(userId, token, ip, userAgent, expiresAt);
        if (!session) throw new BadRequestAppException('Failed to create user session.', ['USER_SESSION_CREATION_FAILED']);
        return new UserSessionResponseDto(session);
    }

    /**
   * Deletes a user session by user ID and token.
   *
   * @param userId - The unique identifier of the user whose session is to be deleted.
   * @param token - The session token to delete.
   * @returns A promise that resolves to the deleted UserSessionDto if successful, or null if no session was found.
   */
    async deleteUserSession(userId: string, token: string): Promise<UserSessionResponseDto | null> {
        const session = await this.userSessionRepository.deleteUserSession(userId, token);
        if (!session) return null;
        return new UserSessionResponseDto(session);
    }

    /**
   * Deletes a user session by user ID and session ID.
   *
   * @param userId - The unique identifier of the user whose session is to be deleted.
   * @param sessionId - The session ID to delete.
   * @returns A promise that resolves to the deleted UserSessionDto if successful, or null if no session was found.
   */
    async deleteUserSessionById(userId: string, sessionId: string): Promise<UserSessionResponseDto | null> {
        const session = await this.userSessionRepository.deleteUserSessionById(userId, sessionId);
        if (!session) return null;
        return new UserSessionResponseDto(session);
    }

    async getMemberFitnessAssessment(userId: string): Promise<MemberFitnessAssessmentResponseDto | null> {
        await this.ensureMemberUser(userId);

        const assessment = await this.memberFitnessAssessmentRepository.findByUserId(userId);
        if (!assessment) return null;

        return new MemberFitnessAssessmentResponseDto(assessment);
    }

    async upsertMemberFitnessAssessment(
        userId: string,
        model: UpsertMemberFitnessAssessmentDto,
    ): Promise<MemberFitnessAssessmentResponseDto> {
        await this.ensureMemberUser(userId);

        if (!model.takingSupplements && model.supplements.length > 0) {
            throw new BadRequestAppException(
                'Supplements must be empty when taking supplements is set to false.',
                ['SUPPLEMENTS_NOT_ALLOWED'],
            );
        }

        if (model.takingSupplements && model.supplements.length === 0) {
            throw new BadRequestAppException(
                'Please select at least one supplement when taking supplements is set to true.',
                ['SUPPLEMENTS_REQUIRED'],
            );
        }

        const assessment = await this.memberFitnessAssessmentRepository.upsert(userId, model);
        return new MemberFitnessAssessmentResponseDto(assessment);
    }

    async findAllMembers(): Promise<AdminUserListItemDto[]> {
        const users = await this.userRepository.findAllByRole(Roles.Member);
        return users.map((user) => this.mapToAdminUserListItem(user));
    }

    async findAllTrainers(): Promise<AdminTrainerListItemDto[]> {
        const users = await this.userRepository.findAllByRole(Roles.Trainer);
        const classCounts = await this.getTrainerClassCounts(users.map((user) => user.id));
        return users.map((user) => this.mapToAdminTrainerListItem(user, classCounts.get(user.id) ?? 0));
    }

    async findAdminMemberById(userId: string): Promise<UserResponseDto> {
        const user = await this.userRepository.findById(userId, false, true, true);
        if (!user) {
            throw new NotFoundAppException(`Member with ID '${userId}' not found.`, 'MEMBER_NOT_FOUND');
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Member)) {
            throw new BadRequestAppException('Requested user is not a member.', ['USER_IS_NOT_MEMBER']);
        }

        return new UserResponseDto(user);
    }

    async findAdminTrainerById(userId: string): Promise<UserResponseDto> {
        const user = await this.userRepository.findById(userId, false, false, true);
        if (!user) {
            throw new NotFoundAppException(`Trainer with ID '${userId}' not found.`, 'TRAINER_NOT_FOUND');
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Trainer)) {
            throw new BadRequestAppException('Requested user is not a trainer.', ['USER_IS_NOT_TRAINER']);
        }

        return new UserResponseDto(user);
    }

    async findPendingVerificationRequests(type?: string): Promise<AdminVerificationRequestDto[]> {
        const normalizedType = type?.toUpperCase();

        if (normalizedType && ![Roles.Member, Roles.Trainer].includes(normalizedType as Roles)) {
            throw new BadRequestAppException('Verification type must be MEMBER or TRAINER.', ['INVALID_VERIFICATION_TYPE']);
        }

        const verifications = await this.userVerificationRepository.findPending(normalizedType);
        return verifications.map((verification: any) => this.mapToAdminVerificationRequest(verification));
    }

    async approveUserVerification(userId: string, adminUserId: string): Promise<UserResponseDto> {
        const user = await this.userRepository.findById(userId);
        if (!user) {
            throw new NotFoundAppException(`User with ID '${userId}' not found.`, 'USER_NOT_FOUND');
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        const canApprove = roleNames.includes(Roles.Member) || roleNames.includes(Roles.Trainer);
        if (!canApprove) {
            throw new BadRequestAppException('Only member and trainer accounts can be approved.', ['APPROVAL_NOT_ALLOWED']);
        }

        const verification = await this.userVerificationRepository.findByUserId(userId);
        if (!verification) {
            throw new BadRequestAppException('User verification information was not found.', ['USER_VERIFICATION_NOT_FOUND']);
        }

        await this.userVerificationRepository.approve(userId, adminUserId);

        const approvedUser = await this.findById(userId);
        if (!approvedUser) {
            throw new NotFoundAppException(`User with ID '${userId}' not found.`, 'USER_NOT_FOUND');
        }

        return approvedUser;
    }

    async addFavoriteTrainer(memberUserId: string, trainerUserId: string): Promise<FavoriteTrainerResponseDto> {
        await this.ensureMemberUser(memberUserId);
        await this.ensureApprovedTrainer(trainerUserId);

        const favorite = await this.favoriteTrainerRepository.create(memberUserId, trainerUserId);
        return this.mapFavoriteTrainerToResponse(favorite);
    }

    async removeFavoriteTrainer(memberUserId: string, trainerUserId: string): Promise<boolean> {
        await this.ensureMemberUser(memberUserId);

        const deleted = await this.favoriteTrainerRepository.delete(memberUserId, trainerUserId);
        if (!deleted) {
            throw new NotFoundAppException('Favorite trainer not found.', 'FAVORITE_TRAINER_NOT_FOUND');
        }

        return true;
    }

    async findFavoriteTrainers(memberUserId: string): Promise<FavoriteTrainerResponseDto[]> {
        await this.ensureMemberUser(memberUserId);

        const favorites = await this.favoriteTrainerRepository.findByMember(memberUserId);
        return favorites.map((favorite: any) => this.mapFavoriteTrainerToResponse(favorite));
    }

    private async uploadRegistrationImage(
        file: Express.Multer.File,
        directoryPath: string,
        fileLabel: string,
    ): Promise<string> {
        const uploadResponse = await this.cloudinaryStorageService.uploadImage(file, directoryPath);

        if (!uploadResponse.secureUrl) {
            throw new BadRequestAppException(`Failed to upload ${fileLabel}.`, ['FILE_UPLOAD_ERROR']);
        }

        return uploadResponse.secureUrl;
    }

    private async ensureMemberUser(userId: string): Promise<UserResponseDto> {
        const user = await this.findById(userId);
        if (!user) {
            throw new NotFoundAppException(`User with ID '${userId}' not found.`, 'USER_NOT_FOUND');
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Member)) {
            throw new BadRequestAppException('This assessment is available for members only.', ['MEMBER_ONLY_FEATURE']);
        }

        return user;
    }

    private async ensureApprovedTrainer(userId: string): Promise<UserResponseDto> {
        const trainer = await this.findById(userId);
        if (!trainer) {
            throw new NotFoundAppException(`Trainer with ID '${userId}' not found.`, 'TRAINER_NOT_FOUND');
        }

        const roleNames = trainer.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Trainer)) {
            throw new BadRequestAppException('Only trainers can be added to favorites.', ['TRAINER_ONLY_FEATURE']);
        }

        if (trainer.verificationStatus !== 'APPROVED') {
            throw new BadRequestAppException('Only approved trainers can be added to favorites.', ['TRAINER_NOT_APPROVED']);
        }

        return trainer;
    }

    private mapFavoriteTrainerToResponse(favorite: any): FavoriteTrainerResponseDto {
        const trainer = favorite.trainer;
        return new FavoriteTrainerResponseDto({
            id: favorite.id,
            trainerUserId: favorite.trainerUserId,
            name: trainer?.displayName ?? trainer?.firstName ?? null,
            profileImageUrl: trainer?.profileImageUrl ?? null,
            phoneNumber: trainer?.phoneNumber ?? null,
            bio: trainer?.trainerProfile?.bio ?? null,
            classesTaught: trainer?.trainerProfile?.classesTaught ?? null,
            instructorExperience: trainer?.trainerProfile?.instructorExperience ?? null,
            certifications: trainer?.trainerProfile?.certifications ?? null,
            classDeliveryMode: trainer?.trainerProfile?.classDeliveryMode ?? null,
            isOnline: trainer?.trainerProfile?.isOnline ?? false,
            createdAt: favorite.createdAt,
        });
    }

    private mapToAdminUserListItem(user: UserEntity): AdminUserListItemDto {
        return new AdminUserListItemDto({
            id: user.id,
            email: user.email ?? null,
            username: user.username ?? null,
            firstName: user.firstName ?? null,
            lastName: user.lastName ?? null,
            displayName: user.displayName ?? null,
            profileImageUrl: user.profileImageUrl ?? null,
            verificationStatus: user.verificationStatus ?? null,
            status: user.isActive ? 'ACTIVE' : 'INACTIVE',
            createdAt: user.createdAt,
        });
    }

    private async getTrainerClassCounts(trainerUserIds: string[]): Promise<Map<string, number>> {
        if (trainerUserIds.length === 0) {
            return new Map<string, number>();
        }

        const rows = await (this.prisma as any).fitnessClass.groupBy({
            by: ['trainerUserId'],
            where: {
                trainerUserId: {
                    in: trainerUserIds,
                },
            },
            _count: {
                id: true,
            },
        });

        return new Map<string, number>(
            rows.map((row: any) => [row.trainerUserId, row._count.id]),
        );
    }

    private mapToAdminTrainerListItem(user: UserEntity, classCount: number): AdminTrainerListItemDto {
        return new AdminTrainerListItemDto({
            id: user.id,
            email: user.email ?? null,
            username: user.username ?? null,
            firstName: user.firstName ?? null,
            lastName: user.lastName ?? null,
            displayName: user.displayName ?? null,
            profileImageUrl: user.profileImageUrl ?? null,
            specialties: user.classesTaught ?? null,
            classCount,
            verificationStatus: user.verificationStatus ?? null,
            status: user.isActive ? 'ACTIVE' : 'INACTIVE',
            rating: null,
        });
    }

    private mapToAdminVerificationRequest(verification: any): AdminVerificationRequestDto {
        const user = verification.user;
        const roleNames = user.roles?.map((userRole: any) => userRole.role.name) ?? [];
        const requestType = roleNames.includes(Roles.Member) ? Roles.Member : Roles.Trainer;
        const fullName = [user.firstName, user.lastName].filter(Boolean).join(' ');
        const displayName = user.displayName ?? (fullName || user.username);

        return new AdminVerificationRequestDto({
            userId: user.id,
            userCode: this.buildUserCode(user.id),
            email: user.email ?? null,
            username: user.username ?? null,
            firstName: user.firstName ?? null,
            lastName: user.lastName ?? null,
            displayName: displayName ?? null,
            profileImageUrl: user.profileImageUrl ?? null,
            requestType,
            verificationStatus: verification.verificationStatus,
            submittedAt: verification.createdAt,
            documentsProvided: Boolean(verification.idCardFrontImageUrl && verification.idCardBackImageUrl),
            idCardType: verification.idCardType,
            idCardNumber: verification.idCardNumber,
            idCardFrontImageUrl: verification.idCardFrontImageUrl,
            idCardBackImageUrl: verification.idCardBackImageUrl,
        });
    }

    private buildUserCode(userId: string): string {
        return `USR-${userId.replace(/-/g, '').slice(0, 6).toUpperCase()}`;
    }

    /**
     * Verifies a user's email address using a verification code.
     *
     * @param email - The email address of the user.
     * @param code - The verification code to validate.
     * @returns A promise that resolves to true if verification is successful.
     */
    async verifyEmail(email: string, code: string): Promise<boolean> {
        const user = await this.userRepository.findByEmail(email);
        if (!user) {
            throw new NotFoundAppException(`User with email '${email}' not found.`, 'USER_NOT_FOUND');
        }

        const userToken = await this.userTokenRepository.validateUserToken(user.id, code, UserTokenType.EMAIL_VERIFICATION);

        if (!userToken) {
            throw new BadRequestAppException('Invalid or expired verification code.', ['INVALID_OR_EXPIRED_CODE']);
        }

        await this.prisma.$transaction(async (tx) => {
            await tx.user.update({
                where: { id: user.id },
                data: { isEmailVerified: true },
            });

            await tx.userToken.update({
                where: { id: userToken.id },
                data: { isUsed: true, usedAt: new Date() },
            });
        });

        return true;
    }

    /**
     * Resends a verification code to a user's email.
     *
     * @param email - The email address of the user.
     * @returns A promise that resolves to true if the code was sent successfully.
     */
    async resendVerificationCode(email: string): Promise<boolean> {
        const user = await this.userRepository.findByEmail(email);
        if (!user) {
            throw new NotFoundAppException(`User with email '${email}' not found.`, 'USER_NOT_FOUND');
        }

        if (user.isEmailVerified) {
            throw new BadRequestAppException('Email is already verified.', ['EMAIL_ALREADY_VERIFIED']);
        }

        // Generate and send verification code
        const verificationCode = Miscellaneous.generateSuffix(6);
        await this.userTokenRepository.create(user.id, {
            token: verificationCode,
            type: UserTokenType.EMAIL_VERIFICATION,
            expiresAt: new Date(Date.now() + 15 * 60 * 1000), // 15 minutes
        });

        await this.emailService.sendVerificationCode(user.email || '', verificationCode);

        return true;
    }

    async forgotPassword(email: string): Promise<boolean> {
        const user = await this.userRepository.findByEmail(email);
        if (!user) {
            return true;
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        const canResetPassword = roleNames.includes(Roles.Member) || roleNames.includes(Roles.Trainer);
        if (!canResetPassword) {
            return true;
        }

        const resetCode = Miscellaneous.generateSuffix(6);

        await this.prisma.$transaction(async (tx) => {
            await tx.userToken.updateMany({
                where: {
                    userId: user.id,
                    type: UserTokenType.PASSWORD_RESET,
                    isUsed: false,
                },
                data: {
                    isUsed: true,
                    usedAt: new Date(),
                },
            });

            await tx.userToken.create({
                data: {
                    userId: user.id,
                    token: resetCode,
                    type: UserTokenType.PASSWORD_RESET,
                    expiresAt: new Date(Date.now() + 15 * 60 * 1000),
                    isUsed: false,
                },
            });
        });

        await this.emailService.sendPasswordResetCode(user.email || '', resetCode);

        return true;
    }

    async verifyPasswordResetOtp(email: string, otp: string): Promise<string> {
        const user = await this.userRepository.findByEmail(email);
        if (!user) {
            throw new NotFoundAppException(`User with email '${email}' not found.`, 'USER_NOT_FOUND');
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        const canResetPassword = roleNames.includes(Roles.Member) || roleNames.includes(Roles.Trainer);
        if (!canResetPassword) {
            throw new BadRequestAppException('Password reset is not available for this account.', ['PASSWORD_RESET_NOT_ALLOWED']);
        }

        const userToken = await this.userTokenRepository.validateUserToken(user.id, otp, UserTokenType.PASSWORD_RESET);
        if (!userToken) {
            throw new BadRequestAppException('Invalid or expired reset OTP.', ['INVALID_OR_EXPIRED_RESET_OTP']);
        }

        const resetKey = `reset_${randomBytes(32).toString('hex')}`;

        await this.prisma.$transaction(async (tx) => {
            await tx.userToken.update({
                where: { id: userToken.id },
                data: {
                    isUsed: true,
                    usedAt: new Date(),
                },
            });

            await tx.userToken.updateMany({
                where: {
                    userId: user.id,
                    type: UserTokenType.PASSWORD_RESET_KEY,
                    isUsed: false,
                },
                data: {
                    isUsed: true,
                    usedAt: new Date(),
                },
            });

            await tx.userToken.create({
                data: {
                    userId: user.id,
                    token: resetKey,
                    type: UserTokenType.PASSWORD_RESET_KEY,
                    expiresAt: new Date(Date.now() + 15 * 60 * 1000),
                    isUsed: false,
                },
            });
        });

        return resetKey;
    }

    async resetPasswordByKey(resetKey: string, newPassword: string): Promise<boolean> {
        const resetToken = await this.userTokenRepository.findFirst({
            token: resetKey,
            type: UserTokenType.PASSWORD_RESET_KEY,
            isUsed: false,
            expiresAt: {
                gte: new Date(),
            },
        });

        if (!resetToken) {
            throw new BadRequestAppException('Invalid or expired reset key.', ['INVALID_OR_EXPIRED_RESET_KEY']);
        }

        const user = await this.userRepository.findById(resetToken.userId, true);
        if (!user) {
            throw new NotFoundAppException(`User with ID '${resetToken.userId}' not found.`, 'USER_NOT_FOUND');
        }

        if (await PasswordUtils.comparePassword(newPassword, user.password || '')) {
            throw new BadRequestAppException('New password cannot be the same as the old password.', ['PASSWORD_SAME_AS_OLD']);
        }

        if (!PasswordUtils.isStrongPassword(newPassword)) {
            throw new BadRequestAppException('New password is not strong enough.', ['WEAK_PASSWORD']);
        }

        const last5Passwords = await this.userPasswordHistoryRepository.getPasswordHistoryByUserId(user.id);
        const passwordChecks = await Promise.all(
            last5Passwords.map(async (history) => {
                const passwordResult = await PasswordUtils.comparePassword(newPassword, history.passwordHash || '');
                return passwordResult;
            })
        );

        if (passwordChecks.includes(true)) {
            throw new BadRequestAppException('Your new password must be different from your 5 most recent passwords', ['PASSWORD_USED_IN_LAST_5_PASSWORDS']);
        }

        const hashedPassword = await PasswordUtils.hashPassword(newPassword);

        await this.prisma.$transaction(async (tx) => {
            await this.userRepository.updatePassword(tx, user.id, hashedPassword);
            await this.userPasswordHistoryRepository.addPasswordHistory(tx, user.id, hashedPassword);

            await tx.userToken.update({
                where: { id: resetToken.id },
                data: {
                    isUsed: true,
                    usedAt: new Date(),
                },
            });

            await tx.userToken.updateMany({
                where: {
                    userId: user.id,
                    type: UserTokenType.PASSWORD_RESET,
                    isUsed: false,
                },
                data: {
                    isUsed: true,
                    usedAt: new Date(),
                },
            });
        });

        return true;
    }

    private resolveActivityYear(year?: number): number {
        const currentYear = new Date().getFullYear();
        if (year === undefined || year === null || Number.isNaN(year)) {
            return currentYear;
        }

        if (!Number.isInteger(year) || year < 2000 || year > currentYear + 1) {
            throw new BadRequestAppException('Invalid activity year.', ['INVALID_ACTIVITY_YEAR']);
        }

        return year;
    }

    private resolveWeekStartDate(date?: string): Date {
        const targetDate = date ? new Date(`${date}T00:00:00.000Z`) : new Date();
        if (Number.isNaN(targetDate.getTime())) {
            throw new BadRequestAppException('Invalid activity date.', ['INVALID_ACTIVITY_DATE']);
        }

        const normalizedDate = new Date(Date.UTC(
            targetDate.getUTCFullYear(),
            targetDate.getUTCMonth(),
            targetDate.getUTCDate(),
        ));
        const day = normalizedDate.getUTCDay();
        const daysSinceMonday = day === 0 ? 6 : day - 1;
        normalizedDate.setUTCDate(normalizedDate.getUTCDate() - daysSinceMonday);

        return normalizedDate;
    }

    private formatDateOnly(date: Date): string {
        return date.toISOString().slice(0, 10);
    }

}
