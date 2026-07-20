CREATE TYPE "FitnessGoal" AS ENUM (
    'LOSE_WEIGHT',
    'GAIN_BULK',
    'GAIN_ENDURANCE',
    'TRYING_OUT_APP'
);

CREATE TYPE "WeightUnit" AS ENUM (
    'KG',
    'LBS'
);

CREATE TYPE "DietPreference" AS ENUM (
    'PLANT_BASED_VEGAN',
    'CARBO_DIET',
    'SPECIALIZED_PALEO_KETO',
    'TRADITIONAL_FRUIT_DIET'
);

CREATE TYPE "SupplementType" AS ENUM (
    'WHEY',
    'PROTEIN',
    'VITAMIN_D',
    'MAGNESIUM'
);

CREATE TYPE "CalorieUnit" AS ENUM (
    'KCAL',
    'JOULES'
);

CREATE TYPE "SleepQuality" AS ENUM (
    'EXCELLENT',
    'GREAT',
    'NORMAL',
    'BAD',
    'INSOMNIAC'
);

CREATE TABLE "member_fitness_assessments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "fitness_goal" "FitnessGoal" NOT NULL,
    "weight" DOUBLE PRECISION NOT NULL,
    "weight_unit" "WeightUnit" NOT NULL,
    "age" INTEGER NOT NULL,
    "has_previous_fitness_experience" BOOLEAN NOT NULL,
    "physical_limitations" TEXT,
    "diet_preference" "DietPreference" NOT NULL,
    "taking_supplements" BOOLEAN NOT NULL,
    "supplements" "SupplementType"[] NOT NULL,
    "calorie_goal" INTEGER NOT NULL,
    "calorie_unit" "CalorieUnit" NOT NULL,
    "sleep_quality" "SleepQuality" NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3),

    CONSTRAINT "member_fitness_assessments_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "member_fitness_assessments_user_id_key" ON "member_fitness_assessments"("user_id");

ALTER TABLE "member_fitness_assessments"
ADD CONSTRAINT "member_fitness_assessments_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
