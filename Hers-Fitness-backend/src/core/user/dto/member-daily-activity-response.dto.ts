import { Expose } from 'class-transformer';

export class MemberDailyActivityItemDto {
    @Expose()
    date: string; // "YYYY-MM-DD"

    @Expose()
    day: number; // 1–31

    @Expose()
    completedSessions: number;

    @Expose()
    activityPercentage: number;

    constructor(partial: Partial<MemberDailyActivityItemDto>) {
        Object.assign(this, partial);
    }
}

export class MemberDailyActivityResponseDto {
    @Expose()
    month: number;

    @Expose()
    year: number;

    @Expose()
    totalCompletedSessions: number;

    @Expose()
    days: MemberDailyActivityItemDto[];

    constructor(partial: Partial<MemberDailyActivityResponseDto>) {
        Object.assign(this, partial);
    }
}
