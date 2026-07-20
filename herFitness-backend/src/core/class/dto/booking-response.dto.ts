import { Expose } from 'class-transformer';

export class BookingClassResponseDto {
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

    @Expose()
    status: string;

    constructor(partial: Partial<BookingClassResponseDto>) {
        Object.assign(this, partial);
    }
}

export class BookingTrainerResponseDto {
    @Expose()
    id: string;

    @Expose()
    name: string | null;

    @Expose()
    profileImageUrl: string | null;

    @Expose()
    phoneNumber: string | null;

    constructor(partial: Partial<BookingTrainerResponseDto>) {
        Object.assign(this, partial);
    }
}

export class BookingResponseDto {
    @Expose()
    id: string;

    @Expose()
    memberUserId: string;

    @Expose()
    trainerUserId: string;

    @Expose()
    fitnessClassId: string;

    @Expose()
    availabilitySlotId: string;

    @Expose()
    bookingPaymentId: string | null;

    @Expose()
    fullName: string;

    @Expose()
    email: string;

    @Expose()
    phoneNumber: string;

    @Expose()
    location: string;

    @Expose()
    comment: string | null;

    @Expose()
    scheduledDate: string;

    @Expose()
    startTime: string;

    @Expose()
    endTime: string;

    @Expose()
    startAt: Date | null;

    @Expose()
    endAt: Date | null;

    @Expose()
    totalAmount: string;

    @Expose()
    bookingStatus: string;

    @Expose()
    paymentStatus: string;

    @Expose()
    reservedUntil: Date | null;

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
    memberCheckedInAt: Date | null;

    @Expose()
    trainerCheckedInAt: Date | null;

    @Expose()
    memberCompletedAt: Date | null;

    @Expose()
    trainerCompletedAt: Date | null;

    @Expose()
    completedAt: Date | null;

    @Expose()
    class: BookingClassResponseDto;

    @Expose()
    trainer: BookingTrainerResponseDto;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    constructor(partial: Partial<BookingResponseDto>) {
        Object.assign(this, partial);
    }
}

export class BookingPaymentSummaryResponseDto {
    @Expose()
    id: string;

    @Expose()
    subtotalAmount: string;

    @Expose()
    discountAmount: string;

    @Expose()
    taxAmount: string;

    @Expose()
    totalAmount: string;

    @Expose()
    currency: string;

    @Expose()
    couponCode: string | null;

    @Expose()
    couponPlaceholder: boolean;

    @Expose()
    status: string;

    @Expose()
    expiresAt: Date;

    constructor(partial: Partial<BookingPaymentSummaryResponseDto>) {
        Object.assign(this, partial);
    }
}

export class BookingCheckoutResponseDto {
    @Expose()
    bookings: BookingResponseDto[];

    @Expose()
    payment: BookingPaymentSummaryResponseDto;

    @Expose()
    reservedUntil: Date;

    constructor(partial: Partial<BookingCheckoutResponseDto>) {
        Object.assign(this, partial);
    }
}

export class StripePaymentIntentResponseDto {
    @Expose()
    paymentId: string;

    @Expose()
    paymentIntentId: string;

    @Expose()
    clientSecret: string | null;

    @Expose()
    publishableKey: string;

    @Expose()
    amount: number;

    @Expose()
    currency: string;

    constructor(partial: Partial<StripePaymentIntentResponseDto>) {
        Object.assign(this, partial);
    }
}
