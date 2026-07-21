import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches } from 'class-validator';

export class TrainerScheduleQueryDto {
    @ApiPropertyOptional({ example: '2026-05-23', description: 'Single schedule date in YYYY-MM-DD format.' })
    @IsOptional()
    @IsString()
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date must be in YYYY-MM-DD format' })
    date?: string;

    @ApiPropertyOptional({ example: '2026-05-01', description: 'Start date for a range query.' })
    @IsOptional()
    @IsString()
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'startDate must be in YYYY-MM-DD format' })
    startDate?: string;

    @ApiPropertyOptional({ example: '2026-05-31', description: 'End date for a range query.' })
    @IsOptional()
    @IsString()
    @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'endDate must be in YYYY-MM-DD format' })
    endDate?: string;
}
