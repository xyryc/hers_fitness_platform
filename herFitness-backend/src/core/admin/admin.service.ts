import { Injectable } from '@nestjs/common';
import { AdminRepository } from './domain/admin.repository';
import { UserService } from '../user/user.service';
import { UserResponseDto } from '../user/dto/user-response.dto';
import { CloudinaryStorageService } from 'src/infrastructure/storage/cloudinary/cloudinary-storage.service';
import { CommissionConfigResponseDto, UpdateCommissionConfigDto } from './dto/commission-config.dto';
import {
    AdminRevenueEarningsQueryDto,
    AdminRevenueEarningsResponseDto,
    AdminRevenueStatsResponseDto,
    AdminTrainerRevenueItemDto,
    AdminTrainersRevenueQueryDto,
    AdminTrainersRevenueResponseDto,
    RevenueDataPointDto,
    RevenuePeriod,
} from './dto/admin-revenue.dto';
import {
    ActivityItemDto,
    ActivitiesQueryDto,
    ChartDataPointDto,
    ChartRange,
    DashboardChartQueryDto,
    DashboardSummaryResponseDto,
} from './dto/admin-dashboard.dto';
import {
    AdminStaticContentResponseDto,
    UpsertStaticContentDto,
} from './dto/admin-static-content.dto';
import { normalizeStaticContentKey } from '../user/static-content.utils';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { UpdateAdminProfileDto } from './dto/update-admin-profile.dto';

@Injectable()
export class AdminService {
    constructor(
        private readonly adminRepository: AdminRepository,
        private readonly userService: UserService,
        private readonly cloudinaryStorageService: CloudinaryStorageService,
    ) { }

    async getAdminProfile(adminUserId: string): Promise<UserResponseDto> {
        const user = await this.userService.findCurrentUser(adminUserId);
        if (!user) throw new NotFoundAppException('Admin user not found.', 'ADMIN_NOT_FOUND');
        return user;
    }

    async updateAdminProfile(adminUserId: string, dto: UpdateAdminProfileDto): Promise<UserResponseDto> {
        const email = dto.email?.trim().toLowerCase();
        if (email) {
            const existing = await this.adminRepository.findUserByEmail(email);
            if (existing && existing.id !== adminUserId) {
                throw new BadRequestAppException('Email address is already in use.', ['EMAIL_ALREADY_EXISTS']);
            }
        }

        const profileFields = this.buildAdminProfileFields(dto);
        if (Object.keys(profileFields).length > 0) {
            await this.adminRepository.updateAdminProfile(adminUserId, profileFields);
        }

        return this.getAdminProfile(adminUserId);
    }

    async uploadAdminProfileImage(adminUserId: string, profileImage?: Express.Multer.File): Promise<UserResponseDto> {
        if (!profileImage) {
            throw new BadRequestAppException('Profile image is required.', ['PROFILE_IMAGE_REQUIRED']);
        }

        const upload = await this.cloudinaryStorageService.uploadImage(profileImage, 'admins/profile-images');
        if (!upload.secureUrl) {
            throw new BadRequestAppException('Profile image upload failed.', ['FILE_UPLOAD_ERROR']);
        }

        await this.adminRepository.updateAdminProfile(adminUserId, {
            profileImageUrl: upload.secureUrl,
        });

        return this.getAdminProfile(adminUserId);
    }

    // ─── Commission config ────────────────────────────────────────────────────

    async getCommissionConfig(): Promise<CommissionConfigResponseDto> {
        const config = await this.adminRepository.getCommissionConfig();
        return new CommissionConfigResponseDto(config);
    }

    async updateCommissionConfig(
        dto: UpdateCommissionConfigDto,
        adminUserId: string,
    ): Promise<CommissionConfigResponseDto> {
        const config = await this.adminRepository.updateCommissionConfig(dto.commissionRate, adminUserId);
        return new CommissionConfigResponseDto(config);
    }

    // ─── Revenue overview ─────────────────────────────────────────────────────

    async getRevenueStats(): Promise<AdminRevenueStatsResponseDto> {
        const [stats, config] = await Promise.all([
            this.adminRepository.getRevenueStats(),
            this.adminRepository.getCommissionConfig(),
        ]);

        return new AdminRevenueStatsResponseDto({
            ...stats,
            currentCommissionRate: Number(config.commissionRate),
        });
    }

    // ─── Earnings charts ──────────────────────────────────────────────────────

    async getRevenueEarnings(query: AdminRevenueEarningsQueryDto): Promise<AdminRevenueEarningsResponseDto> {
        const payments = await this.adminRepository.getPaidPaymentsForChart();
        const period = query.period ?? RevenuePeriod.MONTHLY;

        if (period === RevenuePeriod.WEEKLY) return this.buildWeeklyEarnings(payments, query.date);
        if (period === RevenuePeriod.MONTHLY) return this.buildMonthlyEarnings(payments, query.year);
        return this.buildYearlyEarnings(payments);
    }

    private buildWeeklyEarnings(
        payments: { paidAt: Date; totalAmount: any; platformFeeAmount: any; trainerPayoutAmount: any }[],
        dateInput?: string,
    ): AdminRevenueEarningsResponseDto {
        const anchor = dateInput ? new Date(dateInput) : new Date();
        const dayOfWeek = anchor.getUTCDay();
        const diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
        const monday = new Date(anchor);
        monday.setUTCDate(anchor.getUTCDate() + diffToMonday);

        const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const data: RevenueDataPointDto[] = DAY_LABELS.map((label, i) => {
            const day = new Date(monday);
            day.setUTCDate(monday.getUTCDate() + i);
            const key = day.toISOString().slice(0, 10);
            const matched = payments.filter((p) => p.paidAt?.toISOString().slice(0, 10) === key);
            return new RevenueDataPointDto({
                label,
                key,
                grossRevenue: this.sum(matched, 'totalAmount'),
                platformFee: this.sum(matched, 'platformFeeAmount'),
                trainerPayout: this.sum(matched, 'trainerPayoutAmount'),
            });
        });

        const weekStartDate = monday.toISOString().slice(0, 10);
        const weekEnd = new Date(monday);
        weekEnd.setUTCDate(monday.getUTCDate() + 6);

        return new AdminRevenueEarningsResponseDto({
            period: 'weekly',
            data,
            totalGrossRevenue: this.sumPoints(data, 'grossRevenue'),
            totalPlatformFee: this.sumPoints(data, 'platformFee'),
            totalTrainerPayout: this.sumPoints(data, 'trainerPayout'),
            weekStartDate,
            weekEndDate: weekEnd.toISOString().slice(0, 10),
        });
    }

    private buildMonthlyEarnings(
        payments: { paidAt: Date; totalAmount: any; platformFeeAmount: any; trainerPayoutAmount: any }[],
        yearInput?: number,
    ): AdminRevenueEarningsResponseDto {
        const year = yearInput ?? new Date().getUTCFullYear();
        const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        const data: RevenueDataPointDto[] = MONTH_LABELS.map((label, i) => {
            const key = `${year}-${String(i + 1).padStart(2, '0')}`;
            const matched = payments.filter((p) => p.paidAt?.toISOString().slice(0, 7) === key);
            return new RevenueDataPointDto({
                label,
                key,
                grossRevenue: this.sum(matched, 'totalAmount'),
                platformFee: this.sum(matched, 'platformFeeAmount'),
                trainerPayout: this.sum(matched, 'trainerPayoutAmount'),
            });
        });

        return new AdminRevenueEarningsResponseDto({
            period: 'monthly',
            data,
            totalGrossRevenue: this.sumPoints(data, 'grossRevenue'),
            totalPlatformFee: this.sumPoints(data, 'platformFee'),
            totalTrainerPayout: this.sumPoints(data, 'trainerPayout'),
            year,
        });
    }

    private buildYearlyEarnings(
        payments: { paidAt: Date; totalAmount: any; platformFeeAmount: any; trainerPayoutAmount: any }[],
    ): AdminRevenueEarningsResponseDto {
        const yearMap = new Map<string, { grossRevenue: number; platformFee: number; trainerPayout: number }>();

        for (const p of payments) {
            const key = String(p.paidAt?.getUTCFullYear() ?? new Date().getUTCFullYear());
            const existing = yearMap.get(key) ?? { grossRevenue: 0, platformFee: 0, trainerPayout: 0 };
            existing.grossRevenue += Number(p.totalAmount);
            existing.platformFee += Number(p.platformFeeAmount);
            existing.trainerPayout += Number(p.trainerPayoutAmount);
            yearMap.set(key, existing);
        }

        if (yearMap.size === 0) {
            yearMap.set(String(new Date().getUTCFullYear()), { grossRevenue: 0, platformFee: 0, trainerPayout: 0 });
        }

        const data: RevenueDataPointDto[] = Array.from(yearMap.entries())
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([key, vals]) => new RevenueDataPointDto({
                label: key,
                key,
                grossRevenue: Number(vals.grossRevenue.toFixed(2)),
                platformFee: Number(vals.platformFee.toFixed(2)),
                trainerPayout: Number(vals.trainerPayout.toFixed(2)),
            }));

        return new AdminRevenueEarningsResponseDto({
            period: 'yearly',
            data,
            totalGrossRevenue: this.sumPoints(data, 'grossRevenue'),
            totalPlatformFee: this.sumPoints(data, 'platformFee'),
            totalTrainerPayout: this.sumPoints(data, 'trainerPayout'),
        });
    }

    // ─── Per-trainer breakdown ────────────────────────────────────────────────

    async getTrainerRevenue(query: AdminTrainersRevenueQueryDto): Promise<AdminTrainersRevenueResponseDto> {
        const limit = Math.min(Math.max(Number(query.limit ?? 10), 1), 50);
        const offset = Math.max(Number(query.offset ?? 0), 0);

        const { items, total } = await this.adminRepository.getTrainerRevenue(limit, offset);

        return new AdminTrainersRevenueResponseDto({
            items: items.map((item) => new AdminTrainerRevenueItemDto(item)),
            total,
            limit,
            offset,
        });
    }

    // ─── Dashboard overview ───────────────────────────────────────────────────

    async getDashboardSummary(): Promise<DashboardSummaryResponseDto> {
        const d = await this.adminRepository.getDashboardSummaryData();

        return new DashboardSummaryResponseDto({
            totalRevenue: d.allTimeRevenue,
            totalRevenueTrend: this.calcTrend(d.currentMonthRevenue, d.lastMonthRevenue),
            platformCommission: d.allTimeCommission,
            platformCommissionTrend: this.calcTrend(d.currentMonthCommission, d.lastMonthCommission),
            pendingVerifications: d.pendingVerificationsCount,
            totalMembers: d.totalMembersCount,
            totalMembersTrend: this.calcTrend(d.newMembersThisMonth, d.newMembersLastMonth),
            activeMembers: d.activeMembersCount,
            activeMembersTrend: this.calcTrend(d.newActiveMembersThisMonth, d.newActiveMembersLastMonth),
            trainers: d.totalTrainersCount,
            trainersTrend: this.calcTrend(d.newTrainersThisMonth, d.newTrainersLastMonth),
            bookingsThisWeek: d.bookingsThisWeekCount,
            bookingsThisWeekTrend: this.calcTrend(d.bookingsThisWeekCount, d.bookingsLastWeekCount),
        });
    }

    async getDashboardChartData(query: DashboardChartQueryDto): Promise<ChartDataPointDto[]> {
        const range = query.range ?? ChartRange.SEVEN_DAYS;
        const days = range === ChartRange.SEVEN_DAYS ? 7 : 30;

        const now = new Date();
        const endDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)); // midnight tomorrow
        const startDate = new Date(endDate);
        startDate.setUTCDate(endDate.getUTCDate() - days);

        const { payments, newUsers } = await this.adminRepository.getChartRawData(startDate, endDate);

        // Build a point per day
        const points: ChartDataPointDto[] = [];
        for (let i = 0; i < days; i++) {
            const day = new Date(startDate);
            day.setUTCDate(startDate.getUTCDate() + i);
            const key = day.toISOString().slice(0, 10); // "YYYY-MM-DD"

            const label = days === 7
                ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.getUTCDay()]
                : `${day.getUTCDate()} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][day.getUTCMonth()]}`;

            const dayRevenue = payments
                .filter((p) => p.paidAt?.toISOString().slice(0, 10) === key)
                .reduce((acc, p) => acc + Number(p.totalAmount ?? 0), 0);

            const dayHires = newUsers.filter(
                (u) => u.createdAt?.toISOString().slice(0, 10) === key,
            ).length;

            points.push(new ChartDataPointDto({ label, revenue: dayRevenue, hires: dayHires }));
        }

        return points;
    }

    async getDashboardActivities(query: ActivitiesQueryDto): Promise<ActivityItemDto[]> {
        const limit = Math.min(Math.max(Number(query.limit ?? 10), 1), 50);
        const { newMembers, pendingVerifications } = await this.adminRepository.getRecentActivityRawData(limit);

        const resolveName = (u: { displayName: string | null; firstName: string | null }): string =>
            u.displayName ?? u.firstName ?? 'Unknown User';

        const memberEvents: ActivityItemDto[] = newMembers.map(
            (m) => new ActivityItemDto({
                type: 'NEW_MEMBER',
                title: 'New Member Joined',
                person: resolveName(m),
                occurredAt: m.createdAt,
            }),
        );

        const verificationEvents: ActivityItemDto[] = pendingVerifications.map(
            (v) => new ActivityItemDto({
                type: 'PENDING_APPROVAL',
                title: 'Trainer Verification Pending',
                person: resolveName(v.user),
                occurredAt: v.createdAt,
            }),
        );

        // Merge both streams, sort newest-first, return top `limit`
        return [...memberEvents, ...verificationEvents]
            .sort((a, b) => new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime())
            .slice(0, limit);
    }

    // ─── Static content ───────────────────────────────────────────────────────

    async listStaticContent(): Promise<AdminStaticContentResponseDto[]> {
        const rows = await this.adminRepository.listStaticContent();
        const byKey = new Map<string, any>();

        for (const row of rows) {
            const canonicalKey = normalizeStaticContentKey(row.key);
            if (!canonicalKey) continue;

            const existing = byKey.get(canonicalKey);
            if (!existing || existing.key !== canonicalKey) {
                byKey.set(canonicalKey, { ...row, key: canonicalKey });
            }
        }

        return ['privacy-policy', 'terms-of-service', 'about-us']
            .map((key) => byKey.get(key))
            .filter(Boolean)
            .map((r) => new AdminStaticContentResponseDto(r));
    }

    async getStaticContentByKey(key: string): Promise<AdminStaticContentResponseDto> {
        const canonicalKey = this.resolveStaticContentKey(key);
        const row = await this.adminRepository.findStaticContentByKey(canonicalKey);
        if (!row) {
            // Return an empty shell so the admin UI knows the page exists but has no content yet
            return new AdminStaticContentResponseDto({
                key: canonicalKey,
                title: '',
                content: '',
                createdAt: new Date(),
                updatedAt: null,
            });
        }
        return new AdminStaticContentResponseDto(row);
    }

    async upsertStaticContent(key: string, dto: UpsertStaticContentDto): Promise<AdminStaticContentResponseDto> {
        const canonicalKey = this.resolveStaticContentKey(key);
        const row = await this.adminRepository.upsertStaticContent(canonicalKey, dto.title, dto.content);
        return new AdminStaticContentResponseDto(row);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /** Returns % change of current vs previous, rounded to 1 decimal. */
    private calcTrend(current: number, previous: number): number {
        if (previous === 0) return current > 0 ? 100 : 0;
        return Number(((current - previous) / previous * 100).toFixed(1));
    }

    private sum(rows: any[], field: string): number {
        return Number(rows.reduce((acc, r) => acc + Number(r[field] ?? 0), 0).toFixed(2));
    }

    private sumPoints(points: RevenueDataPointDto[], field: keyof RevenueDataPointDto): number {
        return Number(points.reduce((acc, p) => acc + Number(p[field] ?? 0), 0).toFixed(2));
    }

    private resolveStaticContentKey(key: string): string {
        const canonicalKey = normalizeStaticContentKey(key);
        if (!canonicalKey) {
            throw new BadRequestAppException(
                'Invalid static content key.',
                ['Valid keys are: privacy-policy, terms-of-service, about-us'],
            );
        }

        return canonicalKey;
    }

    private buildAdminProfileFields(dto: UpdateAdminProfileDto): Record<string, string | null> {
        const fields: Record<string, string | null> = {};

        const fullName = dto.fullName?.trim();
        if (fullName !== undefined) {
            fields.displayName = fullName;
            if (dto.firstName === undefined && dto.lastName === undefined) {
                const [firstName, ...lastNameParts] = fullName.split(/\s+/).filter(Boolean);
                fields.firstName = firstName ?? null;
                fields.lastName = lastNameParts.length ? lastNameParts.join(' ') : null;
            }
        }

        if (dto.displayName !== undefined) fields.displayName = dto.displayName.trim();
        if (dto.firstName !== undefined) fields.firstName = dto.firstName.trim();
        if (dto.lastName !== undefined) fields.lastName = dto.lastName.trim() || null;
        if (dto.email !== undefined) fields.email = dto.email.trim().toLowerCase();
        if (dto.phoneNumber !== undefined) fields.phoneNumber = dto.phoneNumber.trim() || null;

        return fields;
    }
}
