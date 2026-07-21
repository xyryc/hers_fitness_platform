import { Expose } from 'class-transformer';
import { BookingResponseDto } from './booking-response.dto';

export class TrainerScheduleActionsResponseDto {
    @Expose()
    canCheckIn: boolean;

    @Expose()
    canReschedule: boolean;

    @Expose()
    canAcceptReschedule: boolean;

    @Expose()
    canMarkComplete: boolean;

    @Expose()
    label: string;

    constructor(partial: Partial<TrainerScheduleActionsResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerScheduleItemResponseDto {
    @Expose()
    booking: BookingResponseDto;

    @Expose()
    actions: TrainerScheduleActionsResponseDto;

    constructor(partial: Partial<TrainerScheduleItemResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerScheduleDayResponseDto {
    @Expose()
    date: string;

    @Expose()
    totalCount: number;

    @Expose()
    completedCount: number;

    @Expose()
    upcomingCount: number;

    @Expose()
    items: TrainerScheduleItemResponseDto[];

    constructor(partial: Partial<TrainerScheduleDayResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerScheduleResponseDto {
    @Expose()
    startDate: string;

    @Expose()
    endDate: string;

    @Expose()
    days: TrainerScheduleDayResponseDto[];

    constructor(partial: Partial<TrainerScheduleResponseDto>) {
        Object.assign(this, partial);
    }
}
