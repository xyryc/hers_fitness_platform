-- DropForeignKey
ALTER TABLE "bookings" DROP CONSTRAINT "bookings_reschedule_requested_by_user_id_fkey";

-- DropIndex
DROP INDEX "idx_bookings_completed_at";

-- DropIndex
DROP INDEX "idx_bookings_proposed_schedule";

-- DropIndex
DROP INDEX "idx_bookings_reschedule_requested_by_user_id";

-- RenameIndex
ALTER INDEX "uq_trainer_reviews_member_trainer" RENAME TO "trainer_reviews_member_user_id_trainer_user_id_key";
