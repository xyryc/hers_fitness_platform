CREATE TYPE "FitnessClassStatus" AS ENUM ('ACTIVE', 'CANCELLED', 'COMPLETED');

ALTER TABLE "fitness_classes"
ADD COLUMN "status" "FitnessClassStatus" NOT NULL DEFAULT 'ACTIVE';
