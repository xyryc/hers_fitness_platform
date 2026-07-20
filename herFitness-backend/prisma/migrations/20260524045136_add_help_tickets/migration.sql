-- CreateEnum
CREATE TYPE "HelpTicketStatus" AS ENUM ('OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'HELP_TICKET_SUBMITTED';
ALTER TYPE "NotificationType" ADD VALUE 'HELP_TICKET_RESOLVED';

-- CreateTable
CREATE TABLE "help_tickets" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "sender_user_id" UUID NOT NULL,
    "title" VARCHAR(300) NOT NULL,
    "body" TEXT NOT NULL,
    "status" "HelpTicketStatus" NOT NULL DEFAULT 'OPEN',
    "admin_note" TEXT,
    "resolved_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "help_tickets_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_help_tickets_sender_user_id" ON "help_tickets"("sender_user_id");

-- CreateIndex
CREATE INDEX "idx_help_tickets_status" ON "help_tickets"("status");

-- AddForeignKey
ALTER TABLE "help_tickets" ADD CONSTRAINT "help_tickets_sender_user_id_fkey" FOREIGN KEY ("sender_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
