-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "users"
ADD COLUMN "state" VARCHAR(200),
ADD COLUMN "location" VARCHAR(500),
ADD COLUMN "id_card_type" VARCHAR(100),
ADD COLUMN "id_card_number" VARCHAR(100),
ADD COLUMN "id_card_front_image_url" VARCHAR(2048),
ADD COLUMN "id_card_back_image_url" VARCHAR(2048),
ADD COLUMN "verification_status" "VerificationStatus" NOT NULL DEFAULT 'PENDING';

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "users_id_card_number_key" ON "users"("id_card_number");

-- Update role names for the project
UPDATE "roles"
SET "name" = 'ADMIN',
    "description" = 'Administrator with full access'
WHERE "name" = 'ADMINISTRATOR';

UPDATE "roles"
SET "name" = 'TRAINER',
    "description" = 'Trainer with operational access'
WHERE "name" = 'TEACHER';

UPDATE "roles"
SET "name" = 'MEMBER',
    "description" = 'Member account pending admin verification on signup'
WHERE "name" = 'STUDENT';
