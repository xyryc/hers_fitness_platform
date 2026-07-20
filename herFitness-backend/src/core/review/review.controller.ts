import { Body, Controller, Get, HttpCode, Param, Post, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateTrainerReviewDto } from './dto/create-trainer-review.dto';
import { TrainerReviewResponseDto, TrainerReviewSummaryResponseDto } from './dto/trainer-review-response.dto';
import { ReviewService } from './review.service';

@ApiTags('6. Reviews')
@ApiBearerAuth('access-token')
@Controller('reviews')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class ReviewController {
    constructor(private readonly reviewService: ReviewService) { }

    @Post('trainers/:trainerUserId')
    @HttpCode(201)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: create or update a review for a trainer' })
    async createTrainerReview(
        @Param('trainerUserId') trainerUserId: string,
        @Body() model: CreateTrainerReviewDto,
        @Request() req,
    ): Promise<CustomResponse<TrainerReviewResponseDto>> {
        const review = await this.reviewService.createTrainerReview(req.user.currentUserId, trainerUserId, model);
        return new CustomResponse<TrainerReviewResponseDto>('Trainer review saved successfully', review, 201);
    }

    @Get('trainers/:trainerUserId')
    @ApiOperation({ summary: 'List reviews for a trainer' })
    async findTrainerReviews(
        @Param('trainerUserId') trainerUserId: string,
    ): Promise<CustomResponse<TrainerReviewResponseDto[]>> {
        const reviews = await this.reviewService.findTrainerReviews(trainerUserId);
        return new CustomResponse<TrainerReviewResponseDto[]>('Trainer reviews fetched successfully', reviews, 200);
    }

    @Get('trainers/:trainerUserId/summary')
    @ApiOperation({ summary: 'Get average rating and review count for a trainer' })
    async getTrainerReviewSummary(
        @Param('trainerUserId') trainerUserId: string,
    ): Promise<CustomResponse<TrainerReviewSummaryResponseDto>> {
        const summary = await this.reviewService.getTrainerReviewSummary(trainerUserId);
        return new CustomResponse<TrainerReviewSummaryResponseDto>('Trainer review summary fetched successfully', summary, 200);
    }

    @Get('member/trainer-reviews')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: list reviews submitted by current member' })
    async findMyTrainerReviews(@Request() req): Promise<CustomResponse<TrainerReviewResponseDto[]>> {
        const reviews = await this.reviewService.findMyTrainerReviews(req.user.currentUserId);
        return new CustomResponse<TrainerReviewResponseDto[]>('Member trainer reviews fetched successfully', reviews, 200);
    }
}
