import { Transform, Type } from 'class-transformer';
import {
    ArrayUnique,
    IsArray,
    IsBoolean,
    IsEnum,
    IsInt,
    IsNotEmpty,
    IsNumber,
    IsOptional,
    IsString,
    Max,
    Min,
} from 'class-validator';

export enum MemberFitnessGoal {
    LOSE_WEIGHT = 'LOSE_WEIGHT',
    GAIN_BULK = 'GAIN_BULK',
    GAIN_ENDURANCE = 'GAIN_ENDURANCE',
    TRYING_OUT_APP = 'TRYING_OUT_APP',
}

export enum MemberWeightUnit {
    KG = 'KG',
    LBS = 'LBS',
}

export enum MemberDietPreference {
    PLANT_BASED_VEGAN = 'PLANT_BASED_VEGAN',
    CARBO_DIET = 'CARBO_DIET',
    SPECIALIZED_PALEO_KETO = 'SPECIALIZED_PALEO_KETO',
    TRADITIONAL_FRUIT_DIET = 'TRADITIONAL_FRUIT_DIET',
}

export enum MemberSupplementType {
    WHEY = 'WHEY',
    PROTEIN = 'PROTEIN',
    VITAMIN_D = 'VITAMIN_D',
    MAGNESIUM = 'MAGNESIUM',
}

export enum MemberCalorieUnit {
    KCAL = 'KCAL',
    JOULES = 'JOULES',
}

export enum MemberSleepQuality {
    EXCELLENT = 'EXCELLENT',
    GREAT = 'GREAT',
    NORMAL = 'NORMAL',
    BAD = 'BAD',
    INSOMNIAC = 'INSOMNIAC',
}

export class UpsertMemberFitnessAssessmentDto {
    @IsEnum(MemberFitnessGoal, { message: 'Fitness goal is invalid' })
    fitnessGoal: MemberFitnessGoal;

    @Type(() => Number)
    @IsNumber({}, { message: 'Weight must be a valid number' })
    @Min(1, { message: 'Weight must be greater than 0' })
    weight: number;

    @IsEnum(MemberWeightUnit, { message: 'Weight unit must be KG or LBS' })
    weightUnit: MemberWeightUnit;

    @Type(() => Number)
    @IsInt({ message: 'Age must be a whole number' })
    @Min(10, { message: 'Age must be at least 10' })
    @Max(120, { message: 'Age must be at most 120' })
    age: number;

    @Type(() => Boolean)
    @IsBoolean({ message: 'Previous fitness experience must be true or false' })
    hasPreviousFitnessExperience: boolean;

    @IsOptional()
    @IsString({ message: 'Physical limitations must be a string' })
    physicalLimitations?: string;

    @IsEnum(MemberDietPreference, { message: 'Diet preference is invalid' })
    dietPreference: MemberDietPreference;

    @Type(() => Boolean)
    @IsBoolean({ message: 'Taking supplements must be true or false' })
    takingSupplements: boolean;

    @Transform(({ value }) => {
        if (!Array.isArray(value)) {
            return [];
        }

        return value
            .map((item) => typeof item === 'string' ? item.trim() : item)
            .filter((item) => item !== '');
    })
    @IsArray({ message: 'Supplements must be an array' })
    @ArrayUnique({ message: 'Supplements must not contain duplicates' })
    @IsEnum(MemberSupplementType, {
        each: true,
        message: 'Each supplement must be WHEY, PROTEIN, VITAMIN_D, or MAGNESIUM',
    })
    supplements: MemberSupplementType[];

    @Type(() => Number)
    @IsInt({ message: 'Calorie goal must be a whole number' })
    @Min(0, { message: 'Calorie goal must be 0 or greater' })
    calorieGoal: number;

    @IsEnum(MemberCalorieUnit, { message: 'Calorie unit must be KCAL or JOULES' })
    calorieUnit: MemberCalorieUnit;

    @IsEnum(MemberSleepQuality, { message: 'Sleep quality is invalid' })
    sleepQuality: MemberSleepQuality;
}
