CREATE TABLE "trainer_reviews" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "member_user_id" UUID NOT NULL,
    "trainer_user_id" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "trainer_reviews_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "trainer_reviews_rating_check" CHECK ("rating" >= 1 AND "rating" <= 5)
);

CREATE UNIQUE INDEX "uq_trainer_reviews_member_trainer" ON "trainer_reviews"("member_user_id", "trainer_user_id");
CREATE INDEX "idx_trainer_reviews_member_user_id" ON "trainer_reviews"("member_user_id");
CREATE INDEX "idx_trainer_reviews_trainer_user_id" ON "trainer_reviews"("trainer_user_id");
CREATE INDEX "idx_trainer_reviews_rating" ON "trainer_reviews"("rating");

ALTER TABLE "trainer_reviews"
    ADD CONSTRAINT "trainer_reviews_member_user_id_fkey"
    FOREIGN KEY ("member_user_id") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "trainer_reviews"
    ADD CONSTRAINT "trainer_reviews_trainer_user_id_fkey"
    FOREIGN KEY ("trainer_user_id") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
