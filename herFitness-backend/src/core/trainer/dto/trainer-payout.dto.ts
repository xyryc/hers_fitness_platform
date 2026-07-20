import { ApiPropertyOptional } from '@nestjs/swagger';
import { Expose } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateTrainerPayoutOnboardingLinkDto {
    @ApiPropertyOptional({ example: 'heba://trainer/payout/return' })
    @IsOptional()
    @IsString()
    @MaxLength(2048)
    returnUrl?: string;

    @ApiPropertyOptional({ example: 'heba://trainer/payout/refresh' })
    @IsOptional()
    @IsString()
    @MaxLength(2048)
    refreshUrl?: string;
}

export class TrainerPayoutStatusResponseDto {
    @Expose() stripeConnectAccountId!: string | null;
    @Expose() onboardingComplete!: boolean;
    @Expose() chargesEnabled!: boolean;
    @Expose() payoutsEnabled!: boolean;
    @Expose() detailsSubmitted!: boolean;
    @Expose() payoutReady!: boolean;
    @Expose() updatedAt!: Date | null;

    constructor(partial: Partial<TrainerPayoutStatusResponseDto>) {
        Object.assign(this, partial);
    }
}

export class TrainerPayoutOnboardingLinkResponseDto extends TrainerPayoutStatusResponseDto {
    @Expose() onboardingUrl!: string;
    @Expose() expiresAt!: Date;

    constructor(partial: Partial<TrainerPayoutOnboardingLinkResponseDto>) {
        super(partial);
        Object.assign(this, partial);
    }
}
