-- AddAdminCommissionConfig and commission fields to BookingPayment

-- 1. Add commission columns to booking_payments
ALTER TABLE "booking_payments"
    ADD COLUMN "commission_rate"       DECIMAL(5,2)  NOT NULL DEFAULT 0,
    ADD COLUMN "platform_fee_amount"   DECIMAL(10,2) NOT NULL DEFAULT 0,
    ADD COLUMN "trainer_payout_amount" DECIMAL(10,2) NOT NULL DEFAULT 0;

-- 2. Backfill existing paid rows: trainer earned the full amount (0% commission historically)
UPDATE "booking_payments"
SET "trainer_payout_amount" = "total_amount"
WHERE "trainer_payout_amount" = 0;

-- 3. Create the singleton admin_commission_config table
CREATE TABLE "admin_commission_config" (
    "id"                UUID          NOT NULL DEFAULT gen_random_uuid(),
    "commission_rate"   DECIMAL(5,2)  NOT NULL DEFAULT 0,
    "updated_by_user_id" UUID,
    "created_at"        TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at"        TIMESTAMPTZ(3),

    CONSTRAINT "admin_commission_config_pkey" PRIMARY KEY ("id")
);

-- 4. FK from admin_commission_config → users (nullable, SET NULL on delete)
ALTER TABLE "admin_commission_config"
    ADD CONSTRAINT "admin_commission_config_updated_by_user_id_fkey"
    FOREIGN KEY ("updated_by_user_id")
    REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 5. Seed the singleton row so GET /admin/commission always returns a result
INSERT INTO "admin_commission_config" ("commission_rate")
VALUES (0)
ON CONFLICT DO NOTHING;
