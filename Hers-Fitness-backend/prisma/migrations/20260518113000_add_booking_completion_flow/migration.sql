ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'COMPLETED';

ALTER TABLE "bookings"
ADD COLUMN "member_completed_at" TIMESTAMPTZ(3),
ADD COLUMN "trainer_completed_at" TIMESTAMPTZ(3),
ADD COLUMN "completed_at" TIMESTAMPTZ(3);

CREATE INDEX "idx_bookings_completed_at" ON "bookings"("completed_at");
