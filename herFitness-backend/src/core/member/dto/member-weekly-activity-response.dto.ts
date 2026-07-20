import { Expose } from 'class-transformer';

export class MemberWeeklyActivityItemDto {
    @Expose()
    date: string;

    @Expose()
    dayOfWeek: number;

    @Expose()
    label: string;

    @Expose()
    shortLabel: string;

    @Expose()
    completedSessions: number;

    @Expose()
    activityPercentage: number;

    constructor(partial: Partial<MemberWeeklyActivityItemDto>) {
        Object.assign(this, partial);
    }
}

export class MemberWeeklyActivityResponseDto {
    @Expose()
    weekStart: string;

    @Expose()
    weekEnd: string;

    @Expose()
    totalCompletedSessions: number;

    @Expose()
    maxDailyCompletedSessions: number;

    @Expose()
    days: MemberWeeklyActivityItemDto[];

    constructor(partial: Partial<MemberWeeklyActivityResponseDto>) {
        Object.assign(this, partial);
    }
}
