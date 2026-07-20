import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Put, Query, Request, Res, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { StripePaymentService } from 'src/infrastructure/payment/stripe/stripe-payment.service';
import {
    CreateTrainerPayoutOnboardingLinkDto,
    TrainerPayoutOnboardingLinkResponseDto,
    TrainerPayoutStatusResponseDto,
} from 'src/core/trainer/dto/trainer-payout.dto';
import { UserService } from './user.service';
import { UserResponseDto } from './dto/user-response.dto';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { CreateUserDto } from './dto/create-user.dto';
import type { Response } from 'express';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { CloudinaryStorageService } from 'src/infrastructure/storage/cloudinary/cloudinary-storage.service';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { AllowPendingAccount } from 'src/common/decorators/allow-pending-account.decorator';
import { UpsertMemberFitnessAssessmentDto } from './dto/upsert-member-fitness-assessment.dto';
import { MemberFitnessAssessmentResponseDto } from './dto/member-fitness-assessment-response.dto';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FavoriteTrainerResponseDto } from './dto/favorite-trainer-response.dto';
import { AdminUserListItemDto } from './dto/admin-user-list-item.dto';
import { AdminTrainerListItemDto } from './dto/admin-trainer-list-item.dto';
import { AdminVerificationRequestDto } from './dto/admin-verification-request.dto';
import { MemberMonthlyActivityResponseDto } from './dto/member-monthly-activity-response.dto';
import { MemberDailyActivityResponseDto } from './dto/member-daily-activity-response.dto';
import { MemberWeeklyActivityResponseDto } from './dto/member-weekly-activity-response.dto';
import { MemberYearlyActivityResponseDto } from './dto/member-yearly-activity-response.dto';
import { MemberTransactionResponseDto } from './dto/member-transaction-response.dto';
import { MemberReferralResponseDto } from './dto/member-referral-response.dto';
import { StaticContentResponseDto } from './dto/static-content-response.dto';
import { UpdateMemberProfileDto } from './dto/update-member-profile.dto';
import { UpdateTrainerProfileDto } from './dto/update-trainer-profile.dto';
import { TrainerTransactionResponseDto } from './dto/trainer-transaction-response.dto';

@ApiBearerAuth('access-token')
@Controller('users')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class UserController {
    constructor(
        private readonly userService: UserService,
        private readonly cloudinaryStorageService: CloudinaryStorageService,
        private readonly stripePaymentService: StripePaymentService,
    ) { }

    @ApiTags('0. Auth & Onboarding')
    @Get('me')
    @AllowPendingAccount()
    async getCurrentUser(@Request() req): Promise<CustomResponse<UserResponseDto | null>> {
        const user = await this.userService.findCurrentUser(req.user.currentUserId);
        if (!user) {
            throw new NotFoundAppException('User not found', 'USER_NOT_FOUND');
        }
        return new CustomResponse<UserResponseDto | null>('User fetched successfully', user, 200);
    }

    // example with file upload feature
    @ApiTags('0. Auth & Onboarding')
    @Post('/')
    @HttpCode(201)
    @UseInterceptors(
        FileFieldsInterceptor([
            { name: 'profilePicture', maxCount: 1 },
            { name: 'documents', maxCount: 5 },
        ]),
    )
    async createUser(
        @Body() model: CreateUserDto,
        @Res({ passthrough: true }) res: Response,
        @UploadedFiles()
        files: {
            profilePicture?: Express.Multer.File[];
            documents?: Express.Multer.File[];
        },
    ) {
        //res.status(200); // to set conditional status code

        if (files) {
            if (files.profilePicture && files.profilePicture[0]) {
                const profilePicture = files.profilePicture[0];
                if (profilePicture) {
                    const uploadResponse = await this.cloudinaryStorageService.uploadImage(profilePicture, 'users/profile-images');
                    if (!uploadResponse.secureUrl) {
                        throw new BadRequestAppException('Failed to upload profile picture', ['FILE_UPLOAD_ERROR']);
                    }
                    console.log('Path: ', uploadResponse.secureUrl);
                }
            }
        }

        return new CustomResponse('User created successfully', model, 201);
    }

    @ApiTags('0. Auth & Onboarding')
    @Put('/')
    @HttpCode(200)
    @AllowPendingAccount()
    async changePassword(@Body() model: UpdatePasswordDto, @Request() req) {
        await this.userService.updatePassword(req.user.currentUserId, model.newPassword, model.currentPassword);
        return new CustomResponse('Password updated successfully', model, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member-assessment')
    @AllowPendingAccount()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    async getMemberAssessment(@Request() req) {
        const assessment = await this.userService.getMemberFitnessAssessment(req.user.currentUserId);
        return new CustomResponse<MemberFitnessAssessmentResponseDto | null>('Member fitness assessment fetched successfully', assessment, 200);
    }

    @ApiTags('1. Member App')
    @Put('/member-assessment')
    @HttpCode(200)
    @AllowPendingAccount()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    async upsertMemberAssessment(@Body() model: UpsertMemberFitnessAssessmentDto, @Request() req) {
        const assessment = await this.userService.upsertMemberFitnessAssessment(req.user.currentUserId, model);
        return new CustomResponse<MemberFitnessAssessmentResponseDto>('Member fitness assessment saved successfully', assessment, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/favorite-trainers')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: list favorite trainers' })
    async getFavoriteTrainers(@Request() req): Promise<CustomResponse<FavoriteTrainerResponseDto[]>> {
        const trainers = await this.userService.findFavoriteTrainers(req.user.currentUserId);
        return new CustomResponse<FavoriteTrainerResponseDto[]>('Favorite trainers fetched successfully', trainers, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/monthly-activity')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: monthly workout activity for a selected year' })
    async getMemberMonthlyActivity(
        @Request() req,
        @Query('year') year?: string,
    ): Promise<CustomResponse<MemberMonthlyActivityResponseDto>> {
        const activity = await this.userService.findMemberMonthlyActivity(
            req.user.currentUserId,
            year ? Number(year) : undefined,
        );
        return new CustomResponse<MemberMonthlyActivityResponseDto>('Member monthly activity fetched successfully', activity, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/daily-activity')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: daily workout activity for a specific month (31-day bar chart)' })
    async getMemberDailyActivity(
        @Request() req,
        @Query('month') month?: string,
        @Query('year') year?: string,
    ): Promise<CustomResponse<MemberDailyActivityResponseDto>> {
        const activity = await this.userService.findMemberDailyActivity(
            req.user.currentUserId,
            month ? Number(month) : undefined,
            year ? Number(year) : undefined,
        );
        return new CustomResponse<MemberDailyActivityResponseDto>('Member daily activity fetched successfully', activity, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/weekly-activity')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: weekly workout activity for a selected date' })
    async getMemberWeeklyActivity(
        @Request() req,
        @Query('date') date?: string,
    ): Promise<CustomResponse<MemberWeeklyActivityResponseDto>> {
        const activity = await this.userService.findMemberWeeklyActivity(req.user.currentUserId, date);
        return new CustomResponse<MemberWeeklyActivityResponseDto>('Member weekly activity fetched successfully', activity, 200);
    }

    @ApiTags('1. Member App')
    @Patch('/member/profile')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: update personal info (displayName, phoneNumber, state, location, age, weight, dietPreference)' })
    async updateMemberProfile(
        @Body() model: UpdateMemberProfileDto,
        @Request() req,
    ): Promise<CustomResponse<UserResponseDto>> {
        const user = await this.userService.updateMemberProfile(req.user.currentUserId, model);
        return new CustomResponse<UserResponseDto>('Profile updated successfully', user, 200);
    }

    @ApiTags('1. Member App')
    @Post('/member/profile/images')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @UseInterceptors(
        FileFieldsInterceptor([
            { name: 'profileImage', maxCount: 1 },
            { name: 'coverImage', maxCount: 1 },
        ]),
    )
    @ApiOperation({ summary: 'Member: upload profile image and/or cover photo (multipart/form-data)' })
    async uploadMemberProfileImages(
        @Request() req,
        @UploadedFiles() files: { profileImage?: Express.Multer.File[]; coverImage?: Express.Multer.File[] },
    ): Promise<CustomResponse<UserResponseDto>> {
        const user = await this.userService.uploadMemberProfileImages(req.user.currentUserId, {
            profileImage: files?.profileImage?.[0],
            coverImage: files?.coverImage?.[0],
        });
        return new CustomResponse<UserResponseDto>('Profile images uploaded successfully', user, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/yearly-activity')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: yearly workout activity breakdown (all years with data)' })
    async getMemberYearlyActivity(
        @Request() req,
    ): Promise<CustomResponse<MemberYearlyActivityResponseDto>> {
        const activity = await this.userService.findMemberYearlyActivity(req.user.currentUserId);
        return new CustomResponse<MemberYearlyActivityResponseDto>('Member yearly activity fetched successfully', activity, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/transactions')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: list all successful payment transactions' })
    async getMemberTransactions(
        @Request() req,
    ): Promise<CustomResponse<MemberTransactionResponseDto[]>> {
        const transactions = await this.userService.findMemberTransactions(req.user.currentUserId);
        return new CustomResponse<MemberTransactionResponseDto[]>('Member transactions fetched successfully', transactions, 200);
    }

    @ApiTags('1. Member App')
    @Get('/member/referral')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: get unique referral code and sharing link' })
    async getMemberReferral(@Request() req): Promise<CustomResponse<MemberReferralResponseDto>> {
        const referral = this.userService.getMemberReferral(req.user.currentUserId);
        return new CustomResponse<MemberReferralResponseDto>('Referral fetched successfully', referral, 200);
    }

    @ApiTags('1. Member App')
    @Delete('/member/account')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: delete (deactivate) account — sets isActive=false' })
    async deleteMemberAccount(@Request() req): Promise<CustomResponse<null>> {
        await this.userService.deleteMemberAccount(req.user.currentUserId);
        return new CustomResponse<null>('Account deleted successfully', null, 200);
    }

    @ApiTags('1. Member App')
    @Post('/member/favorite-trainers/:trainerUserId')
    @HttpCode(201)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: add trainer to favorites' })
    async addFavoriteTrainer(
        @Param('trainerUserId') trainerUserId: string,
        @Request() req,
    ): Promise<CustomResponse<FavoriteTrainerResponseDto>> {
        const trainer = await this.userService.addFavoriteTrainer(req.user.currentUserId, trainerUserId);
        return new CustomResponse<FavoriteTrainerResponseDto>('Trainer added to favorites successfully', trainer, 201);
    }

    @ApiTags('1. Member App')
    @Delete('/member/favorite-trainers/:trainerUserId')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: remove trainer from favorites' })
    async removeFavoriteTrainer(
        @Param('trainerUserId') trainerUserId: string,
        @Request() req,
    ): Promise<CustomResponse<null>> {
        await this.userService.removeFavoriteTrainer(req.user.currentUserId, trainerUserId);
        return new CustomResponse<null>('Trainer removed from favorites successfully', null, 200);
    }

    // ─── Trainer endpoints ────────────────────────────────────────────────────────

    @ApiTags('2. Trainer App')
    @Patch('/trainer/profile')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: update personal info & profile fields' })
    async updateTrainerProfile(
        @Body() model: UpdateTrainerProfileDto,
        @Request() req,
    ): Promise<CustomResponse<UserResponseDto>> {
        const user = await this.userService.updateTrainerProfile(req.user.currentUserId, model);
        return new CustomResponse<UserResponseDto>('Profile updated successfully', user, 200);
    }

    @ApiTags('2. Trainer App')
    @Post('/trainer/profile/images')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @UseInterceptors(
        FileFieldsInterceptor([
            { name: 'profileImage', maxCount: 1 },
            { name: 'coverImage', maxCount: 1 },
        ]),
    )
    @ApiOperation({ summary: 'Trainer: upload profile image and/or cover photo (multipart/form-data)' })
    async uploadTrainerProfileImages(
        @Request() req,
        @UploadedFiles() files: { profileImage?: Express.Multer.File[]; coverImage?: Express.Multer.File[] },
    ): Promise<CustomResponse<{ imageUrl: string | null; coverPhotoUrl: string | null }>> {
        const result = await this.userService.uploadTrainerProfileImages(req.user.currentUserId, {
            profileImage: files?.profileImage?.[0],
            coverImage: files?.coverImage?.[0],
        });
        return new CustomResponse('Profile images uploaded successfully', result, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('/trainer/transactions')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: list earnings / payment transactions' })
    async getTrainerTransactions(
        @Request() req,
        @Query('page') page?: string,
        @Query('limit') limit?: string,
        @Query('startDate') startDate?: string,
        @Query('endDate') endDate?: string,
    ): Promise<CustomResponse<TrainerTransactionResponseDto[]>> {
        const result = await this.userService.findTrainerTransactions(req.user.currentUserId, {
            page: page ? Math.max(1, parseInt(page, 10)) : 1,
            limit: limit ? Math.min(100, Math.max(1, parseInt(limit, 10))) : 20,
            startDate,
            endDate,
        });
        const response = new CustomResponse<TrainerTransactionResponseDto[]>(
            'Trainer transactions fetched successfully',
            result.data,
            200,
        );
        (response as any).meta = result.meta;
        return response;
    }

    @ApiTags('2. Trainer App')
    @Delete('/trainer/account')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: delete (deactivate) account — soft-deletes and cancels upcoming classes' })
    async deleteTrainerAccount(@Request() req): Promise<CustomResponse<null>> {
        await this.userService.deleteTrainerAccount(req.user.currentUserId);
        return new CustomResponse<null>('Account deleted successfully', null, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('/trainer/payout/status')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: get Stripe payout onboarding/status' })
    async getTrainerPayoutStatus(@Request() req): Promise<CustomResponse<TrainerPayoutStatusResponseDto>> {
        const status = await this.stripePaymentService.getTrainerPayoutStatus(req.user.currentUserId, true);
        return new CustomResponse<TrainerPayoutStatusResponseDto>(
            'Trainer payout status fetched successfully',
            new TrainerPayoutStatusResponseDto(status),
            200,
        );
    }

    @ApiTags('2. Trainer App')
    @Post('/trainer/payout/onboarding-link')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: create Stripe Connect onboarding link' })
    async createTrainerPayoutOnboardingLink(
        @Request() req,
        @Body() model: CreateTrainerPayoutOnboardingLinkDto,
    ): Promise<CustomResponse<TrainerPayoutOnboardingLinkResponseDto>> {
        const result = await this.stripePaymentService.createTrainerOnboardingLink({
            trainerUserId: req.user.currentUserId,
            returnUrl: model.returnUrl,
            refreshUrl: model.refreshUrl,
        });
        return new CustomResponse<TrainerPayoutOnboardingLinkResponseDto>(
            'Trainer payout onboarding link created successfully',
            new TrainerPayoutOnboardingLinkResponseDto({
                ...result.status,
                onboardingUrl: result.url,
                expiresAt: result.expiresAt,
            }),
            200,
        );
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/verifications')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: list pending member and trainer verifications' })
    async getPendingVerifications(
        @Query('type') type?: string,
    ): Promise<CustomResponse<AdminVerificationRequestDto[]>> {
        const verifications = await this.userService.findPendingVerificationRequests(type);
        return new CustomResponse<AdminVerificationRequestDto[]>('Pending verifications fetched successfully', verifications, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/members')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: list all members' })
    async getAllMembers(): Promise<CustomResponse<AdminUserListItemDto[]>> {
        const members = await this.userService.findAllMembers();
        return new CustomResponse<AdminUserListItemDto[]>('Members fetched successfully', members, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/members/:userId')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: get member details' })
    async getMemberDetails(@Param('userId') userId: string): Promise<CustomResponse<UserResponseDto>> {
        const member = await this.userService.findAdminMemberById(userId);
        return new CustomResponse<UserResponseDto>('Member fetched successfully', member, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/trainers')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: list all trainers' })
    async getAllTrainers(): Promise<CustomResponse<AdminTrainerListItemDto[]>> {
        const trainers = await this.userService.findAllTrainers();
        return new CustomResponse<AdminTrainerListItemDto[]>('Trainers fetched successfully', trainers, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/trainers/:userId')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: get trainer details' })
    async getTrainerDetails(@Param('userId') userId: string): Promise<CustomResponse<UserResponseDto>> {
        const trainer = await this.userService.findAdminTrainerById(userId);
        return new CustomResponse<UserResponseDto>('Trainer fetched successfully', trainer, 200);
    }

    @ApiTags('7. Admin Portal')
    @Patch('/admin/:userId/approve')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: approve a member or trainer account' })
    async approveUser(
        @Param('userId') userId: string,
        @Request() req,
    ): Promise<CustomResponse<UserResponseDto>> {
        const user = await this.userService.approveUserVerification(userId, req.user.currentUserId);
        return new CustomResponse<UserResponseDto>('User approved successfully', user, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get(':email')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin, Roles.Trainer) // for authorization. Role based authorization
    async getUserByEmail(@Param('email') email: string): Promise<CustomResponse<UserResponseDto | null>> {
        const user = await this.userService.findByEmail(email);

        if (!user) {
            throw new NotFoundAppException('User not found', 'USER_NOT_FOUND');
        }

        return new CustomResponse<UserResponseDto | null>('User fetched successfully', user, 200);
    }
}

import { Controller as PublicController, Get as PublicGet, Param as PublicParam } from '@nestjs/common';
import { ApiOperation as PublicApiOperation, ApiTags as PublicApiTags } from '@nestjs/swagger';

@PublicApiTags('5. Public')
@PublicController('static-content')
export class StaticContentController {
    constructor(private readonly userService: UserService) {}

    @PublicGet(':key')
    @PublicApiOperation({ summary: 'Public: get static content by key (privacy-policy, terms-of-service, about-us)' })
    async getStaticContent(
        @PublicParam('key') key: string,
    ): Promise<CustomResponse<StaticContentResponseDto>> {
        const content = await this.userService.getStaticContent(key);
        return new CustomResponse<StaticContentResponseDto>('Content fetched successfully', content, 200);
    }
}
