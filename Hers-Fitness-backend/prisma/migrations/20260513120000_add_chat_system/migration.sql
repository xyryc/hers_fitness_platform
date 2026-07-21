-- CreateEnum
CREATE TYPE "ChatMessageType" AS ENUM ('TEXT', 'IMAGE');

-- CreateEnum
CREATE TYPE "ChatParticipantStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateTable
CREATE TABLE "chat_conversations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "member_user_id" UUID NOT NULL,
    "trainer_user_id" UUID NOT NULL,
    "member_status" "ChatParticipantStatus" NOT NULL DEFAULT 'INACTIVE',
    "trainer_status" "ChatParticipantStatus" NOT NULL DEFAULT 'INACTIVE',
    "last_message_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "chat_conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "conversation_id" UUID NOT NULL,
    "sender_user_id" UUID NOT NULL,
    "message_type" "ChatMessageType" NOT NULL DEFAULT 'TEXT',
    "text" TEXT,
    "attachment_url" VARCHAR(2048),
    "attachment_type" VARCHAR(100),
    "seen_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "uq_chat_conversations_member_trainer" ON "chat_conversations"("member_user_id", "trainer_user_id");

-- CreateIndex
CREATE INDEX "idx_chat_conversations_member_user_id" ON "chat_conversations"("member_user_id");

-- CreateIndex
CREATE INDEX "idx_chat_conversations_trainer_user_id" ON "chat_conversations"("trainer_user_id");

-- CreateIndex
CREATE INDEX "idx_chat_conversations_last_message_at" ON "chat_conversations"("last_message_at");

-- CreateIndex
CREATE INDEX "idx_chat_messages_conversation_created_at" ON "chat_messages"("conversation_id", "created_at");

-- CreateIndex
CREATE INDEX "idx_chat_messages_sender_user_id" ON "chat_messages"("sender_user_id");

-- AddForeignKey
ALTER TABLE "chat_conversations"
ADD CONSTRAINT "chat_conversations_member_user_id_fkey"
FOREIGN KEY ("member_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_conversations"
ADD CONSTRAINT "chat_conversations_trainer_user_id_fkey"
FOREIGN KEY ("trainer_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages"
ADD CONSTRAINT "chat_messages_conversation_id_fkey"
FOREIGN KEY ("conversation_id") REFERENCES "chat_conversations"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages"
ADD CONSTRAINT "chat_messages_sender_user_id_fkey"
FOREIGN KEY ("sender_user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
