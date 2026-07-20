-- CreateEnum
CREATE TYPE "ClassDeliveryMode" AS ENUM ('ONLINE', 'OFFLINE', 'BOTH');

-- AlterTable
ALTER TABLE "users"
ADD COLUMN "classes_taught" TEXT,
ADD COLUMN "instructor_experience" VARCHAR(200),
ADD COLUMN "certifications" TEXT,
ADD COLUMN "class_delivery_mode" "ClassDeliveryMode";
