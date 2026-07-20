export interface FitnessClassJoinedMember {
    bookingId: string;
    memberUserId: string;
    name: string | null;
    profileImageUrl: string | null;
    bookingStatus: string;
    scheduledDate: string;
    startTime: string;
    endTime: string;
    memberCheckedInAt: Date | null;
    memberCompletedAt: Date | null;
    completedAt: Date | null;
}

export interface FitnessClassEntity {
    id: string;
    trainerUserId: string;
    name: string;
    scheduledAt: Date | null;
    classType: string;
    sessionPlanType: string;
    durationMinutes: number;
    pricePerMember: string;
    sessionFormat: string;
    capacity?: number | null;
    status: string;
    bookedMemberCount: number;
    joinedMembers: FitnessClassJoinedMember[];
    rescheduleStatus?: string | null;
    rescheduleRequestedByUserId?: string | null;
    rescheduleRequestedAt?: Date | null;
    rescheduleNote?: string | null;
    trainerImageUrl?: string | null;
    trainer: {
        id: string;
        name: string | null;
        imageUrl: string | null;
        timezone?: string | null;
    };
    availableSlots: {
        id: string;
        date: string;
        startTime: string;
        endTime: string;
        startAt: Date;
        endAt: Date;
        status: string;
        availabilityStatus: string;
        isRescheduleProposal: boolean;
        rescheduleStatus: string | null;
        bookedCount: number;
        heldCount: number;
        capacity: number | null;
        spotsRemaining: number | null;
    }[];
    bookedSlots: {
        id: string;
        date: string;
        startTime: string;
        endTime: string;
        startAt: Date;
        endAt: Date;
        status: string;
        availabilityStatus: string;
        isRescheduleProposal: boolean;
        rescheduleStatus: string | null;
        bookedCount: number;
        heldCount: number;
        capacity: number | null;
        spotsRemaining: number | null;
    }[];
    proposedRescheduleSlots: {
        id: string;
        date: string;
        startTime: string;
        endTime: string;
        startAt: Date;
        endAt: Date;
        status: string;
        availabilityStatus: string;
        isRescheduleProposal: boolean;
        rescheduleStatus: string | null;
        bookedCount: number;
        heldCount: number;
        capacity: number | null;
        spotsRemaining: number | null;
    }[];
    createdAt: Date;
    updatedAt?: Date | null;
}
