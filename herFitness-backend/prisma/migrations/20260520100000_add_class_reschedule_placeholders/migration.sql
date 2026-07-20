ALTER TABLE "fitness_classes"
ADD COLUMN "reschedule_status" VARCHAR(50),
ADD COLUMN "reschedule_requested_by_user_id" UUID,
ADD COLUMN "reschedule_requested_at" TIMESTAMPTZ(3),
ADD COLUMN "reschedule_note" TEXT;

ALTER TABLE "fitness_class_availability_slots"
ADD COLUMN "is_reschedule_proposal" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "reschedule_status" VARCHAR(50);

CREATE INDEX "idx_fitness_classes_reschedule_status"
ON "fitness_classes"("reschedule_status");

CREATE INDEX "idx_fitness_class_availability_slots_reschedule"
ON "fitness_class_availability_slots"("fitness_class_id", "is_reschedule_proposal", "reschedule_status");
