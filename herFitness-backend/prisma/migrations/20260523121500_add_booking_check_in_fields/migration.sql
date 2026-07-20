ALTER TABLE "bookings"
ADD COLUMN "member_checked_in_at" TIMESTAMPTZ(3),
ADD COLUMN "trainer_checked_in_at" TIMESTAMPTZ(3);
