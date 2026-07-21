-- Add cover_photo_url column to users table
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "cover_photo_url" VARCHAR(2048);

-- Create static_content table for CMS (privacy policy, terms of service, about)
CREATE TABLE IF NOT EXISTS "static_content" (
    "id"         UUID          NOT NULL DEFAULT gen_random_uuid(),
    "key"        VARCHAR(100)  NOT NULL,
    "title"      VARCHAR(200)  NOT NULL,
    "content"    TEXT          NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "static_content_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "static_content_key_key" ON "static_content"("key");

-- Seed default content rows (upsert-safe)
INSERT INTO "static_content" ("key", "title", "content") VALUES
    ('privacy_policy',   'Privacy Policy',   'Our privacy policy content goes here.'),
    ('terms_of_service', 'Terms of Service', 'Our terms of service content goes here.'),
    ('about_us',         'About Us',         'About our fitness platform.')
ON CONFLICT ("key") DO NOTHING;
