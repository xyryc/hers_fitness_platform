-- CreateEnum
CREATE TYPE "AvailabilitySlotStatus" AS ENUM ('AVAILABLE', 'BOOKED', 'BLOCKED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('CONFIRMED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED');

-- AlterTable
ALTER TABLE "fitness_classes"
ALTER COLUMN "scheduled_at" DROP NOT NULL;

-- CreateTable
CREATE TABLE "fitness_class_availability_slots" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "fitness_class_id" UUID NOT NULL,
    "trainer_user_id" UUID NOT NULL,
    "date" VARCHAR(10) NOT NULL,
    "start_time" VARCHAR(5) NOT NULL,
    "end_time" VARCHAR(5) NOT NULL,
    "start_at" TIMESTAMPTZ(3) NOT NULL,
    "end_at" TIMESTAMPTZ(3) NOT NULL,
    "status" "AvailabilitySlotStatus" NOT NULL DEFAULT 'AVAILABLE',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "fitness_class_availability_slots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bookings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "member_user_id" UUID NOT NULL,
    "trainer_user_id" UUID NOT NULL,
    "fitness_class_id" UUID NOT NULL,
    "availability_slot_id" UUID NOT NULL,
    "full_name" VARCHAR(200) NOT NULL,
    "email" CITEXT NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "location" VARCHAR(500) NOT NULL,
    "comment" TEXT,
    "scheduled_date" VARCHAR(10) NOT NULL,
    "start_time" VARCHAR(5) NOT NULL,
    "end_time" VARCHAR(5) NOT NULL,
    "total_amount" DECIMAL(10,2) NOT NULL,
    "booking_status" "BookingStatus" NOT NULL DEFAULT 'CONFIRMED',
    "payment_status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_fitness_class_availability_slots_class_id" ON "fitness_class_availability_slots"("fitness_class_id");

-- CreateIndex
CREATE INDEX "idx_fitness_class_availability_slots_trainer_id" ON "fitness_class_availability_slots"("trainer_user_id");

-- CreateIndex
CREATE INDEX "idx_fitness_class_availability_slots_status" ON "fitness_class_availability_slots"("status");

-- CreateIndex
CREATE INDEX "idx_fitness_class_availability_slots_start_at" ON "fitness_class_availability_slots"("start_at");

-- CreateIndex
CREATE INDEX "idx_bookings_member_user_id" ON "bookings"("member_user_id");

-- CreateIndex
CREATE INDEX "idx_bookings_trainer_user_id" ON "bookings"("trainer_user_id");

-- CreateIndex
CREATE INDEX "idx_bookings_fitness_class_id" ON "bookings"("fitness_class_id");

-- CreateIndex
CREATE INDEX "idx_bookings_availability_slot_id" ON "bookings"("availability_slot_id");

-- AddForeignKey
ALTER TABLE "fitness_class_availability_slots"
ADD CONSTRAINT "fitness_class_availability_slots_fitness_class_id_fkey"
FOREIGN KEY ("fitness_class_id") REFERENCES "fitness_classes"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fitness_class_availability_slots"
ADD CONSTRAINT "fitness_class_availability_slots_trainer_user_id_fkey"
FOREIGN KEY ("trainer_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings"
ADD CONSTRAINT "bookings_member_user_id_fkey"
FOREIGN KEY ("member_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings"
ADD CONSTRAINT "bookings_trainer_user_id_fkey"
FOREIGN KEY ("trainer_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings"
ADD CONSTRAINT "bookings_fitness_class_id_fkey"
FOREIGN KEY ("fitness_class_id") REFERENCES "fitness_classes"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings"
ADD CONSTRAINT "bookings_availability_slot_id_fkey"
FOREIGN KEY ("availability_slot_id") REFERENCES "fitness_class_availability_slots"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
