import { Expose } from 'class-transformer';

export class TrainerDashboardStatsResponseDto {
    @Expose() totalClasses!: number;
    @Expose() totalAttendance!: number;
    @Expose() totalRevenue!: number;
    @Expose() avgClassSize!: number;
    @Expose() overallRating!: number | null;

    constructor(partial: Partial<TrainerDashboardStatsResponseDto>) {
        Object.assign(this, partial);
    }
}
