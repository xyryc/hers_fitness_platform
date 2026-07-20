ALTER TABLE "trainer_profiles"
ADD COLUMN "stripe_connect_account_id" VARCHAR(255),
ADD COLUMN "stripe_connect_onboarding_complete" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "stripe_charges_enabled" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "stripe_payouts_enabled" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "stripe_details_submitted" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "stripe_connect_updated_at" TIMESTAMPTZ(3);

CREATE UNIQUE INDEX "trainer_profiles_stripe_connect_account_id_key"
ON "trainer_profiles"("stripe_connect_account_id");
