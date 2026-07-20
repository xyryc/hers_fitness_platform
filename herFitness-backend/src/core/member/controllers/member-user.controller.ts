import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Put, Query, Request, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { UserService } from '../../user/user.service';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { AllowPendingAccount } from 'src/common/decorators/allow-pending-account.decorator';
import { UserResponseDto } from '../../user/dto/user-response.dto';
import { MemberFitnessAssessmentResponseDto } from '../dto/member-fitness-assessment-response.dto';
import { UpsertMemberFitnessAssessmentDto } from '../dto/upsert-member-fitness-assessment.dto';
import { FavoriteTrainerResponseDto } from '../dto/favorite-trainer-response.dto';
import { MemberMonthlyActivityResponseDto } from '../dto/member-monthly-activity-response.dto';
import { MemberDailyActivityResponseDto } from '../dto/member-daily-activity-response.dto';
import { MemberWeeklyActivityResponseDto } from '../dto/member-weekly-activity-response.dto';
import { UpdateMemberProfileDto } from '../dto/update-member-profile.dto';
import { MemberYearlyActivityResponseDto } from '../dto/member-yearly-activity-response.dto';
import { MemberTransactionResponseDto } from '../dto/member-transaction-response.dto';
import { MemberReferralResponseDto } from '../dto/member-referral-response.dto';

@ApiBearerAuth('access-token')
@Controller('users')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class MemberUserController {
    constructor(private readonly userService: UserService) { }

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
}
