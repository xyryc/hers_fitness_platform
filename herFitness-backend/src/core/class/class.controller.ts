import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { CreateFitnessClassDto } from './dto/create-fitness-class.dto';
import { FitnessClassResponseDto } from './dto/fitness-class-response.dto';
import { UpdateFitnessClassDto } from './dto/update-fitness-class.dto';
import { RescheduleFitnessClassDto } from './dto/reschedule-fitness-class.dto';
import { ClassService } from './class.service';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { TrainerAvailabilityQueryDto } from './dto/trainer-availability-query.dto';
import { TrainerAvailabilityCalendarResponseDto } from './dto/trainer-availability-response.dto';
import { CreateClassBookingDto } from './dto/create-class-booking.dto';
import { ConfirmBookingPaymentDto, FailBookingPaymentDto } from './dto/booking-payment.dto';
import { BookingRescheduleDto } from './dto/booking-reschedule.dto';
import { BookingCheckoutResponseDto, BookingResponseDto, StripePaymentIntentResponseDto } from './dto/booking-response.dto';
import { MemberNextWorkoutResponseDto } from './dto/member-next-workout-response.dto';
import { TrainerScheduleQueryDto } from './dto/trainer-schedule-query.dto';
import { TrainerScheduleResponseDto } from './dto/trainer-schedule-response.dto';
import { TrainerDashboardStatsResponseDto } from './dto/trainer-dashboard-stats-response.dto';
import { TrainerClassesQueryDto } from './dto/trainer-classes-query.dto';
import { TrainerEarningsQueryDto } from './dto/trainer-earnings-query.dto';
import { TrainerEarningsResponseDto, TrainerTopClassItemDto } from './dto/trainer-earnings-response.dto';

@ApiBearerAuth('access-token')
@Controller()
export class ClassController {
    constructor(private readonly classService: ClassService) { }

    @ApiTags('2. Trainer App')
    @Get('trainer/schedule')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: list scheduled booked classes by date or date range' })
    async findTrainerSchedule(@Request() req, @Query() query: TrainerScheduleQueryDto) {
        const schedule = await this.classService.findScheduleByTrainer(req.user.currentUserId, query);
        return new CustomResponse<TrainerScheduleResponseDto>('Trainer schedule fetched successfully', schedule, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('trainer/dashboard/stats')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: dashboard stats — totalClasses, totalAttendance, avgClassSize, overallRating' })
    async getTrainerDashboardStats(@Request() req) {
        const stats = await this.classService.getTrainerDashboardStats(req.user.currentUserId);
        return new CustomResponse<TrainerDashboardStatsResponseDto>('Trainer dashboard stats fetched successfully', stats, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('trainer/dashboard/earnings')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({
        summary: 'Trainer: earnings chart data — ?period=weekly|monthly|yearly. ' +
            'weekly: add ?date=YYYY-MM-DD (any day in the target week, defaults to current week). ' +
            'monthly: add ?year=2026 (defaults to current year). ' +
            'yearly: no extra params needed.',
    })
    async getTrainerEarnings(@Request() req, @Query() query: TrainerEarningsQueryDto) {
        const earnings = await this.classService.getTrainerEarnings(req.user.currentUserId, query);
        return new CustomResponse<TrainerEarningsResponseDto>('Trainer earnings fetched successfully', earnings, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('trainer/dashboard/top-classes')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: top performing classes sorted by booking count then revenue. Optional ?limit=5 (max 20).' })
    async getTrainerTopClasses(@Request() req, @Query('limit') limit?: string) {
        const classes = await this.classService.getTrainerTopClasses(req.user.currentUserId, limit ? Number(limit) : 5);
        return new CustomResponse<TrainerTopClassItemDto[]>('Top performing classes fetched successfully', classes, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('trainer/classes/next')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: get next upcoming class' })
    async findNextTrainerClass(@Request() req) {
        const fitnessClass = await this.classService.findNextClassForTrainer(req.user.currentUserId);
        return new CustomResponse<FitnessClassResponseDto | null>('Next trainer class fetched successfully', fitnessClass, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('trainer/classes')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: list own classes sorted by next upcoming slot. Optional ?date=YYYY-MM-DD to filter by slot date (e.g. today\'s classes)' })
    async findTrainerClasses(@Request() req, @Query() query: TrainerClassesQueryDto) {
        const classes = await this.classService.findByTrainer(req.user.currentUserId, query.date, query.includeCompleted ?? false);
        return new CustomResponse<FitnessClassResponseDto[]>('Trainer classes fetched successfully', classes, 200);
    }

    @ApiTags('2. Trainer App')
    @Get('trainer/classes/:id')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: get own class/service by ID' })
    async findTrainerClassById(@Param('id') id: string, @Request() req) {
        const fitnessClass = await this.classService.findByIdForTrainer(id, req.user.currentUserId);
        return new CustomResponse<FitnessClassResponseDto>('Trainer class fetched successfully', fitnessClass, 200);
    }

    @ApiTags('2. Trainer App')
    @Post('trainer/classes')
    @HttpCode(201)
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: create class/service with availability slots' })
    async create(@Body() model: CreateFitnessClassDto, @Request() req) {
        const fitnessClass = await this.classService.create(req.user.currentUserId, model);
        return new CustomResponse<FitnessClassResponseDto>('Class created successfully', fitnessClass, 201);
    }

    @ApiTags('2. Trainer App')
    @Post('trainer/classes/:id/reschedule')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: request class reschedule for member approval' })
    async requestTrainerClassReschedule(@Param('id') id: string, @Body() model: RescheduleFitnessClassDto, @Request() req) {
        const fitnessClass = await this.classService.requestTrainerClassReschedule(id, req.user.currentUserId, model);
        return new CustomResponse<FitnessClassResponseDto>('Class reschedule requested successfully', fitnessClass, 200);
    }

    @ApiTags('2. Trainer App')
    @Patch('trainer/classes/:id')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: update class/service and optionally replace available slots' })
    async update(@Param('id') id: string, @Body() model: UpdateFitnessClassDto, @Request() req) {
        const fitnessClass = await this.classService.updateForTrainer(id, req.user.currentUserId, model);
        return new CustomResponse<FitnessClassResponseDto>('Class updated successfully', fitnessClass, 200);
    }

    @ApiTags('2. Trainer App')
    @Delete('trainer/classes/:id')
    @UseGuards(AuthGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: cancel own class/service' })
    async cancel(@Param('id') id: string, @Request() req) {
        const fitnessClass = await this.classService.cancelForTrainer(id, req.user.currentUserId);
        return new CustomResponse<FitnessClassResponseDto>('Class cancelled successfully', fitnessClass, 200);
    }

    @ApiTags('2. Trainer App')
    @Patch('trainer/bookings/:bookingId/check-in')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: check in to a booking after the member has checked in' })
    async checkInTrainerBooking(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.checkInTrainerBooking(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Trainer booking check-in saved successfully', booking, 200);
    }

    @ApiTags('2. Trainer App')
    @Patch('trainer/bookings/:bookingId/complete')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: mark a booking complete after member confirmation' })
    async markTrainerBookingComplete(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.markTrainerBookingComplete(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Trainer booking completion saved successfully', booking, 200);
    }

    @ApiTags('2. Trainer App')
    @Post('trainer/bookings/:bookingId/reschedule')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: request booking reschedule' })
    async requestTrainerBookingReschedule(
        @Param('bookingId') bookingId: string,
        @Body() model: BookingRescheduleDto,
        @Request() req,
    ) {
        const booking = await this.classService.requestTrainerBookingReschedule(req.user.currentUserId, bookingId, model);
        return new CustomResponse<BookingResponseDto>('Booking reschedule requested successfully', booking, 200);
    }

    @ApiTags('2. Trainer App')
    @Patch('trainer/bookings/:bookingId/reschedule/accept')
    @UseGuards(AuthGuard, ApprovedAccountGuard, RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: accept booking reschedule request' })
    async acceptTrainerBookingReschedule(@Param('bookingId') bookingId: string, @Request() req) {
        const booking = await this.classService.acceptTrainerBookingReschedule(req.user.currentUserId, bookingId);
        return new CustomResponse<BookingResponseDto>('Booking reschedule accepted successfully', booking, 200);
    }

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
