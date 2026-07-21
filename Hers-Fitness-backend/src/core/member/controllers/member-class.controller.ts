import { Body, Controller, Get, HttpCode, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { ClassService } from '../../class/class.service';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateClassBookingDto } from '../dto/create-class-booking.dto';
import { ConfirmBookingPaymentDto, FailBookingPaymentDto } from '../dto/booking-payment.dto';
import { BookingRescheduleDto } from '../dto/booking-reschedule.dto';
import { BookingCheckoutResponseDto, BookingResponseDto, StripePaymentIntentResponseDto } from '../dto/booking-response.dto';
import { MemberNextWorkoutResponseDto } from '../dto/member-next-workout-response.dto';
import { FitnessClassResponseDto } from '../../class/dto/fitness-class-response.dto';
import { TrainerAvailabilityQueryDto } from '../../class/dto/trainer-availability-query.dto';
import { TrainerAvailabilityCalendarResponseDto } from '../../class/dto/trainer-availability-response.dto';

@ApiBearerAuth('access-token')
@Controller()
export class MemberClassController {
    constructor(private readonly classService: ClassService) { }

    @ApiTags('4. Discovery')
    @Get('member/classes')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: list available classes/services with availability slots' })
    async findAvailableClassesForMember() {
        const classes = await this.classService.findAvailableForMember();
        return new CustomResponse<FitnessClassResponseDto[]>('Available classes fetched successfully', classes, 200);
    }

    @ApiTags('4. Discovery')
    @Post('member/classes/:id/bookings')
    @HttpCode(201)
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: hold selected class slot(s) and get booking payment summary' })
    async createBookingForMember(
        @Param('id') id: string,
        @Body() model: CreateClassBookingDto,
        @Request() req,
    ) {
        const checkout = await this.classService.createBookingForMember(req.user.currentUserId, id, model);
        return new CustomResponse<BookingCheckoutResponseDto>('Booking summary created successfully', checkout, 201);
    }

    @ApiTags('4. Discovery')
    @Get('member/bookings')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: list booked classes' })
    async findMemberBookings(@Request() req) {
        const bookings = await this.classService.findBookingsByMember(req.user.currentUserId);
        return new CustomResponse<BookingResponseDto[]>('Member bookings fetched successfully', bookings, 200);
    }

    @ApiTags('4. Discovery')
    @Get('member/booked-classes')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: list booked classes' })
    async findMemberBookedClasses(@Request() req) {
        const bookings = await this.classService.findBookingsByMember(req.user.currentUserId);
        return new CustomResponse<BookingResponseDto[]>('Member booked classes fetched successfully', bookings, 200);
    }

    @ApiTags('4. Discovery')
    @Get('member/bookings/next')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: get next booked class' })
    async findNextMemberBooking(@Request() req) {
        const booking = await this.classService.findNextBookingByMember(req.user.currentUserId);
        return new CustomResponse<BookingResponseDto | null>('Next member booking fetched successfully', booking, 200);
    }

    @ApiTags('1. Member App')
    @Get('member/workouts/next')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member homepage: list next workout appointments' })
    async findMemberNextWorkouts(@Request() req, @Query('limit') limit?: string) {
        const workouts = await this.classService.findNextWorkoutsByMember(
            req.user.currentUserId,
            limit ? Number(limit) : 5,
        );
        return new CustomResponse<MemberNextWorkoutResponseDto[]>('Next member workouts fetched successfully', workouts, 200);
    }

    @ApiTags('1. Member App')
    @Patch('member/bookings/:bookingId/cancel')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: cancel a booking (100% refund >48h, 50% refund 24-48h, 0% <24h)' })
    async cancelMemberBooking(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.cancelMemberBooking(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Booking cancelled successfully', booking, 200);
    }

    @ApiTags('1. Member App')
    @Patch('member/bookings/:bookingId/reschedule/reject')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: reject trainer reschedule proposal and receive a 100% refund' })
    async rejectMemberReschedule(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.rejectMemberReschedule(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Reschedule rejected and booking cancelled with full refund', booking, 200);
    }

    @ApiTags('1. Member App')
    @Patch('member/bookings/:bookingId/check-in')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: check in to a booked workout after it starts' })
    async checkInMemberBooking(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.checkInMemberBooking(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Member booking check-in saved successfully', booking, 200);
    }

    @ApiTags('1. Member App')
    @Patch('member/bookings/:bookingId/complete')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: mark a booked workout complete' })
    async markMemberBookingComplete(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.markMemberBookingComplete(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Member booking completion saved successfully', booking, 200);
    }

    @ApiTags('1. Member App')
    @Post('member/bookings/:bookingId/reschedule')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: request booking reschedule' })
    async requestMemberBookingReschedule(
        @Param('bookingId') bookingId: string,
        @Body() model: BookingRescheduleDto,
        @Request() req,
    ) {
        const booking = await this.classService.requestMemberBookingReschedule(req.user.currentUserId, bookingId, model);
        return new CustomResponse<BookingResponseDto>('Booking reschedule requested successfully', booking, 200);
    }

    @ApiTags('1. Member App')
    @Patch('member/bookings/:bookingId/reschedule/accept')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: accept booking reschedule request' })
    async acceptMemberBookingReschedule(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.acceptMemberBookingReschedule(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Booking reschedule accepted successfully', booking, 200);
    }

    @ApiTags('4. Discovery')
    @Post('member/booking-payments/:paymentId/stripe-payment-intent')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: create Stripe PaymentIntent for Flutter Stripe SDK' })
    async createStripePaymentIntent(@Param('paymentId') paymentId: string, @Request() req) {
        const intent = await this.classService.createStripePaymentIntentForMember(req.user.currentUserId, paymentId);
        return new CustomResponse<StripePaymentIntentResponseDto>('Stripe payment intent created successfully', intent, 200);
    }

    @ApiTags('4. Discovery')
    @Post('member/booking-payments/:paymentId/confirm')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: confirm booking payment after successful Stripe payment' })
    async confirmBookingPayment(
        @Param('paymentId') paymentId: string,
        @Body() model: ConfirmBookingPaymentDto,
        @Request() req,
    ) {
        const bookings = await this.classService.confirmBookingPaymentForMember(req.user.currentUserId, paymentId, model);
        return new CustomResponse<BookingResponseDto[]>('Booking payment confirmed successfully', bookings, 200);
    }

    @ApiTags('4. Discovery')
    @Post('member/booking-payments/:paymentId/fail')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member)
    @ApiOperation({ summary: 'Member: mark booking payment failed and release held slots' })
    async failBookingPayment(
        @Param('paymentId') paymentId: string,
        @Body() model: FailBookingPaymentDto,
        @Request() req,
    ) {
        const payment = await this.classService.failBookingPaymentForMember(req.user.currentUserId, paymentId, model);
        return new CustomResponse<{ paymentId: string }>('Booking payment failed successfully', payment, 200);
    }

    @ApiTags('4. Discovery')
    @Get('trainers/:trainerUserId/availability')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Member, Roles.Trainer)
    @ApiOperation({ summary: 'Member/Trainer: get trainer monthly availability calendar' })
    async findTrainerAvailabilityCalendar(
        @Param('trainerUserId') trainerUserId: string,
        @Query() query: TrainerAvailabilityQueryDto,
    ) {
        const availability = await this.classService.findTrainerAvailabilityCalendar(trainerUserId, query.month);
        return new CustomResponse<TrainerAvailabilityCalendarResponseDto>('Trainer availability fetched successfully', availability, 200);
    }
}
