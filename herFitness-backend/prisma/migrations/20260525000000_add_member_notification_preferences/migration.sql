-- Add member-specific notification preference columns to user_notification_preferences table.
-- Existing columns (new_booking, class_check_in, payment_received) remain and continue to
-- serve as TRAINER-only preferences. The new columns below are MEMBER-only.
-- Shared columns (class_reminder, system_announcements, email_notifications, push_notifications)
-- are already present and apply to both roles.

ALTER TABLE "user_notification_preferences"
    ADD COLUMN IF NOT EXISTS "booking_confirmation" BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS "booking_cancellation" BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS "payment_confirmation"  BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS "trainer_message"       BOOLEAN NOT NULL DEFAULT true;
