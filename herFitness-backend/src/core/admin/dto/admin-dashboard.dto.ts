import { IsEnum, IsNumber, IsOptional, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';

// ─── Shared helpers ───────────────────────────────────────────────────────────

export class MetricWithTrendDto {
    value: number;
    trend?: number;

    constructor(value: number, trend?: number) {
        this.value = Number(value.toFixed(2));
        if (trend !== undefined) this.trend = trend;
    }
}

export class MetricIntDto {
    value: number;
    trend?: number;

    constructor(value: number, trend?: number) {
        this.value = value;
        if (trend !== undefined) this.trend = trend;
    }
}

// ─── 1. Dashboard Summary ─────────────────────────────────────────────────────

export class DashboardSummaryResponseDto {
    totalRevenue: MetricWithTrendDto;
    platformCommission: MetricWithTrendDto;
    pendingVerifications: MetricIntDto;
    totalMembers: MetricIntDto;
    activeMembers: MetricIntDto;
    trainers: MetricIntDto;
    bookingsThisWeek: MetricIntDto;

    constructor(data: {
        totalRevenue: number;
        totalRevenueTrend: number;
        platformCommission: number;
        platformCommissionTrend: number;
        pendingVerifications: number;
        totalMembers: number;
        totalMembersTrend: number;
        activeMembers: number;
        activeMembersTrend: number;
        trainers: number;
        trainersTrend: number;
        bookingsThisWeek: number;
        bookingsThisWeekTrend: number;
    }) {
        this.totalRevenue = new MetricWithTrendDto(data.totalRevenue, data.totalRevenueTrend);
        this.platformCommission = new MetricWithTrendDto(data.platformCommission, data.platformCommissionTrend);
        this.pendingVerifications = new MetricIntDto(data.pendingVerifications);
        this.totalMembers = new MetricIntDto(data.totalMembers, data.totalMembersTrend);
        this.activeMembers = new MetricIntDto(data.activeMembers, data.activeMembersTrend);
        this.trainers = new MetricIntDto(data.trainers, data.trainersTrend);
        this.bookingsThisWeek = new MetricIntDto(data.bookingsThisWeek, data.bookingsThisWeekTrend);
    }
}

// ─── 2. Chart Data ────────────────────────────────────────────────────────────

export enum ChartRange {
    SEVEN_DAYS = '7d',
    THIRTY_DAYS = '30d',
}

export class DashboardChartQueryDto {
    @ApiPropertyOptional({ enum: ChartRange, default: ChartRange.SEVEN_DAYS, description: '7d = last 7 days, 30d = last 30 days' })
    @IsEnum(ChartRange)
    @IsOptional()
    range?: ChartRange = ChartRange.SEVEN_DAYS;
}

export class ChartDataPointDto {
    /** Human-readable day label e.g. "Mon", "25 Apr" */
    label: string;
    /** Total revenue from PAID bookings on this day */
    revenue: number;
    /** Combined count of new trainers + new members on this day */
    hires: number;

    constructor(data: { label: string; revenue: number; hires: number }) {
        this.label = data.label;
        this.revenue = Number(data.revenue.toFixed(2));
        this.hires = data.hires;
    }
}

// ─── 3. Recent Activity ───────────────────────────────────────────────────────

export class ActivitiesQueryDto {
    @ApiPropertyOptional({ default: 10, minimum: 1, description: 'Max number of activity events to return' })
    @Type(() => Number)
    @IsNumber()
    @Min(1)
    @IsOptional()
    limit?: number = 10;
}

export type ActivityType = 'NEW_MEMBER' | 'PENDING_APPROVAL';

export class ActivityItemDto {
    type: ActivityType;
    title: string;
    person: string;
    occurredAt: string; // ISO 8601

    constructor(data: { type: ActivityType; title: string; person: string; occurredAt: Date }) {
        this.type = data.type;
        this.title = data.title;
        this.person = data.person;
        this.occurredAt = data.occurredAt.toISOString();
    }
}
