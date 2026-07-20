import { Expose } from 'class-transformer';

export class MemberYearlyActivityItemDto {
    @Expose() year!: number;
    @Expose() completedSessions!: number;
    @Expose() activityPercentage!: number;

    constructor(partial: Partial<MemberYearlyActivityItemDto>) {
        Object.assign(this, partial);
    }
}

export class MemberYearlyActivityResponseDto {
    @Expose() totalCompletedSessions!: number;
    @Expose() maxYearlyCompletedSessions!: number;
    @Expose() years!: MemberYearlyActivityItemDto[];

    constructor(partial: Partial<MemberYearlyActivityResponseDto>) {
        Object.assign(this, partial);
    }
}
