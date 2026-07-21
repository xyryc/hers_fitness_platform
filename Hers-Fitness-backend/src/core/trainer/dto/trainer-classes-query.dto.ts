import { IsDateString, IsOptional, IsBoolean } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';

export class TrainerClassesQueryDto {
    @ApiPropertyOptional({ description: 'Filter classes by slot date (YYYY-MM-DD)' })
    @IsOptional()
    @IsDateString()
    date?: string;

    @ApiPropertyOptional({
        description: 'Set to true to include completed (past) classes in the response. Defaults to false.',
        default: false,
    })
    @IsOptional()
    @Transform(({ value }) => value === 'true' || value === true)
    @IsBoolean()
    includeCompleted?: boolean;
}
