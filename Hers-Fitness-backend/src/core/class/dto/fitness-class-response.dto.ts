import { Expose } from 'class-transformer';

export class ClassJoinedMemberResponseDto {
    @Expose() bookingId!: string;
    @Expose() memberUserId!: string;
    @Expose() name!: string | null;
    @Expose() profileImageUrl!: string | null;
    @Expose() bookingStatus!: string;
    @Expose() scheduledDate!: string;
    @Expose() startTime!: string;
    @Expose() endTime!: string;
    @Expose() memberCheckedInAt!: Date | null;
    @Expose() memberCompletedAt!: Date | null;
    @Expose() completedAt!: Date | null;

    constructor(partial: Partial<ClassJoinedMemberResponseDto>) {
        Object.assign(this, partial);
    }
}

export class FitnessClassAvailabilitySlotResponseDto {
    @Expose()
    id: string;

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
    isRescheduleProposal: boolean;

    @Expose()
    rescheduleStatus: string | null;

    @Expose()
    bookedCount: number;

    @Expose()
    heldCount: number;

    @Expose()
    capacity: number | null;

    @Expose()
    spotsRemaining: number | null;

    constructor(partial: Partial<FitnessClassAvailabilitySlotResponseDto>) {
        Object.assign(this, partial);
    }
}

export class FitnessClassTrainerResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string | null;

    @Expose()
    imageUrl: string | null;

    constructor(partial: Partial<FitnessClassTrainerResponseDto>) {
        Object.assign(this, partial);
    }
}

export class FitnessClassResponseDto {
    @Expose()
    id: string;

    @Expose()
    trainerUserId: string;

    @Expose()
    name: string;

    @Expose()
    scheduledAt: Date | null;

    @Expose()
    classType: string;

    @Expose()
    sessionPlanType: string;

    @Expose()
    durationMinutes: number;

    @Expose()
    pricePerMember: string;

    @Expose()
    sessionFormat: string;

    @Expose()
    capacity: number | null;

    @Expose()
    status: string;

    @Expose()
    bookedMemberCount: number;

    @Expose()
    joinedMembers: ClassJoinedMemberResponseDto[];

    @Expose()
    rescheduleStatus: string | null;

    @Expose()
    rescheduleRequestedByUserId: string | null;

    @Expose()
    rescheduleRequestedAt: Date | null;

    @Expose()
    rescheduleNote: string | null;

    @Expose()
    imageUrl: string | null;

    @Expose()
    trainerImageUrl: string | null;

    @Expose()
    trainer: FitnessClassTrainerResponseDto;

    @Expose()
    availableSlots: FitnessClassAvailabilitySlotResponseDto[];

    @Expose()
    bookedSlots: FitnessClassAvailabilitySlotResponseDto[];

    @Expose()
    proposedRescheduleSlots: FitnessClassAvailabilitySlotResponseDto[];

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    constructor(partial: Partial<FitnessClassResponseDto>) {
        Object.assign(this, partial);
    }
}
