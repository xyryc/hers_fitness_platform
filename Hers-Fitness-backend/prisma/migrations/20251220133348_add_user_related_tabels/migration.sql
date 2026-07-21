-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('CREDENTIALS', 'GOOGLE', 'FACEBOOK', 'GITHUB', 'APPLE');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" CITEXT,
    "username" CITEXT,
    "password" VARCHAR(1000),
    "first_name" VARCHAR(200),
    "last_name" VARCHAR(200),
    "display_name" VARCHAR(300),
    "phone_number" VARCHAR(20),
    "profile_image_url" VARCHAR(2048),
    "provider" "AuthProvider" NOT NULL DEFAULT 'CREDENTIALS',
    "provider_id" VARCHAR(100),
    "is_email_verified" BOOLEAN NOT NULL DEFAULT false,
    "is_phone_verified" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "dob" DATE,
    "gender" VARCHAR(50),
    "bio" TEXT,
    "tagline" VARCHAR(300),
    "website" VARCHAR(2048),
    "country_code_iso3" VARCHAR(5),
    "timezone" VARCHAR(50),
    "locale" VARCHAR(10),
    "metadata" JSONB,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(100) NOT NULL,
    "description" VARCHAR(500),
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_roles" (
    "user_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,

    CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id","role_id")
);

-- CreateTable
CREATE TABLE "user_sessions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "ip_address" VARCHAR(45),
    "user_agent" TEXT,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_used_at" TIMESTAMPTZ(3),

    CONSTRAINT "user_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "token" VARCHAR(500) NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "is_used" BOOLEAN NOT NULL DEFAULT false,
    "used_at" TIMESTAMPTZ(3),
    "ip_address" VARCHAR(45),
    "user_agent" VARCHAR(1000),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "user_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_password_history" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "password_hash" VARCHAR(1000) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_password_history_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_provider_provider_id_key" ON "users"("provider", "provider_id");

-- CreateIndex
CREATE UNIQUE INDEX "roles_name_key" ON "roles"("name");

-- CreateIndex
CREATE INDEX "idx_user_roles_role_id" ON "user_roles"("role_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_sessions_token_key" ON "user_sessions"("token");

-- CreateIndex
CREATE INDEX "idx_user_sessions_expires_at" ON "user_sessions"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "user_tokens_token_key" ON "user_tokens"("token");

-- CreateIndex
CREATE INDEX "idx_user_tokens_expires_at" ON "user_tokens"("expires_at");

-- CreateIndex
CREATE INDEX "idx_pwdhist_user_created_desc" ON "user_password_history"("user_id", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "user_password_history_user_id_password_hash_key" ON "user_password_history"("user_id", "password_hash");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_country_code_iso3_fkey" FOREIGN KEY ("country_code_iso3") REFERENCES "countries"("code_iso3") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_sessions" ADD CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_tokens" ADD CONSTRAINT "user_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_password_history" ADD CONSTRAINT "user_password_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- Add Roles
INSERT INTO roles (id, name, description, is_active) VALUES
('07ccec0f-4b6f-4229-b29a-4ed605163ddc', 'ADMINISTRATOR', 'Administrator with full access', TRUE),
('2fd63250-fc05-43cb-ba05-7333de644dd7', 'TEACHER', 'Teacher with limited access', TRUE),
('e6b19836-d83b-480e-b4e6-e64277382f3d', 'STUDENT', 'Student with limited access', TRUE);

-- Add Admin User
INSERT INTO users (id, email, password, first_name, last_name, display_name, is_email_verified, is_active, created_at, updated_at) VALUES
('b748f3eb-c9a8-4c52-8f41-e0a6b2e5f01c', 'kumarsonu676@gmail.com', '$2b$10$mGW7/GzkU5mly0hpoyRROO5sZG.QeZ3WOjJ/flhpFPDfzv6saCtYm', 'Sonu', 'Kumar', 'Sonu Kumar', TRUE, TRUE, NOW(), NOW());

-- Assign Admin Role to Admin User
INSERT INTO user_roles (user_id, role_id) VALUES
('b748f3eb-c9a8-4c52-8f41-e0a6b2e5f01c', '07ccec0f-4b6f-4229-b29a-4ed605163ddc');