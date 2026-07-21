import { Body, Controller, Delete, Get, HttpCode, Patch, Post, Query, Request, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { UserService } from '../../user/user.service';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { UserResponseDto } from '../../user/dto/user-response.dto';
import { UpdateTrainerProfileDto } from '../dto/update-trainer-profile.dto';
import { TrainerTransactionResponseDto } from '../dto/trainer-transaction-response.dto';
import { StripePaymentService } from 'src/infrastructure/payment/stripe/stripe-payment.service';
import {
    CreateTrainerPayoutOnboardingLinkDto,
    TrainerPayoutOnboardingLinkResponseDto,
    TrainerPayoutStatusResponseDto,
} from '../dto/trainer-payout.dto';

@ApiBearerAuth('access-token')
@Controller('users')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class TrainerUserController {
    constructor(
        private readonly userService: UserService,
        private readonly stripePaymentService: StripePaymentService,
    ) { }

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

    @ApiTags('2. Trainer App')
    @Delete('/trainer/account')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: delete (deactivate) account — soft-deletes and cancels upcoming classes' })
    async deleteTrainerAccount(@Request() req): Promise<CustomResponse<null>> {
        await this.userService.deleteTrainerAccount(req.user.currentUserId);
        return new CustomResponse<null>('Account deleted successfully', null, 200);
    }
}
