import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class ConfirmBookingPaymentDto {
    @ApiPropertyOptional({ example: 'stripe' })
    @IsOptional()
    @IsString()
    @MaxLength(100)
    provider?: string;

    @ApiPropertyOptional({ example: 'card' })
    @IsOptional()
    @IsString()
    @MaxLength(100)
    paymentMethod?: string;

    @ApiPropertyOptional({ example: 'pi_123456789' })
    @IsOptional()
    @IsString()
    @MaxLength(255)
    providerSessionId?: string;
}

export class FailBookingPaymentDto extends ConfirmBookingPaymentDto { }
