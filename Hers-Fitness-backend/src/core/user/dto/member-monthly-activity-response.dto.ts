import { Expose } from 'class-transformer';

export class MemberMonthlyActivityItemDto {
    @Expose()
    month: number;

    @Expose()
    label: string;

    @Expose()
    shortLabel: string;

    @Expose()
    completedSessions: number;

    @Expose()
    activityPercentage: number;

    constructor(partial: Partial<MemberMonthlyActivityItemDto>) {
        Object.assign(this, partial);
    }
}

export class MemberMonthlyActivityResponseDto {
    @Expose()
    year: number;

    @Expose()
    totalCompletedSessions: number;

    @Expose()
    maxMonthlyCompletedSessions: number;

    @Expose()
    months: MemberMonthlyActivityItemDto[];

    constructor(partial: Partial<MemberMonthlyActivityResponseDto>) {
        Object.assign(this, partial);
    }
}
