CREATE TYPE "FitnessSessionPlanType" AS ENUM ('SINGLE_SESSION', 'MONTHLY_SESSION');

CREATE TYPE "BookingPaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'EXPIRED');

ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'HELD';
ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'EXPIRED';
ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'PAYMENT_FAILED';
ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'RESCHEDULE_REQUESTED';
ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'RESCHEDULED';

ALTER TYPE "PaymentStatus" ADD VALUE IF NOT EXISTS 'EXPIRED';

ALTER TABLE "fitness_classes"
ADD COLUMN "session_plan_type" "FitnessSessionPlanType" NOT NULL DEFAULT 'SINGLE_SESSION';

CREATE TABLE "booking_payments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "member_user_id" UUID NOT NULL,
    "fitness_class_id" UUID NOT NULL,
    "subtotal_amount" DECIMAL(10,2) NOT NULL,
    "discount_amount" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "tax_amount" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "total_amount" DECIMAL(10,2) NOT NULL,
    "currency" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "coupon_code" VARCHAR(100),
    "payment_method" VARCHAR(100),
    "provider" VARCHAR(100),
    "provider_session_id" VARCHAR(255),
    "status" "BookingPaymentStatus" NOT NULL DEFAULT 'PENDING',
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "paid_at" TIMESTAMPTZ(3),
    "failed_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),
    CONSTRAINT "booking_payments_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "bookings"
ADD COLUMN "booking_payment_id" UUID,
ADD COLUMN "reserved_until" TIMESTAMPTZ(3),
ADD COLUMN "confirmed_at" TIMESTAMPTZ(3),
ADD COLUMN "cancelled_at" TIMESTAMPTZ(3),
ADD COLUMN "expired_at" TIMESTAMPTZ(3),
ADD COLUMN "reminder_enabled" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "reminder_at" TIMESTAMPTZ(3);

ALTER TABLE "bookings"
ALTER COLUMN "booking_status" SET DEFAULT 'HELD';

CREATE INDEX "idx_booking_payments_member_user_id" ON "booking_payments"("member_user_id");
CREATE INDEX "idx_booking_payments_fitness_class_id" ON "booking_payments"("fitness_class_id");
CREATE INDEX "idx_booking_payments_status_expires_at" ON "booking_payments"("status", "expires_at");
CREATE INDEX "idx_bookings_booking_payment_id" ON "bookings"("booking_payment_id");
CREATE INDEX "idx_bookings_status_reserved_until" ON "bookings"("booking_status", "reserved_until");

ALTER TABLE "booking_payments"
ADD CONSTRAINT "booking_payments_member_user_id_fkey"
FOREIGN KEY ("member_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "booking_payments"
ADD CONSTRAINT "booking_payments_fitness_class_id_fkey"
FOREIGN KEY ("fitness_class_id") REFERENCES "fitness_classes"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "bookings"
ADD CONSTRAINT "bookings_booking_payment_id_fkey"
FOREIGN KEY ("booking_payment_id") REFERENCES "booking_payments"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
