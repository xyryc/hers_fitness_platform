import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayNotEmpty, IsArray, IsBoolean, IsInt, IsNotEmpty, IsOptional, IsString, IsUUID, Min, ValidateNested } from 'class-validator';

// ─── Create ───────────────────────────────────────────────────────────────────

export class CreateFaqDto {
    @ApiProperty({ example: 'How do I book a session?' })
    @IsString()
    @IsNotEmpty()
    question: string;

    @ApiProperty({ example: 'Go to the trainer\'s profile and tap "Book Session".' })
    @IsString()
    @IsNotEmpty()
    answer: string;

    @ApiPropertyOptional({ example: 1, description: 'Display order (lower = shown first). Defaults to 0.' })
    @Type(() => Number)
    @IsInt()
    @Min(0)
    @IsOptional()
    order?: number = 0;

    @ApiPropertyOptional({ example: true, description: 'Whether the FAQ is visible to users. Defaults to true.' })
    @IsBoolean()
    @IsOptional()
    isActive?: boolean = true;
}

// ─── Update ───────────────────────────────────────────────────────────────────

export class UpdateFaqDto {
    @ApiPropertyOptional({ example: 'How do I cancel a booking?' })
    @IsString()
    @IsNotEmpty()
    @IsOptional()
    question?: string;

    @ApiPropertyOptional({ example: 'You can cancel up to 24 hours before the session.' })
    @IsString()
    @IsNotEmpty()
    @IsOptional()
    answer?: string;

    @ApiPropertyOptional({ example: 2 })
    @Type(() => Number)
    @IsInt()
    @Min(0)
    @IsOptional()
    order?: number;

    @ApiPropertyOptional({ example: false })
    @IsBoolean()
    @IsOptional()
    isActive?: boolean;
}

// ─── Reorder ──────────────────────────────────────────────────────────────────

export class ReorderFaqItemDto {
    @ApiProperty({ example: 'uuid-here' })
    @IsUUID()
    id: string;

    @ApiProperty({ example: 3 })
    @Type(() => Number)
    @IsInt()
    @Min(0)
    order: number;
}

export class ReorderFaqsDto {
    @ApiProperty({ type: [ReorderFaqItemDto] })
    @IsArray()
    @ArrayNotEmpty()
    @ValidateNested({ each: true })
    @Type(() => ReorderFaqItemDto)
    items: ReorderFaqItemDto[];
}
