-- CreateTable
CREATE TABLE "user_verifications" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "id_card_type" VARCHAR(100) NOT NULL,
    "id_card_number" VARCHAR(100) NOT NULL,
    "id_card_front_image_url" VARCHAR(2048) NOT NULL,
    "id_card_back_image_url" VARCHAR(2048) NOT NULL,
    "verification_status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "reviewed_by_user_id" UUID,
    "reviewed_at" TIMESTAMPTZ(3),
    "rejection_reason" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "user_verifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trainer_profiles" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "bio" TEXT NOT NULL,
    "classes_taught" TEXT NOT NULL,
    "instructor_experience" VARCHAR(200) NOT NULL,
    "certifications" TEXT NOT NULL,
    "class_delivery_mode" "ClassDeliveryMode" NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "trainer_profiles_pkey" PRIMARY KEY ("id")
);

-- Backfill shared verification records from users
INSERT INTO "user_verifications" (
    "user_id",
    "id_card_type",
    "id_card_number",
    "id_card_front_image_url",
    "id_card_back_image_url",
    "verification_status",
    "created_at",
    "updated_at"
)
SELECT
    "id",
    "id_card_type",
    "id_card_number",
    "id_card_front_image_url",
    "id_card_back_image_url",
    "verification_status",
    "created_at",
    "updated_at"
FROM "users"
WHERE "id_card_number" IS NOT NULL;

-- Backfill trainer-only profile data from users
INSERT INTO "trainer_profiles" (
    "user_id",
    "bio",
    "classes_taught",
    "instructor_experience",
    "certifications",
    "class_delivery_mode",
    "created_at",
    "updated_at"
)
SELECT
    "id",
    COALESCE("bio", ''),
    "classes_taught",
    "instructor_experience",
    "certifications",
    "class_delivery_mode",
    "created_at",
    "updated_at"
FROM "users"
WHERE "classes_taught" IS NOT NULL
  AND "instructor_experience" IS NOT NULL
  AND "certifications" IS NOT NULL
  AND "class_delivery_mode" IS NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "user_verifications_user_id_key" ON "user_verifications"("user_id");
CREATE UNIQUE INDEX "user_verifications_id_card_number_key" ON "user_verifications"("id_card_number");
CREATE INDEX "idx_user_verifications_status" ON "user_verifications"("verification_status");
CREATE UNIQUE INDEX "trainer_profiles_user_id_key" ON "trainer_profiles"("user_id");

-- AddForeignKey
ALTER TABLE "user_verifications"
ADD CONSTRAINT "user_verifications_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_verifications"
ADD CONSTRAINT "user_verifications_reviewed_by_user_id_fkey"
FOREIGN KEY ("reviewed_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "trainer_profiles"
ADD CONSTRAINT "trainer_profiles_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Drop old unique index before dropping column
DROP INDEX IF EXISTS "users_id_card_number_key";

-- AlterTable
ALTER TABLE "users"
DROP COLUMN "id_card_type",
DROP COLUMN "id_card_number",
DROP COLUMN "id_card_front_image_url",
DROP COLUMN "id_card_back_image_url",
DROP COLUMN "verification_status",
DROP COLUMN "classes_taught",
DROP COLUMN "instructor_experience",
DROP COLUMN "certifications",
DROP COLUMN "class_delivery_mode",
DROP COLUMN "bio";
