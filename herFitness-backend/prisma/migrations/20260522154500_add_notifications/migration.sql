CREATE TYPE "NotificationType" AS ENUM (
    'BOOKING_CONFIRMED',
    'BOOKING_PAYMENT_FAILED',
    'BOOKING_RESCHEDULE_REQUESTED',
    'BOOKING_RESCHEDULED',
    'BOOKING_COMPLETED',
    'CLASS_CANCELLED',
    'CHAT_MESSAGE',
    'TRAINER_REVIEW_RECEIVED',
    'FAVORITE_TRAINER_ADDED',
    'ACCOUNT_VERIFICATION_APPROVED',
    'ACCOUNT_VERIFICATION_REJECTED'
);

CREATE TYPE "DevicePlatform" AS ENUM (
    'IOS',
    'ANDROID',
    'WEB'
);

CREATE TABLE "user_notifications" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "read_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_notifications_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "user_device_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "device_id" VARCHAR(255),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_seen_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "user_device_tokens_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "user_device_tokens_token_key" ON "user_device_tokens"("token");
CREATE INDEX "idx_user_notifications_user_created_desc" ON "user_notifications"("user_id", "created_at" DESC);
CREATE INDEX "idx_user_notifications_user_read_at" ON "user_notifications"("user_id", "read_at");
CREATE INDEX "idx_user_device_tokens_user_active" ON "user_device_tokens"("user_id", "is_active");

ALTER TABLE "user_notifications" ADD CONSTRAINT "user_notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_device_tokens" ADD CONSTRAINT "user_device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
