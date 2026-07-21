import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

// ─── Query ────────────────────────────────────────────────────────────────────

export enum RevenuePeriod {
    WEEKLY = 'weekly',
    MONTHLY = 'monthly',
    YEARLY = 'yearly',
}

export class AdminRevenueEarningsQueryDto {
    @ApiPropertyOptional({ enum: RevenuePeriod, default: RevenuePeriod.MONTHLY })
    @IsEnum(RevenuePeriod)
    @IsOptional()
    period?: RevenuePeriod = RevenuePeriod.MONTHLY;

    /** ISO date string — any day within the target week (weekly period only) */
    @ApiPropertyOptional({ example: '2026-05-25' })
    @IsString()
    @IsOptional()
    date?: string;

    /** Four-digit year (monthly period only) */
    @ApiPropertyOptional({ example: 2026 })
    @Type(() => Number)
    @IsNumber()
    @IsOptional()
    year?: number;
}

export class AdminTrainersRevenueQueryDto {
    @ApiPropertyOptional({ default: 10, minimum: 1 })
    @Type(() => Number)
    @IsNumber()
    @Min(1)
    @IsOptional()
    limit?: number = 10;

    @ApiPropertyOptional({ default: 0, minimum: 0 })
    @Type(() => Number)
    @IsNumber()
    @Min(0)
    @IsOptional()
    offset?: number = 0;
}

// ─── Responses ────────────────────────────────────────────────────────────────

export class AdminRevenueStatsResponseDto {
    /** Total gross amount collected from members (sum of all PAID booking payments) */
    totalGrossRevenue: string;
    /** Platform's share (sum of platformFeeAmount) */
    totalPlatformFee: string;
    /** Amount paid out to trainers (sum of trainerPayoutAmount) */
    totalTrainerPayout: string;
    /** Current commission rate in effect */
    currentCommissionRate: string;
    /** Total number of PAID booking payments */
    totalPaidBookings: number;
    /** Number of unique trainers who received at least one paid booking */
    activeTrainerCount: number;

    constructor(data: {
        totalGrossRevenue: number;
        totalPlatformFee: number;
        totalTrainerPayout: number;
        currentCommissionRate: number;
        totalPaidBookings: number;
        activeTrainerCount: number;
    }) {
        this.totalGrossRevenue = data.totalGrossRevenue.toFixed(2);
        this.totalPlatformFee = data.totalPlatformFee.toFixed(2);
        this.totalTrainerPayout = data.totalTrainerPayout.toFixed(2);
        this.currentCommissionRate = data.currentCommissionRate.toFixed(2);
        this.totalPaidBookings = data.totalPaidBookings;
        this.activeTrainerCount = data.activeTrainerCount;
    }
}

export class RevenueDataPointDto {
    /** Human-readable label (e.g. "Mon", "Jan", "2026") */
    label: string;
    /** Sortable key (e.g. "2026-05-25", "2026-05", "2026") */
    key: string;
    /** Gross revenue for this period */
    grossRevenue: number;
    /** Platform fee for this period */
    platformFee: number;
    /** Trainer payout for this period */
    trainerPayout: number;

    constructor(data: { label: string; key: string; grossRevenue: number; platformFee: number; trainerPayout: number }) {
        this.label = data.label;
        this.key = data.key;
        this.grossRevenue = data.grossRevenue;
        this.platformFee = data.platformFee;
        this.trainerPayout = data.trainerPayout;
    }
}

export class AdminRevenueEarningsResponseDto {
    period: string;
    data: RevenueDataPointDto[];
    totalGrossRevenue: number;
    totalPlatformFee: number;
    totalTrainerPayout: number;
    weekStartDate?: string;
    weekEndDate?: string;
    year?: number;

    constructor(data: {
        period: string;
        data: RevenueDataPointDto[];
        totalGrossRevenue: number;
        totalPlatformFee: number;
        totalTrainerPayout: number;
        weekStartDate?: string;
        weekEndDate?: string;
        year?: number;
    }) {
        Object.assign(this, data);
    }
}

export class AdminTrainerRevenueItemDto {
    trainerUserId: string;
    trainerName: string | null;
    profileImageUrl: string | null;
    totalGrossRevenue: string;
    totalPlatformFee: string;
    totalTrainerPayout: string;
    totalBookings: number;

    constructor(data: {
        trainerUserId: string;
        trainerName: string | null;
        profileImageUrl: string | null;
        totalGrossRevenue: number;
        totalPlatformFee: number;
        totalTrainerPayout: number;
        totalBookings: number;
    }) {
        this.trainerUserId = data.trainerUserId;
        this.trainerName = data.trainerName;
        this.profileImageUrl = data.profileImageUrl;
        this.totalGrossRevenue = data.totalGrossRevenue.toFixed(2);
        this.totalPlatformFee = data.totalPlatformFee.toFixed(2);
        this.totalTrainerPayout = data.totalTrainerPayout.toFixed(2);
        this.totalBookings = data.totalBookings;
    }
}

export class AdminTrainersRevenueResponseDto {
    items: AdminTrainerRevenueItemDto[];
    total: number;
    limit: number;
    offset: number;

    constructor(data: {
        items: AdminTrainerRevenueItemDto[];
        total: number;
        limit: number;
        offset: number;
    }) {
        Object.assign(this, data);
    }
}
