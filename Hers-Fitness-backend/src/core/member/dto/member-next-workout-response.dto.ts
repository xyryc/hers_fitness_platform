import { Expose } from 'class-transformer';

export class MemberWorkoutActionsResponseDto {
    @Expose()
    canCheckIn!: boolean;

    @Expose()
    canReschedule!: boolean;

    @Expose()
    canAcceptReschedule!: boolean;

    @Expose()
    canMarkComplete!: boolean;

    @Expose()
    label!: string;

    constructor(partial: Partial<MemberWorkoutActionsResponseDto>) {
        Object.assign(this, partial);
    }
}

export class MemberNextWorkoutClassResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string;

    @Expose()
    classType: string;

    @Expose()
    sessionPlanType: string;

    @Expose()
    durationMinutes: number;

    @Expose()
    sessionFormat: string;

    constructor(partial: Partial<MemberNextWorkoutClassResponseDto>) {
        Object.assign(this, partial);
    }
}

export class MemberNextWorkoutTrainerResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string | null;

    @Expose()
    profileImageUrl: string | null;

    @Expose()
    phoneNumber: string | null;

    @Expose()
    classesTaught: string | null;

    @Expose()
    averageRating: number | null;

    @Expose()
    reviewCount: number;

    @Expose()
    distanceMeters: number | null;

    @Expose()
    locationLabel: string | null;

    constructor(partial: Partial<MemberNextWorkoutTrainerResponseDto>) {
        Object.assign(this, partial);
    }
}

export class MemberNextWorkoutLocationTimeResponseDto {
    @Expose()
    location: string | null;

    @Expose()
    scheduledDate: string;

    @Expose()
    startTime: string;

    @Expose()
    endTime: string;

    @Expose()
    startAt: Date;

    @Expose()
    endAt: Date;

    constructor(partial: Partial<MemberNextWorkoutLocationTimeResponseDto>) {
        Object.assign(this, partial);
    }
}

export class MemberNextWorkoutResponseDto {
    @Expose()
    bookingId: string;

    @Expose()
    fitnessClassId: string;

    @Expose()
    availabilitySlotId: string;

    @Expose()
    bookingStatus: string;

    @Expose()
    paymentStatus: string;

    @Expose()
    class: MemberNextWorkoutClassResponseDto;

    @Expose()
    trainer: MemberNextWorkoutTrainerResponseDto;

    @Expose()
    locationTime: MemberNextWorkoutLocationTimeResponseDto;

    @Expose()
    totalAmount: string;

    @Expose()
    confirmedAt: Date | null;

    @Expose()
    rescheduleRequestedByUserId: string | null;

    @Expose()
    rescheduleRequestedAt: Date | null;

    @Expose()
    proposedScheduledDate: string | null;

    @Expose()
    proposedStartTime: string | null;

    @Expose()
    proposedEndTime: string | null;

    @Expose()
    memberRescheduleAcceptedAt: Date | null;

    @Expose()
    trainerRescheduleAcceptedAt: Date | null;

    @Expose()
    rescheduledAt: Date | null;

    @Expose()
    memberCheckedInAt!: Date | null;

    @Expose()
    trainerCheckedInAt!: Date | null;

    @Expose()
    memberCompletedAt: Date | null;

    @Expose()
    trainerCompletedAt: Date | null;

    @Expose()
    completedAt: Date | null;

    @Expose()
    actions!: MemberWorkoutActionsResponseDto;

    constructor(partial: Partial<MemberNextWorkoutResponseDto>) {
        Object.assign(this, partial);
    }
}
