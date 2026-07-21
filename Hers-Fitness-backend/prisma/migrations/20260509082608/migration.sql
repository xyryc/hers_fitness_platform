-- DropIndex
DROP INDEX "user_tokens_token_key";

-- CreateIndex
CREATE INDEX "idx_user_tokens_user_token" ON "user_tokens"("user_id", "token");
