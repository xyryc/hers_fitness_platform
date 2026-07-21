import { Body, Controller, Get, HttpCode, Param, Patch, Post, Put, Query, Request, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AdminService } from './admin.service';
import { CommissionConfigResponseDto, UpdateCommissionConfigDto } from './dto/commission-config.dto';
import {
    AdminRevenueEarningsQueryDto,
    AdminRevenueEarningsResponseDto,
    AdminRevenueStatsResponseDto,
    AdminTrainersRevenueQueryDto,
    AdminTrainersRevenueResponseDto,
} from './dto/admin-revenue.dto';
import {
    ActivitiesQueryDto,
    ActivityItemDto,
    ChartDataPointDto,
    DashboardChartQueryDto,
    DashboardSummaryResponseDto,
} from './dto/admin-dashboard.dto';
import {
    AdminStaticContentResponseDto,
    STATIC_CONTENT_KEYS,
    UpsertStaticContentDto,
} from './dto/admin-static-content.dto';
import { UserResponseDto } from '../user/dto/user-response.dto';
import { UpdateAdminProfileDto } from './dto/update-admin-profile.dto';

@ApiTags('6. Admin Dashboard')
@ApiBearerAuth('access-token')
@Controller('admin')
@UseGuards(AuthGuard, RolesGuard)
@AllowedRoles(Roles.Admin)
export class AdminController {
    constructor(private readonly adminService: AdminService) { }

    @Get('profile')
    @ApiOperation({ summary: 'Admin: get current admin profile' })
    async getProfile(@Request() req): Promise<CustomResponse<UserResponseDto>> {
        const data = await this.adminService.getAdminProfile(req.user.currentUserId);
        return new CustomResponse<UserResponseDto>('Admin profile fetched successfully', data, 200);
    }

    @Patch('profile')
    @ApiOperation({ summary: 'Admin: update current admin profile information' })
    async updateProfile(
        @Body() dto: UpdateAdminProfileDto,
        @Request() req,
    ): Promise<CustomResponse<UserResponseDto>> {
        const data = await this.adminService.updateAdminProfile(req.user.currentUserId, dto);
        return new CustomResponse<UserResponseDto>('Admin profile updated successfully', data, 200);
    }

    @Post('profile/image')
    @HttpCode(200)
    @UseInterceptors(FileInterceptor('profileImage'))
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        schema: {
            type: 'object',
            required: ['profileImage'],
            properties: {
                profileImage: { type: 'string', format: 'binary' },
            },
        },
    })
    @ApiOperation({ summary: 'Admin: upload current admin profile image' })
    async uploadProfileImage(
        @UploadedFile() profileImage: Express.Multer.File,
        @Request() req,
    ): Promise<CustomResponse<UserResponseDto>> {
        const data = await this.adminService.uploadAdminProfileImage(req.user.currentUserId, profileImage);
        return new CustomResponse<UserResponseDto>('Admin profile image uploaded successfully', data, 200);
    }

    // ─── Dashboard overview ───────────────────────────────────────────────────

    @Get('dashboard/summary')
    @ApiOperation({
        summary: 'Admin: dashboard summary metrics — revenue, commission, members, trainers, bookings, pending verifications',
        description: 'Returns current totals and month-over-month (or week-over-week for bookings) percentage trends.',
    })
    async getDashboardSummary(): Promise<CustomResponse<DashboardSummaryResponseDto>> {
        const data = await this.adminService.getDashboardSummary();
        return new CustomResponse<DashboardSummaryResponseDto>('Dashboard summary fetched successfully', data, 200);
    }

    @Get('dashboard/chart-data')
    @ApiOperation({
        summary: 'Admin: Hiring & Revenue chart — ?range=7d|30d',
        description: 'Returns a time-series array (one entry per day) with gross revenue and combined new-member+trainer count (hires).',
    })
    async getDashboardChartData(
        @Query() query: DashboardChartQueryDto,
    ): Promise<CustomResponse<ChartDataPointDto[]>> {
        const data = await this.adminService.getDashboardChartData(query);
        return new CustomResponse<ChartDataPointDto[]>('Chart data fetched successfully', data, 200);
    }

    @Get('dashboard/activities')
    @ApiOperation({
        summary: 'Admin: recent activity feed — ?limit=10',
        description: 'Returns the most recent NEW_MEMBER and PENDING_APPROVAL events sorted by date descending.',
    })
    async getDashboardActivities(
        @Query() query: ActivitiesQueryDto,
    ): Promise<CustomResponse<ActivityItemDto[]>> {
        const data = await this.adminService.getDashboardActivities(query);
        return new CustomResponse<ActivityItemDto[]>('Activities fetched successfully', data, 200);
    }

    // ─── Static content (Privacy Policy / Terms of Service / About Us) ────────

    @Get('static-content')
    @ApiOperation({ summary: 'Admin: list all static content pages (privacy-policy, terms-of-service, about-us)' })
    async listStaticContent(): Promise<CustomResponse<AdminStaticContentResponseDto[]>> {
        const data = await this.adminService.listStaticContent();
        return new CustomResponse('Static content fetched successfully', data, 200);
    }

    @Get('static-content/:key')
    @ApiOperation({ summary: 'Admin: get one static content page by key' })
    async getStaticContent(
        @Param('key') key: string,
    ): Promise<CustomResponse<AdminStaticContentResponseDto>> {
        const data = await this.adminService.getStaticContentByKey(key);
        return new CustomResponse('Static content fetched successfully', data, 200);
    }

    @Put('static-content/:key')
    @ApiOperation({
        summary: 'Admin: create or update a static content page',
        description: `Valid keys: ${STATIC_CONTENT_KEYS.join(', ')}. Creates the page if it does not exist yet.`,
    })
    async upsertStaticContent(
        @Param('key') key: string,
        @Body() dto: UpsertStaticContentDto,
    ): Promise<CustomResponse<AdminStaticContentResponseDto>> {
        const data = await this.adminService.upsertStaticContent(key, dto);
        return new CustomResponse('Static content saved successfully', data, 200);
    }

    // ─── Commission config ────────────────────────────────────────────────────

    @Get('commission')
    @ApiOperation({ summary: 'Admin: get current platform commission rate' })
    async getCommissionConfig(): Promise<CustomResponse<CommissionConfigResponseDto>> {
        const config = await this.adminService.getCommissionConfig();
        return new CustomResponse<CommissionConfigResponseDto>('Commission config fetched successfully', config, 200);
    }

    @Patch('commission')
    @ApiOperation({
        summary: 'Admin: update platform commission rate',
        description: 'Sets the % the platform takes from every booking payment. ' +
            'The new rate applies to bookings created after this call; existing payments are unaffected.',
    })
    async updateCommissionConfig(
        @Body() dto: UpdateCommissionConfigDto,
        @Request() req,
    ): Promise<CustomResponse<CommissionConfigResponseDto>> {
        const config = await this.adminService.updateCommissionConfig(dto, req.user.currentUserId);
        return new CustomResponse<CommissionConfigResponseDto>('Commission rate updated successfully', config, 200);
    }

    // ─── Revenue dashboard ────────────────────────────────────────────────────

    @Get('dashboard/revenue/stats')
    @ApiOperation({
        summary: 'Admin: platform revenue overview — gross revenue, platform fees, trainer payouts, booking count',
    })
    async getRevenueStats(): Promise<CustomResponse<AdminRevenueStatsResponseDto>> {
        const stats = await this.adminService.getRevenueStats();
        return new CustomResponse<AdminRevenueStatsResponseDto>('Revenue stats fetched successfully', stats, 200);
    }

    @Get('dashboard/revenue/earnings')
    @ApiOperation({
        summary: 'Admin: platform revenue chart — ?period=weekly|monthly|yearly. ' +
            'weekly: add ?date=YYYY-MM-DD (any day in the target week). ' +
            'monthly: add ?year=2026. ' +
            'yearly: no extra params.',
    })
    async getRevenueEarnings(
        @Query() query: AdminRevenueEarningsQueryDto,
    ): Promise<CustomResponse<AdminRevenueEarningsResponseDto>> {
        const earnings = await this.adminService.getRevenueEarnings(query);
        return new CustomResponse<AdminRevenueEarningsResponseDto>('Revenue earnings fetched successfully', earnings, 200);
    }

    @Get('dashboard/revenue/trainers')
    @ApiOperation({
        summary: 'Admin: per-trainer revenue breakdown sorted by gross revenue. ' +
            'Supports ?limit=10&offset=0 for pagination.',
    })
    async getTrainerRevenue(
        @Query() query: AdminTrainersRevenueQueryDto,
    ): Promise<CustomResponse<AdminTrainersRevenueResponseDto>> {
        const result = await this.adminService.getTrainerRevenue(query);
        return new CustomResponse<AdminTrainersRevenueResponseDto>('Trainer revenue fetched successfully', result, 200);
    }
}
