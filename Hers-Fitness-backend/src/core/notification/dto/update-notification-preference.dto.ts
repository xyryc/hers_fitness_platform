import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPreferenceDto {
    // ─── Member-only ──────────────────────────────────────────────────────────────

    @ApiPropertyOptional({ description: 'Member: when you successfully book a class' })
    @IsOptional()
    @IsBoolean()
    bookingConfirmation?: boolean;

    @ApiPropertyOptional({ description: 'Member: when a booking is cancelled by you or the trainer' })
    @IsOptional()
    @IsBoolean()
    bookingCancellation?: boolean;

    @ApiPropertyOptional({ description: 'Member: when a payment is processed for your booking' })
    @IsOptional()
    @IsBoolean()
    paymentConfirmation?: boolean;

    @ApiPropertyOptional({ description: 'Member: when your trainer sends you a message' })
    @IsOptional()
    @IsBoolean()
    trainerMessage?: boolean;

    // ─── Trainer-only ─────────────────────────────────────────────────────────────

    @ApiPropertyOptional({ description: 'Trainer: when a member books one of your classes' })
    @IsOptional()
    @IsBoolean()
    newBooking?: boolean;

    @ApiPropertyOptional({ description: 'Trainer: when a member checks into your class' })
    @IsOptional()
    @IsBoolean()
    classCheckIn?: boolean;

    @ApiPropertyOptional({ description: 'Trainer: when you receive a booking payment' })
    @IsOptional()
    @IsBoolean()
    paymentReceived?: boolean;

    // ─── Shared (both roles) ──────────────────────────────────────────────────────

    @ApiPropertyOptional({ description: 'Both: reminder before upcoming class starts' })
    @IsOptional()
    @IsBoolean()
    classReminder?: boolean;

    @ApiPropertyOptional({ description: 'Both: news and feature updates' })
    @IsOptional()
    @IsBoolean()
    systemAnnouncements?: boolean;

    @ApiPropertyOptional({ description: 'Both: receive push notifications on this device' })
    @IsOptional()
    @IsBoolean()
    pushNotifications?: boolean;

    @ApiPropertyOptional({ description: 'Both: receive summaries and updates by email' })
    @IsOptional()
    @IsBoolean()
    emailNotifications?: boolean;
}
