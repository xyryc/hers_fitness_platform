ALTER TABLE "bookings"
ADD COLUMN "reschedule_requested_by_user_id" UUID,
ADD COLUMN "reschedule_requested_at" TIMESTAMPTZ(3),
ADD COLUMN "proposed_scheduled_date" VARCHAR(10),
ADD COLUMN "proposed_start_time" VARCHAR(5),
ADD COLUMN "proposed_end_time" VARCHAR(5),
ADD COLUMN "member_reschedule_accepted_at" TIMESTAMPTZ(3),
ADD COLUMN "trainer_reschedule_accepted_at" TIMESTAMPTZ(3),
ADD COLUMN "rescheduled_at" TIMESTAMPTZ(3);

CREATE INDEX "idx_bookings_reschedule_requested_by_user_id"
ON "bookings"("reschedule_requested_by_user_id");

CREATE INDEX "idx_bookings_proposed_schedule"
ON "bookings"("proposed_scheduled_date", "proposed_start_time");

ALTER TABLE "bookings"
ADD CONSTRAINT "bookings_reschedule_requested_by_user_id_fkey"
FOREIGN KEY ("reschedule_requested_by_user_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
