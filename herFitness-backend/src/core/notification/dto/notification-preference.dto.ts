import { Expose } from 'class-transformer';

export class NotificationPreferenceResponseDto {
    /** Discriminator — tells the frontend which set of toggles to render */
    @Expose() role!: 'MEMBER' | 'TRAINER';

    // ─── Member-only ──────────────────────────────────────────────────────────────
    /** When you successfully book a class */
    @Expose() bookingConfirmation?: boolean;
    /** When a booking is cancelled by you or the trainer */
    @Expose() bookingCancellation?: boolean;
    /** When a payment is processed for your booking */
    @Expose() paymentConfirmation?: boolean;
    /** When your trainer sends you a message */
    @Expose() trainerMessage?: boolean;

    // ─── Trainer-only ─────────────────────────────────────────────────────────────
    /** When a member books one of your classes */
    @Expose() newBooking?: boolean;
    /** When a member checks into your class */
    @Expose() classCheckIn?: boolean;
    /** When you receive a booking payment */
    @Expose() paymentReceived?: boolean;

    // ─── Shared (both roles) ──────────────────────────────────────────────────────
    /** Reminder before your upcoming class starts */
    @Expose() classReminder!: boolean;
    /** News and feature updates from Hers Fitness */
    @Expose() systemAnnouncements!: boolean;
    /** Receive push notifications on this device */
    @Expose() pushNotifications!: boolean;
    /** Receive summaries and updates by email */
    @Expose() emailNotifications!: boolean;

    constructor(partial: Partial<NotificationPreferenceResponseDto>) {
        Object.assign(this, partial);
    }
}

export const DEFAULT_MEMBER_PREFERENCES = {
    bookingConfirmation: true,
    bookingCancellation: true,
    paymentConfirmation: true,
    trainerMessage: true,
    classReminder: true,
    systemAnnouncements: false,
    pushNotifications: true,
    emailNotifications: true,
};

export const DEFAULT_TRAINER_PREFERENCES = {
    newBooking: true,
    classCheckIn: true,
    paymentReceived: true,
    classReminder: true,
    systemAnnouncements: false,
    pushNotifications: true,
    emailNotifications: true,
};

/** @deprecated Use DEFAULT_MEMBER_PREFERENCES or DEFAULT_TRAINER_PREFERENCES */
export const DEFAULT_NOTIFICATION_PREFERENCES = DEFAULT_TRAINER_PREFERENCES;
