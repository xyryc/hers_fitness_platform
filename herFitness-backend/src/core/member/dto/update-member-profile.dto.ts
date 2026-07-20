import { IsEnum, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

enum DietPreference {
    PLANT_BASED_VEGAN = 'PLANT_BASED_VEGAN',
    CARBO_DIET = 'CARBO_DIET',
    SPECIALIZED_PALEO_KETO = 'SPECIALIZED_PALEO_KETO',
    TRADITIONAL_FRUIT_DIET = 'TRADITIONAL_FRUIT_DIET',
}

enum WeightUnit {
    KG = 'KG',
    LBS = 'LBS',
}

export class UpdateMemberProfileDto {
    @ApiPropertyOptional()
    @IsOptional()
    @IsString()
    displayName?: string;

    @ApiPropertyOptional()
    @IsOptional()
    @IsString()
    phoneNumber?: string;

    @ApiPropertyOptional()
    @IsOptional()
    @IsString()
    state?: string;

    @ApiPropertyOptional()
    @IsOptional()
    @IsString()
    location?: string;

    @ApiPropertyOptional({ minimum: 1, maximum: 120 })
    @IsOptional()
    @IsInt()
    @Min(1)
    @Max(120)
    age?: number;

    @ApiPropertyOptional({ minimum: 1, maximum: 500 })
    @IsOptional()
    @IsNumber()
    @Min(1)
    @Max(500)
    weight?: number;

    @ApiPropertyOptional({ enum: WeightUnit })
    @IsOptional()
    @IsEnum(WeightUnit)
    weightUnit?: string;

    @ApiPropertyOptional({ enum: DietPreference })
    @IsOptional()
    @IsEnum(DietPreference)
    dietPreference?: string;
}
