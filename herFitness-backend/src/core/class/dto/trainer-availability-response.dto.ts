import { Expose } from 'class-transformer';

export class TrainerAvailabilitySlotResponseDto {
    @Expose()
    id: string;

    @Expose()
    fitnessClassId: string;

    @Expose()
    className: string;

    @Expose()
    classType: string;

    @Expose()
    sessionPlanType: string;

    @Expose()
    sessionFormat: string;

    @Expose()
    durationMinutes: number;

    @Expose()
    pricePerMember: string;

    @Expose()
    date: string;

    @Expose()
    startTime: string;

    @Expose()
    endTime: string;

    @Expose()
    startAt: Date;

    @Expose()
    endAt: Date;

    @Expose()
    status: string;

    @Expose()
    availabilityStatus: string;

    @Expose()
    bookedCount: number;

    @Expose()
    heldCount: number;

    @Expose()
    capacity: number;

    @Expose()
    spotsRemaining: number;

    constructor(partial: Partial<TrainerAvailabilitySlotResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerAvailabilityDayResponseDto {
    @Expose()
    date: string;

    @Expose()
    day: number;

    @Expose()
    status: string;

    @Expose()
    isAvailable: boolean;

    @Expose()
    totalSlotCount: number;

    @Expose()
    availableSlotCount: number;

    @Expose()
    bookedSlotCount: number;

    @Expose()
    heldSlotCount: number;

    @Expose()
    blockedSlotCount: number;

    @Expose()
    slots: TrainerAvailabilitySlotResponseDto[];

    constructor(partial: Partial<TrainerAvailabilityDayResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerAvailabilityCalendarResponseDto {
    @Expose()
    trainerUserId: string;

    @Expose()
    month: string;

    @Expose()
    startDate: string;

    @Expose()
    endDate: string;

    @Expose()
    days: TrainerAvailabilityDayResponseDto[];

    constructor(partial: Partial<TrainerAvailabilityCalendarResponseDto>) {
        Object.assign(this, partial);
    }
}
