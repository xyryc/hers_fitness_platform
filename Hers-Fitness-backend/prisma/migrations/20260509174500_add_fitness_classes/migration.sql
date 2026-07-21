CREATE TABLE "fitness_classes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "trainer_user_id" UUID NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "scheduled_at" TIMESTAMPTZ(3) NOT NULL,
    "class_type" VARCHAR(120) NOT NULL,
    "duration_minutes" INTEGER NOT NULL,
    "price_per_member" DECIMAL(10,2) NOT NULL,
    "session_format" VARCHAR(120) NOT NULL,
    "max_members" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "fitness_classes_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_fitness_classes_trainer_user_id" ON "fitness_classes"("trainer_user_id");
CREATE INDEX "idx_fitness_classes_scheduled_at" ON "fitness_classes"("scheduled_at");

ALTER TABLE "fitness_classes"
ADD CONSTRAINT "fitness_classes_trainer_user_id_fkey"
FOREIGN KEY ("trainer_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
