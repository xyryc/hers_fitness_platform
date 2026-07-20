import { Expose, Type } from 'class-transformer';

export class EarningsDataPointDto {
    @Expose() label: string;      // 'Mon', 'Jan', '2025', etc.
    @Expose() key: string;        // '2026-05-19', '2026-01', '2026' — for frontend to use as chart key
    @Expose() earnings: number;

    constructor(partial: Partial<EarningsDataPointDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerEarningsResponseDto {
    @Expose() period: string;          // 'weekly' | 'monthly' | 'yearly'
    @Expose() totalEarnings: number;   // sum across all data points

    @Expose()
    @Type(() => EarningsDataPointDto)
    data: EarningsDataPointDto[];

    // Context fields — which time window is shown
    @Expose() year?: number;           // for monthly
    @Expose() weekStartDate?: string;  // for weekly (YYYY-MM-DD)
    @Expose() weekEndDate?: string;    // for weekly (YYYY-MM-DD)

    constructor(partial: Partial<TrainerEarningsResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerTopClassItemDto {
    @Expose() id: string;
    @Expose() name: string;
    @Expose() classType: string;
    @Expose() sessionFormat: string;
    @Expose() bookingCount: number;
    @Expose() totalRevenue: number;

    constructor(partial: Partial<TrainerTopClassItemDto>) {
        Object.assign(this, partial);
    }
}
