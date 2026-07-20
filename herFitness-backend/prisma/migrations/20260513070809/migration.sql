-- CreateTable
CREATE TABLE "favorite_trainers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "member_user_id" UUID NOT NULL,
    "trainer_user_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorite_trainers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "favorite_trainers_member_user_id_trainer_user_id_key" ON "favorite_trainers"("member_user_id", "trainer_user_id");

-- CreateIndex
CREATE INDEX "idx_favorite_trainers_member_user_id" ON "favorite_trainers"("member_user_id");

-- CreateIndex
CREATE INDEX "idx_favorite_trainers_trainer_user_id" ON "favorite_trainers"("trainer_user_id");

-- AddForeignKey
ALTER TABLE "favorite_trainers"
ADD CONSTRAINT "favorite_trainers_member_user_id_fkey"
FOREIGN KEY ("member_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorite_trainers"
ADD CONSTRAINT "favorite_trainers_trainer_user_id_fkey"
FOREIGN KEY ("trainer_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
