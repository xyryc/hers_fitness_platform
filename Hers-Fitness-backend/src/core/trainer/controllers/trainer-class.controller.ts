import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { ClassService } from '../../class/class.service';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateFitnessClassDto } from '../dto/create-fitness-class.dto';
import { UpdateFitnessClassDto } from '../dto/update-fitness-class.dto';
import { RescheduleFitnessClassDto } from '../dto/reschedule-fitness-class.dto';
import { TrainerScheduleQueryDto } from '../dto/trainer-schedule-query.dto';
import { TrainerScheduleResponseDto } from '../dto/trainer-schedule-response.dto';
import { TrainerDashboardStatsResponseDto } from '../dto/trainer-dashboard-stats-response.dto';
import { TrainerClassesQueryDto } from '../dto/trainer-classes-query.dto';
import { TrainerEarningsQueryDto } from '../dto/trainer-earnings-query.dto';
import { TrainerEarningsResponseDto, TrainerTopClassItemDto } from '../dto/trainer-earnings-response.dto';
import { FitnessClassResponseDto } from '../../class/dto/fitness-class-response.dto';
import { BookingResponseDto } from '../../member/dto/booking-response.dto';
import { BookingRescheduleDto } from '../../member/dto/booking-reschedule.dto';

@ApiBearerAuth('access-token')
@Controller()
export class TrainerClassController {
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
}
