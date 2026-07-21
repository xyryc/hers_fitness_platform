import { Injectable } from '@nestjs/common';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { Roles } from 'src/common/enums/roles.enum';
import { UserService } from '../user/user.service';
import { CreateFitnessClassDto, FitnessSessionFormat } from './dto/create-fitness-class.dto';
import { AvailabilitySlotDto } from './dto/availability-slot.dto';
import { ClassJoinedMemberResponseDto, FitnessClassAvailabilitySlotResponseDto, FitnessClassResponseDto, FitnessClassTrainerResponseDto } from './dto/fitness-class-response.dto';
import { UpdateFitnessClassDto } from './dto/update-fitness-class.dto';
import { RescheduleFitnessClassDto } from './dto/reschedule-fitness-class.dto';
import { TrainerAvailabilityCalendarResponseDto, TrainerAvailabilityDayResponseDto, TrainerAvailabilitySlotResponseDto } from './dto/trainer-availability-response.dto';
import { CreateClassBookingDto } from './dto/create-class-booking.dto';
import { ConfirmBookingPaymentDto, FailBookingPaymentDto } from './dto/booking-payment.dto';
import { BookingRescheduleDto } from './dto/booking-reschedule.dto';
import {
    BookingCheckoutResponseDto,
    BookingClassResponseDto,
    BookingPaymentSummaryResponseDto,
    BookingResponseDto,
    BookingTrainerResponseDto,
    StripePaymentIntentResponseDto,
} from './dto/booking-response.dto';
import {
    MemberNextWorkoutClassResponseDto,
    MemberNextWorkoutLocationTimeResponseDto,
    MemberNextWorkoutResponseDto,
    MemberNextWorkoutTrainerResponseDto,
    MemberWorkoutActionsResponseDto,
} from './dto/member-next-workout-response.dto';
import {
    TrainerScheduleActionsResponseDto,
    TrainerScheduleDayResponseDto,
    TrainerScheduleItemResponseDto,
    TrainerScheduleResponseDto,
} from './dto/trainer-schedule-response.dto';
import { TrainerDashboardStatsResponseDto } from './dto/trainer-dashboard-stats-response.dto';
import { EarningsPeriod, TrainerEarningsQueryDto } from './dto/trainer-earnings-query.dto';
import { EarningsDataPointDto, TrainerEarningsResponseDto, TrainerTopClassItemDto } from './dto/trainer-earnings-response.dto';
import { FitnessClassRepository } from './domain/repositories/fitness-class.repository';
import { FitnessClassEntity } from './domain/entities/fitness-class.entity';
import { StripePaymentService } from 'src/infrastructure/payment/stripe/stripe-payment.service';
import { DateTimeUtils } from 'src/utils/date-time.utils';
import { NotificationService, NotificationType } from '../notification/notification.service';

@Injectable()
export class ClassService {
    constructor(
        private readonly fitnessClassRepository: FitnessClassRepository,
        private readonly userService: UserService,
        private readonly stripePaymentService: StripePaymentService,
        private readonly notificationService: NotificationService,
    ) { }

    async create(trainerUserId: string, model: CreateFitnessClassDto): Promise<FitnessClassResponseDto> {
        const trainer = await this.userService.findById(trainerUserId);
        if (!trainer) {
            throw new NotFoundAppException('Trainer not found', 'TRAINER_NOT_FOUND');
        }

        const roleNames = trainer.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Trainer)) {
            throw new BadRequestAppException('Only trainers can create classes.', ['TRAINER_ONLY_FEATURE']);
        }

        this.validateSessionFormatCapacity(model.sessionFormat, model.capacity);
        this.validateSlotCountForPlan(model.sessionPlanType, model.availableSlots);

        const slots = this.buildSlotRecords(trainerUserId, model.availableSlots, model.durationMinutes, trainer.timezone);
        const fitnessClass = await this.fitnessClassRepository.create(trainerUserId, model, slots);
        return this.mapToResponse(fitnessClass);
    }

    async findAll(): Promise<FitnessClassResponseDto[]> {
        const fitnessClasses = await this.fitnessClassRepository.findAll();
        return fitnessClasses.map((fitnessClass) => this.mapToResponse(fitnessClass));
    }

    async findByTrainer(trainerUserId: string, date?: string, includeCompleted = false): Promise<FitnessClassResponseDto[]> {
        const fitnessClasses = await this.fitnessClassRepository.findByTrainerUserId(trainerUserId, date, includeCompleted);
        return this.sortClassesByNextSlot(fitnessClasses).map((fitnessClass) => this.mapToResponse(fitnessClass));
    }

    async findNextClassForTrainer(trainerUserId: string): Promise<FitnessClassResponseDto | null> {
        const fitnessClasses = await this.fitnessClassRepository.findByTrainerUserId(trainerUserId);
        const now = new Date();
        const sorted = this.sortClassesByNextSlot(
            fitnessClasses.filter((c) =>
                c.status === 'ACTIVE'
                && [...(c.availableSlots ?? []), ...(c.bookedSlots ?? [])].some((s) => s.startAt > now),
            ),
        );
        return sorted.length ? this.mapToResponse(sorted[0]) : null;
    }

    async getTrainerDashboardStats(trainerUserId: string): Promise<TrainerDashboardStatsResponseDto> {
        const { totalClasses, totalAttendance, totalRevenue, overallRating } =
            await this.fitnessClassRepository.findTrainerDashboardStats(trainerUserId);

        const avgClassSize = totalClasses > 0
            ? Number((totalAttendance / totalClasses).toFixed(2))
            : 0;

        return new TrainerDashboardStatsResponseDto({ totalClasses, totalAttendance, totalRevenue, avgClassSize, overallRating });
    }

    async getTrainerEarnings(trainerUserId: string, query: TrainerEarningsQueryDto): Promise<TrainerEarningsResponseDto> {
        const bookings = await this.fitnessClassRepository.findTrainerEarningsData(trainerUserId);
        const { period } = query;

        if (period === EarningsPeriod.WEEKLY) {
            return this.buildWeeklyEarnings(bookings, query.date);
        }
        if (period === EarningsPeriod.MONTHLY) {
            return this.buildMonthlyEarnings(bookings, query.year);
        }
        return this.buildYearlyEarnings(bookings);
    }

    async getTrainerTopClasses(trainerUserId: string, limit = 5): Promise<TrainerTopClassItemDto[]> {
        const safeLimit = Math.min(Math.max(Number(limit) || 5, 1), 20);
        const classes = await this.fitnessClassRepository.findTrainerTopClasses(trainerUserId, safeLimit);
        return classes.map((c: any) => new TrainerTopClassItemDto(c));
    }

    private buildWeeklyEarnings(
        bookings: { scheduledDate: string; totalAmount: any }[],
        dateInput?: string,
    ): TrainerEarningsResponseDto {
        const anchor = dateInput ? new Date(dateInput) : new Date();
        // Find Monday of the anchor week
        const dayOfWeek = anchor.getUTCDay(); // 0=Sun, 1=Mon...
        const diffToMonday = (dayOfWeek === 0 ? -6 : 1 - dayOfWeek);
        const monday = new Date(anchor);
        monday.setUTCDate(anchor.getUTCDate() + diffToMonday);

        const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const data: EarningsDataPointDto[] = DAY_LABELS.map((label, i) => {
            const day = new Date(monday);
            day.setUTCDate(monday.getUTCDate() + i);
            const key = day.toISOString().slice(0, 10); // YYYY-MM-DD
            const earnings = bookings
                .filter((b) => b.scheduledDate === key)
                .reduce((sum, b) => sum + Number(b.totalAmount), 0);
            return new EarningsDataPointDto({ label, key, earnings: Number(earnings.toFixed(2)) });
        });

        const weekStartDate = monday.toISOString().slice(0, 10);
        const weekEnd = new Date(monday);
        weekEnd.setUTCDate(monday.getUTCDate() + 6);
        const weekEndDate = weekEnd.toISOString().slice(0, 10);
        const totalEarnings = Number(data.reduce((s, d) => s + d.earnings, 0).toFixed(2));

        return new TrainerEarningsResponseDto({ period: 'weekly', data, totalEarnings, weekStartDate, weekEndDate });
    }

    private buildMonthlyEarnings(
        bookings: { scheduledDate: string; totalAmount: any }[],
        yearInput?: number,
    ): TrainerEarningsResponseDto {
        const year = yearInput ?? new Date().getUTCFullYear();
        const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        const data: EarningsDataPointDto[] = MONTH_LABELS.map((label, i) => {
            const month = i + 1; // 1-12
            const key = `${year}-${String(month).padStart(2, '0')}`;
            const earnings = bookings
                .filter((b) => b.scheduledDate.startsWith(key))
                .reduce((sum, b) => sum + Number(b.totalAmount), 0);
            return new EarningsDataPointDto({ label, key, earnings: Number(earnings.toFixed(2)) });
        });

        const totalEarnings = Number(data.reduce((s, d) => s + d.earnings, 0).toFixed(2));
        return new TrainerEarningsResponseDto({ period: 'monthly', data, totalEarnings, year });
    }

    private buildYearlyEarnings(
        bookings: { scheduledDate: string; totalAmount: any }[],
    ): TrainerEarningsResponseDto {
        const yearMap = new Map<number, number>();

        for (const booking of bookings) {
            const year = Number(booking.scheduledDate.slice(0, 4));
            yearMap.set(year, (yearMap.get(year) ?? 0) + Number(booking.totalAmount));
        }

        // If no bookings at all, still return current year with 0
        if (yearMap.size === 0) {
            yearMap.set(new Date().getUTCFullYear(), 0);
        }

        const data: EarningsDataPointDto[] = Array.from(yearMap.entries())
            .sort(([a], [b]) => a - b)
            .map(([year, earnings]) => new EarningsDataPointDto({
                label: String(year),
                key: String(year),
                earnings: Number(earnings.toFixed(2)),
            }));

        const totalEarnings = Number(data.reduce((s, d) => s + d.earnings, 0).toFixed(2));
        return new TrainerEarningsResponseDto({ period: 'yearly', data, totalEarnings });
    }

    private sortClassesByNextSlot(classes: FitnessClassEntity[]): FitnessClassEntity[] {
        const now = new Date();
        return [...classes].sort((a, b) => {
            const nextSlot = (c: FitnessClassEntity) =>
                [...(c.availableSlots ?? []), ...(c.bookedSlots ?? [])]
                    .map((s) => s.startAt)
                    .filter((t) => t > now)
                    .sort((x, y) => x.getTime() - y.getTime())[0] ?? null;

            const aNext = nextSlot(a);
            const bNext = nextSlot(b);
            if (aNext && bNext) return aNext.getTime() - bNext.getTime();
            if (aNext) return -1;
            if (bNext) return 1;
            return b.createdAt.getTime() - a.createdAt.getTime();
        });
    }

    async findAvailableForMember(): Promise<FitnessClassResponseDto[]> {
        const fitnessClasses = await this.fitnessClassRepository.findAvailableForMember();
        return fitnessClasses.map((fitnessClass) => this.mapToResponse(fitnessClass));
    }

    async createBookingForMember(
        memberUserId: string,
        fitnessClassId: string,
        model: CreateClassBookingDto,
    ): Promise<BookingCheckoutResponseDto> {
        const fitnessClass = await this.fitnessClassRepository.findById(fitnessClassId);
        if (!fitnessClass || fitnessClass.status !== 'ACTIVE') {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        if (model.selectedClassType && model.selectedClassType !== fitnessClass.classType) {
            throw new BadRequestAppException('Selected class type does not match this class.', ['CLASS_TYPE_MISMATCH']);
        }

        const requestedSlotIds = this.getRequestedSlotIds(model);
        if (!requestedSlotIds.length) {
            throw new BadRequestAppException('At least one class slot must be selected.', ['CLASS_SLOT_REQUIRED']);
        }

        if (fitnessClass.sessionPlanType === 'SINGLE_SESSION' && requestedSlotIds.length !== 1) {
            throw new BadRequestAppException('Single session booking requires exactly one slot.', ['SINGLE_SESSION_ONLY_ONE_SLOT']);
        }

        this.validateRequestedSlotsForBooking(fitnessClass, requestedSlotIds);

        const result = await this.fitnessClassRepository.createBooking(memberUserId, fitnessClassId, model);
        this.throwBookingError(result);

        return new BookingCheckoutResponseDto({
            bookings: result.bookings.map((booking: any) => this.mapBooking(booking)),
            payment: this.mapPaymentSummary(result.payment, model.couponCode),
            reservedUntil: result.reservedUntil,
        });
    }

    async findBookingsByMember(memberUserId: string): Promise<BookingResponseDto[]> {
        const bookings = await this.fitnessClassRepository.findBookedClassesByMember(memberUserId);
        return bookings.map((booking: any) => this.mapBooking(booking));
    }

    async findNextBookingByMember(memberUserId: string): Promise<BookingResponseDto | null> {
        const booking = await this.fitnessClassRepository.findNextBookingByMember(memberUserId);
        return booking ? this.mapBooking(booking) : null;
    }

    async findNextWorkoutsByMember(memberUserId: string, limit: number = 5): Promise<MemberNextWorkoutResponseDto[]> {
        const requestedLimit = Number.isFinite(limit) ? limit : 5;
        const safeLimit = Math.min(Math.max(requestedLimit || 5, 1), 20);
        const bookings = await this.fitnessClassRepository.findNextWorkoutsByMember(memberUserId, safeLimit);
        return bookings.map((booking: any) => this.mapNextWorkout(booking));
    }

    async findScheduleByTrainer(
        trainerUserId: string,
        query: { date?: string; startDate?: string; endDate?: string },
    ): Promise<TrainerScheduleResponseDto> {
        const { startDate, endDate } = this.resolveScheduleDateRange(query);
        const bookings = await this.fitnessClassRepository.findScheduleBookingsByTrainer(
            trainerUserId,
            startDate,
            endDate,
        );

        return this.mapTrainerSchedule(startDate, endDate, bookings);
    }

    async createStripePaymentIntentForMember(
        memberUserId: string,
        paymentId: string,
    ): Promise<StripePaymentIntentResponseDto> {
        const payment = await this.fitnessClassRepository.findPendingBookingPaymentForMember(memberUserId, paymentId);
        if (!payment) {
            throw new NotFoundAppException('Pending booking payment not found.', 'PAYMENT_NOT_FOUND');
        }

        const amount = this.toStripeAmount(payment.totalAmount);
        const currency = payment.currency ?? 'USD';

        // Resolve trainer Connect account from any booking on this payment
        const firstBooking = (payment.bookings ?? [])[0];
        const trainerProfile = firstBooking?.trainer?.trainerProfile;
        const destinationAccountId = (
            trainerProfile?.stripeConnectAccountId
            && trainerProfile?.stripeConnectOnboardingComplete
            && trainerProfile?.stripeChargesEnabled
            && trainerProfile?.stripePayoutsEnabled
        ) ? trainerProfile.stripeConnectAccountId : null;

        // Platform fee in cents (platformFeeAmount is stored in currency units)
        const applicationFeeAmount = destinationAccountId && payment.platformFeeAmount != null
            ? this.toStripeAmount(payment.platformFeeAmount)
            : null;

        const paymentIntent = await this.stripePaymentService.createPaymentIntent({
            amount,
            currency,
            paymentIntentId: payment.providerSessionId,
            destinationAccountId,
            applicationFeeAmount,
            metadata: {
                paymentId: payment.id,
                memberUserId,
                fitnessClassId: payment.fitnessClassId,
                bookingIds: (payment.bookings ?? []).map((booking: any) => booking.id).join(','),
            },
        });

        await this.fitnessClassRepository.updateBookingPaymentProviderSession(
            memberUserId,
            payment.id,
            paymentIntent.id,
        );

        return new StripePaymentIntentResponseDto({
            paymentId: payment.id,
            paymentIntentId: paymentIntent.id,
            clientSecret: paymentIntent.client_secret ?? null,
            publishableKey: this.stripePaymentService.publishableKey,
            amount,
            currency,
        });
    }

    async confirmBookingPaymentForMember(
        memberUserId: string,
        paymentId: string,
        model: ConfirmBookingPaymentDto,
    ): Promise<BookingResponseDto[]> {
        const result = await this.fitnessClassRepository.confirmBookingPayment(memberUserId, paymentId, {
            provider: model.provider ?? 'stripe',
            paymentMethod: model.paymentMethod,
            providerSessionId: model.providerSessionId,
        });
        this.throwBookingError(result);

        await Promise.all(result.bookings.map((booking: any) => this.notifyBookingConfirmed(booking)));

        return result.bookings.map((booking: any) => this.mapBooking(booking));
    }

    async failBookingPaymentForMember(
        memberUserId: string,
        paymentId: string,
        model: FailBookingPaymentDto,
    ): Promise<{ paymentId: string }> {
        const result = await this.fitnessClassRepository.failBookingPayment(memberUserId, paymentId, {
            provider: model.provider ?? 'stripe',
            paymentMethod: model.paymentMethod,
            providerSessionId: model.providerSessionId,
        });
        this.throwBookingError(result);

        await this.notificationService.notifyUser({
            userId: memberUserId,
            type: NotificationType.BOOKING_PAYMENT_FAILED,
            title: 'Payment failed',
            body: 'Your booking payment could not be completed. Please try again.',
            data: {
                paymentId: result.paymentId,
            },
        });

        return { paymentId: result.paymentId };
    }

    async markMemberBookingComplete(memberUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.markBookingComplete(
            bookingId,
            memberUserId,
            Roles.Member,
        );
        this.throwBookingError(result);

        await this.notifyBookingCompletion(result.booking, Roles.Member);

        return this.mapBooking(result.booking);
    }

    async markTrainerBookingComplete(trainerUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.markBookingComplete(
            bookingId,
            trainerUserId,
            Roles.Trainer,
        );
        this.throwBookingError(result);

        await this.notifyBookingCompletion(result.booking, Roles.Trainer);

        return this.mapBooking(result.booking);
    }

    async cancelMemberBooking(memberUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.cancelBookingByMember(memberUserId, bookingId);
        this.throwBookingError(result);

        const booking = result.booking;
        const refundPercent = this.getMemberCancelRefundPercent(booking);
        const refundAmount = Math.round(Number(booking.totalAmount) * refundPercent * 100);

        if (refundAmount > 0 && booking.bookingPayment?.providerSessionId) {
            try {
                await this.stripePaymentService.createRefund({
                    paymentIntentId: booking.bookingPayment.providerSessionId,
                    amountCents: refundAmount,
                    reason: 'requested_by_customer',
                });
            } catch {
                // refund failure should not block the cancellation response
            }
        }

        await this.notificationService.notifyUser({
            userId: booking.trainerUserId,
            type: NotificationType.BOOKING_CANCELLED,
            title: 'Booking cancelled',
            body: `${booking.fullName} cancelled their booking for ${booking.scheduledDate} at ${booking.startTime}.`,
            data: this.getBookingNotificationData(booking),
        });

        return this.mapBooking(booking);
    }

    async rejectMemberReschedule(memberUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.rejectBookingRescheduleByMember(memberUserId, bookingId);
        this.throwBookingError(result);

        const booking = result.booking;
        const refundAmountCents = Math.round(Number(booking.totalAmount) * 100);

        if (refundAmountCents > 0 && booking.bookingPayment?.providerSessionId) {
            try {
                await this.stripePaymentService.createRefund({
                    paymentIntentId: booking.bookingPayment.providerSessionId,
                    amountCents: refundAmountCents,
                    reason: 'requested_by_customer',
                });
            } catch {
                // refund failure should not block the rejection response
            }
        }

        await this.notificationService.notifyUser({
            userId: booking.trainerUserId,
            type: NotificationType.BOOKING_CANCELLED,
            title: 'Reschedule rejected',
            body: `${booking.fullName} rejected your reschedule proposal and the booking has been cancelled with a full refund.`,
            data: this.getBookingNotificationData(booking),
        });

        return this.mapBooking(booking);
    }

    async checkInMemberBooking(memberUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.markBookingCheckIn(
            bookingId,
            memberUserId,
            Roles.Member,
        );
        this.throwBookingError(result);

        return this.mapBooking(result.booking);
    }

    async checkInTrainerBooking(trainerUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.markBookingCheckIn(
            bookingId,
            trainerUserId,
            Roles.Trainer,
        );
        this.throwBookingError(result);

        return this.mapBooking(result.booking);
    }

    async requestMemberBookingReschedule(
        memberUserId: string,
        bookingId: string,
        model: BookingRescheduleDto,
    ): Promise<BookingResponseDto> {
        return this.requestBookingReschedule(memberUserId, bookingId, Roles.Member, model);
    }

    async requestTrainerBookingReschedule(
        trainerUserId: string,
        bookingId: string,
        model: BookingRescheduleDto,
    ): Promise<BookingResponseDto> {
        return this.requestBookingReschedule(trainerUserId, bookingId, Roles.Trainer, model);
    }

    async acceptMemberBookingReschedule(memberUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.acceptBookingReschedule(
            bookingId,
            memberUserId,
            Roles.Member,
        );
        this.throwBookingError(result);

        await this.notifyBookingRescheduleAccepted(result.booking, Roles.Member);

        return this.mapBooking(result.booking);
    }

    async acceptTrainerBookingReschedule(trainerUserId: string, bookingId: string): Promise<BookingResponseDto> {
        const result = await this.fitnessClassRepository.acceptBookingReschedule(
            bookingId,
            trainerUserId,
            Roles.Trainer,
        );
        this.throwBookingError(result);

        await this.notifyBookingRescheduleAccepted(result.booking, Roles.Trainer);

        return this.mapBooking(result.booking);
    }

    async findTrainerAvailabilityCalendar(
        trainerUserId: string,
        month: string,
    ): Promise<TrainerAvailabilityCalendarResponseDto> {
        const trainer = await this.userService.findById(trainerUserId);
        if (!trainer) {
            throw new NotFoundAppException('Trainer not found', 'TRAINER_NOT_FOUND');
        }

        const roleNames = trainer.roles?.map((role) => role.name) ?? [];
        if (!roleNames.includes(Roles.Trainer)) {
            throw new BadRequestAppException('Requested user is not a trainer.', ['USER_IS_NOT_TRAINER']);
        }

        if (trainer.verificationStatus !== 'APPROVED') {
            throw new BadRequestAppException('Trainer is not approved.', ['TRAINER_NOT_APPROVED']);
        }

        const { startDate, endDate } = this.getMonthDateRange(month);
        const slots = await this.fitnessClassRepository.findTrainerAvailabilitySlots(
            trainerUserId,
            startDate,
            endDate,
        );

        return this.mapToTrainerAvailabilityCalendar(trainerUserId, month, startDate, endDate, slots);
    }

    async findById(id: string): Promise<FitnessClassResponseDto> {
        const fitnessClass = await this.fitnessClassRepository.findById(id);
        if (!fitnessClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        return this.mapToResponse(fitnessClass);
    }

    async findByIdForTrainer(id: string, trainerUserId: string): Promise<FitnessClassResponseDto> {
        const fitnessClass = await this.fitnessClassRepository.findByIdAndTrainerUserId(id, trainerUserId);
        if (!fitnessClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        return this.mapToResponse(fitnessClass);
    }

    async requestTrainerClassReschedule(
        id: string,
        trainerUserId: string,
        model: RescheduleFitnessClassDto,
    ): Promise<FitnessClassResponseDto> {
        const existingClass = await this.fitnessClassRepository.findByIdAndTrainerUserId(id, trainerUserId);
        if (!existingClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        if (existingClass.status === 'CANCELLED') {
            throw new BadRequestAppException('Cancelled classes cannot be rescheduled.', ['CLASS_ALREADY_CANCELLED']);
        }

        this.validateSlotCountForPlan(existingClass.sessionPlanType, model.availableSlots);

        const slots = this.buildSlotRecords(
            trainerUserId,
            model.availableSlots,
            existingClass.durationMinutes,
            existingClass.trainer?.timezone,
            {
                status: 'BLOCKED',
                isRescheduleProposal: true,
                rescheduleStatus: 'PENDING_MEMBER_APPROVAL',
            },
        );

        const fitnessClass = await this.fitnessClassRepository.requestRescheduleByTrainer(
            id,
            trainerUserId,
            {
                rescheduleStatus: 'PENDING_MEMBER_APPROVAL',
                rescheduleRequestedByUserId: trainerUserId,
                rescheduleRequestedAt: new Date(),
                rescheduleNote: model.note?.trim() || null,
            },
            slots,
        );

        if (!fitnessClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        return this.mapToResponse(fitnessClass);
    }

    async updateForTrainer(
        id: string,
        trainerUserId: string,
        model: UpdateFitnessClassDto,
    ): Promise<FitnessClassResponseDto> {
        const existingClass = await this.fitnessClassRepository.findByIdAndTrainerUserId(id, trainerUserId);
        if (!existingClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        if (existingClass.status === 'CANCELLED') {
            throw new BadRequestAppException('Cancelled classes cannot be edited.', ['CLASS_ALREADY_CANCELLED']);
        }

        if (existingClass.status === 'COMPLETED') {
            throw new BadRequestAppException('Completed classes cannot be edited.', ['CLASS_ALREADY_COMPLETED']);
        }

        const bookingState = await this.fitnessClassRepository.findClassEditBookingState(id, trainerUserId);
        this.validateBookedClassEdit(model, existingClass, bookingState);

        const resolvedSessionPlanType = model.sessionPlanType ?? existingClass.sessionPlanType;
        const resolvedSessionFormat = model.sessionFormat ?? existingClass.sessionFormat;
        const resolvedCapacity = model.sessionFormat === FitnessSessionFormat.PRIVATE
            ? null
            : model.capacity !== undefined
                ? model.capacity
                : existingClass.capacity ?? null;
        const resolvedDurationMinutes = model.durationMinutes ?? existingClass.durationMinutes;

        this.validateSessionFormatCapacity(resolvedSessionFormat as FitnessSessionFormat, resolvedCapacity);

        let slots: any[] | undefined;
        if (model.availableSlots !== undefined) {
            this.validateSlotCountForPlan(resolvedSessionPlanType, model.availableSlots);
            slots = this.buildSlotRecords(trainerUserId, model.availableSlots, resolvedDurationMinutes, existingClass.trainer?.timezone);
        }

        const fitnessClass = await this.fitnessClassRepository.updateByIdAndTrainerUserId(id, trainerUserId, {
            ...(model.name !== undefined ? { name: model.name.trim() } : {}),
            ...(model.classType !== undefined ? { classType: model.classType } : {}),
            ...(model.sessionPlanType !== undefined ? { sessionPlanType: model.sessionPlanType } : {}),
            ...(model.durationMinutes !== undefined ? { durationMinutes: model.durationMinutes } : {}),
            ...(model.pricePerMember !== undefined ? { pricePerMember: model.pricePerMember } : {}),
            ...(model.sessionFormat !== undefined ? { sessionFormat: model.sessionFormat } : {}),
            maxMembers: resolvedCapacity,
        }, slots);

        if (!fitnessClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        return this.mapToResponse(fitnessClass);
    }

    async cancelForTrainer(id: string, trainerUserId: string): Promise<FitnessClassResponseDto> {
        const existingClass = await this.fitnessClassRepository.findByIdAndTrainerUserId(id, trainerUserId);
        if (!existingClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        if (existingClass.status === 'CANCELLED') {
            throw new BadRequestAppException('Class is already cancelled.', ['CLASS_ALREADY_CANCELLED']);
        }

        const bookingState = await this.fitnessClassRepository.findClassEditBookingState(id, trainerUserId);
        if (bookingState.activeBookingCount > 0) {
            throw new BadRequestAppException(
                'Cannot cancel a class that has active member bookings. Please reschedule instead.',
                ['CLASS_HAS_ACTIVE_BOOKINGS'],
            );
        }

        const fitnessClass = await this.fitnessClassRepository.updateByIdAndTrainerUserId(id, trainerUserId, {
            status: 'CANCELLED',
        });

        if (!fitnessClass) {
            throw new NotFoundAppException('Class not found', 'CLASS_NOT_FOUND');
        }

        const memberUserIds = await this.fitnessClassRepository.findActiveMemberIdsByClass(id, trainerUserId);
        await Promise.all(memberUserIds.map((memberUserId) => this.notificationService.notifyUser({
            userId: memberUserId,
            type: NotificationType.CLASS_CANCELLED,
            title: 'Class cancelled',
            body: `${existingClass.name} has been cancelled by your trainer.`,
            data: {
                fitnessClassId: existingClass.id,
            },
        })));

        return this.mapToResponse(fitnessClass);
    }

    private mapToResponse(fitnessClass: any): FitnessClassResponseDto {
        return new FitnessClassResponseDto({
            id: fitnessClass.id,
            trainerUserId: fitnessClass.trainerUserId,
            name: fitnessClass.name,
            scheduledAt: fitnessClass.scheduledAt,
            classType: fitnessClass.classType,
            sessionPlanType: fitnessClass.sessionPlanType,
            durationMinutes: fitnessClass.durationMinutes,
            pricePerMember: fitnessClass.pricePerMember,
            sessionFormat: fitnessClass.sessionFormat,
            capacity: fitnessClass.capacity ?? null,
            status: fitnessClass.status,
            bookedMemberCount: fitnessClass.bookedMemberCount ?? 0,
            joinedMembers: (fitnessClass.joinedMembers ?? []).map((m: any) => new ClassJoinedMemberResponseDto(m)),
            rescheduleStatus: fitnessClass.rescheduleStatus ?? null,
            rescheduleRequestedByUserId: fitnessClass.rescheduleRequestedByUserId ?? null,
            rescheduleRequestedAt: fitnessClass.rescheduleRequestedAt ?? null,
            rescheduleNote: fitnessClass.rescheduleNote ?? null,
            imageUrl: fitnessClass.trainerImageUrl ?? null,
            trainerImageUrl: fitnessClass.trainerImageUrl,
            trainer: new FitnessClassTrainerResponseDto(fitnessClass.trainer),
            availableSlots: (fitnessClass.availableSlots ?? []).map((slot: any) => new FitnessClassAvailabilitySlotResponseDto(slot)),
            bookedSlots: (fitnessClass.bookedSlots ?? []).map((slot: any) => new FitnessClassAvailabilitySlotResponseDto(slot)),
            proposedRescheduleSlots: (fitnessClass.proposedRescheduleSlots ?? []).map((slot: any) => new FitnessClassAvailabilitySlotResponseDto(slot)),
            createdAt: fitnessClass.createdAt,
            updatedAt: fitnessClass.updatedAt,
        });
    }

    private mapBooking(booking: any): BookingResponseDto {
        return new BookingResponseDto({
            id: booking.id,
            memberUserId: booking.memberUserId,
            trainerUserId: booking.trainerUserId,
            fitnessClassId: booking.fitnessClassId,
            availabilitySlotId: booking.availabilitySlotId,
            bookingPaymentId: booking.bookingPaymentId ?? null,
            fullName: booking.fullName,
            email: booking.email,
            phoneNumber: booking.phoneNumber,
            location: booking.location,
            comment: booking.comment ?? null,
            scheduledDate: booking.scheduledDate,
            startTime: booking.startTime,
            endTime: booking.endTime,
            startAt: booking.availabilitySlot?.startAt ?? null,
            endAt: booking.availabilitySlot?.endAt ?? null,
            totalAmount: booking.totalAmount?.toString?.() ?? String(booking.totalAmount),
            bookingStatus: booking.bookingStatus,
            paymentStatus: booking.paymentStatus,
            reservedUntil: booking.reservedUntil ?? null,
            confirmedAt: booking.confirmedAt ?? null,
            rescheduleRequestedByUserId: booking.rescheduleRequestedByUserId ?? null,
            rescheduleRequestedAt: booking.rescheduleRequestedAt ?? null,
            proposedScheduledDate: booking.proposedScheduledDate ?? null,
            proposedStartTime: booking.proposedStartTime ?? null,
            proposedEndTime: booking.proposedEndTime ?? null,
            memberRescheduleAcceptedAt: booking.memberRescheduleAcceptedAt ?? null,
            trainerRescheduleAcceptedAt: booking.trainerRescheduleAcceptedAt ?? null,
            rescheduledAt: booking.rescheduledAt ?? null,
            memberCheckedInAt: booking.memberCheckedInAt ?? null,
            trainerCheckedInAt: booking.trainerCheckedInAt ?? null,
            memberCompletedAt: booking.memberCompletedAt ?? null,
            trainerCompletedAt: booking.trainerCompletedAt ?? null,
            completedAt: booking.completedAt ?? null,
            class: new BookingClassResponseDto({
                id: booking.fitnessClass.id,
                name: booking.fitnessClass.name,
                classType: booking.fitnessClass.classType,
                sessionPlanType: booking.fitnessClass.sessionPlanType,
                durationMinutes: booking.fitnessClass.durationMinutes,
                sessionFormat: booking.fitnessClass.sessionFormat,
                status: booking.fitnessClass.status,
            }),
            trainer: new BookingTrainerResponseDto({
                id: booking.trainer.id,
                name: booking.trainer.displayName ?? booking.trainer.firstName ?? null,
                profileImageUrl: booking.trainer.profileImageUrl ?? null,
                phoneNumber: booking.trainer.phoneNumber ?? null,
            }),
            createdAt: booking.createdAt,
            updatedAt: booking.updatedAt ?? null,
        });
    }

    private async requestBookingReschedule(
        currentUserId: string,
        bookingId: string,
        role: Roles.Member | Roles.Trainer,
        model: BookingRescheduleDto,
    ): Promise<BookingResponseDto> {
        const scheduledDate = model.scheduledDate ?? model.date;
        if (!scheduledDate) {
            throw new BadRequestAppException('Validation failed', ['scheduledDate is required']);
        }

        const result = await this.fitnessClassRepository.requestBookingReschedule(
            bookingId,
            currentUserId,
            role,
            scheduledDate,
            model.startTime,
        );
        this.throwBookingError(result);

        await this.notifyBookingRescheduleRequested(result.booking, role);

        return this.mapBooking(result.booking);
    }

    private async notifyBookingConfirmed(booking: any): Promise<void> {
        const className = booking.fitnessClass?.name ?? 'class';
        await Promise.all([
            this.notificationService.notifyUser({
                userId: booking.memberUserId,
                type: NotificationType.BOOKING_CONFIRMED,
                title: 'Booking confirmed',
                body: `Your ${className} booking is confirmed for ${booking.scheduledDate} at ${booking.startTime}.`,
                data: this.getBookingNotificationData(booking),
            }),
            this.notificationService.notifyUser({
                userId: booking.trainerUserId,
                type: NotificationType.BOOKING_CONFIRMED,
                title: 'New booking confirmed',
                body: `${booking.fullName} booked ${className} for ${booking.scheduledDate} at ${booking.startTime}.`,
                data: this.getBookingNotificationData(booking),
            }),
        ]);
    }

    private async notifyBookingRescheduleRequested(booking: any, requestedByRole: Roles.Member | Roles.Trainer): Promise<void> {
        const recipientUserId = requestedByRole === Roles.Member ? booking.trainerUserId : booking.memberUserId;
        const requester = requestedByRole === Roles.Member ? 'member' : 'trainer';
        await this.notificationService.notifyUser({
            userId: recipientUserId,
            type: NotificationType.BOOKING_RESCHEDULE_REQUESTED,
            title: 'Reschedule requested',
            body: `Your ${requester} requested ${booking.proposedScheduledDate} at ${booking.proposedStartTime}.`,
            data: this.getBookingNotificationData(booking),
        });
    }

    private async notifyBookingRescheduleAccepted(booking: any, acceptedByRole: Roles.Member | Roles.Trainer): Promise<void> {
        const recipientUserId = acceptedByRole === Roles.Member ? booking.trainerUserId : booking.memberUserId;
        const isRescheduled = booking.bookingStatus === 'RESCHEDULED';
        await this.notificationService.notifyUser({
            userId: recipientUserId,
            type: isRescheduled ? NotificationType.BOOKING_RESCHEDULED : NotificationType.BOOKING_RESCHEDULE_REQUESTED,
            title: isRescheduled ? 'Booking rescheduled' : 'Reschedule accepted',
            body: isRescheduled
                ? `Your booking moved to ${booking.scheduledDate} at ${booking.startTime}.`
                : 'The other participant accepted your reschedule request.',
            data: this.getBookingNotificationData(booking),
        });
    }

    private async notifyBookingCompletion(booking: any, completedByRole: Roles.Member | Roles.Trainer): Promise<void> {
        const recipientUserId = completedByRole === Roles.Member ? booking.trainerUserId : booking.memberUserId;
        await this.notificationService.notifyUser({
            userId: recipientUserId,
            type: NotificationType.BOOKING_COMPLETED,
            title: booking.bookingStatus === 'COMPLETED' ? 'Session completed' : 'Completion confirmation needed',
            body: booking.bookingStatus === 'COMPLETED'
                ? 'Your session has been marked complete.'
                : 'The member marked this session complete. Please confirm from your side.',
            data: this.getBookingNotificationData(booking),
        });
    }

    private getBookingNotificationData(booking: any): Record<string, unknown> {
        return {
            bookingId: booking.id,
            fitnessClassId: booking.fitnessClassId,
            availabilitySlotId: booking.availabilitySlotId,
            memberUserId: booking.memberUserId,
            trainerUserId: booking.trainerUserId,
            bookingStatus: booking.bookingStatus,
            paymentStatus: booking.paymentStatus,
        };
    }

    private mapTrainerSchedule(
        startDate: string,
        endDate: string,
        bookings: any[],
    ): TrainerScheduleResponseDto {
        const daysByDate = new Map<string, TrainerScheduleItemResponseDto[]>();

        for (const booking of bookings) {
            const item = new TrainerScheduleItemResponseDto({
                booking: this.mapBooking(booking),
                actions: this.getTrainerScheduleActions(booking),
            });
            const dayItems = daysByDate.get(booking.scheduledDate) ?? [];
            dayItems.push(item);
            daysByDate.set(booking.scheduledDate, dayItems);
        }

        const days = Array.from(daysByDate.entries())
            .sort(([firstDate], [secondDate]) => firstDate.localeCompare(secondDate))
            .map(([date, items]) => new TrainerScheduleDayResponseDto({
                date,
                totalCount: items.length,
                completedCount: items.filter((item) => item.booking.bookingStatus === 'COMPLETED').length,
                upcomingCount: items.filter((item) => item.booking.bookingStatus !== 'COMPLETED').length,
                items,
            }));

        return new TrainerScheduleResponseDto({
            startDate,
            endDate,
            days,
        });
    }

    private getTrainerScheduleActions(booking: any): TrainerScheduleActionsResponseDto {
        const now = new Date();
        const startAt = booking.availabilitySlot?.startAt
            ? new Date(booking.availabilitySlot.startAt)
            : this.buildSlotDateTime(booking.scheduledDate, booking.startTime, booking.trainer?.timezone);
        const endAt = booking.availabilitySlot?.endAt
            ? new Date(booking.availabilitySlot.endAt)
            : this.buildSlotDateTime(booking.scheduledDate, booking.endTime, booking.trainer?.timezone);
        const isActive = ['CONFIRMED', 'RESCHEDULED'].includes(booking.bookingStatus);
        const isReschedulePending = booking.bookingStatus === 'RESCHEDULE_REQUESTED';
        const canAcceptReschedule = isReschedulePending
            && booking.rescheduleRequestedByUserId !== booking.trainerUserId
            && !booking.trainerRescheduleAcceptedAt;
        const canCheckIn = isActive
            && startAt <= now
            && !booking.trainerCheckedInAt
            && Boolean(booking.memberCheckedInAt);
        const canReschedule = isActive && startAt > now;
        const canMarkComplete = (isActive || (booking.bookingStatus === 'COMPLETED' && !booking.completedAt))
            && endAt <= now
            && Boolean(booking.memberCompletedAt)
            && !booking.trainerCompletedAt;

        let label = 'Upcoming';
        if (booking.bookingStatus === 'COMPLETED') {
            label = 'Completed';
        } else if (canMarkComplete) {
            label = 'Mark as complete';
        } else if (canCheckIn) {
            label = 'Check in';
        } else if (isReschedulePending) {
            label = canAcceptReschedule ? 'Accept reschedule' : 'Reschedule pending';
        } else if (startAt <= now && endAt > now) {
            label = 'In progress';
        }

        return new TrainerScheduleActionsResponseDto({
            canCheckIn,
            canReschedule,
            canAcceptReschedule,
            canMarkComplete,
            label,
        });
    }

    private resolveScheduleDateRange(query: { date?: string; startDate?: string; endDate?: string }): { startDate: string; endDate: string } {
        const today = new Date().toISOString().slice(0, 10);
        const startDate = query.date ?? query.startDate ?? today;
        const endDate = query.date ?? query.endDate ?? startDate;

        if (endDate < startDate) {
            throw new BadRequestAppException('endDate must be on or after startDate.', ['INVALID_DATE_RANGE']);
        }

        return { startDate, endDate };
    }

    private mapNextWorkout(booking: any): MemberNextWorkoutResponseDto {
        const trainer = booking.trainer;
        const trainerProfile = trainer?.trainerProfile;
        const reviewRatings = (trainer?.trainerReviews ?? []).map((review: any) => Number(review.rating));
        const averageRating = reviewRatings.length
            ? Number((reviewRatings.reduce((sum: number, rating: number) => sum + rating, 0) / reviewRatings.length).toFixed(2))
            : null;
        const distanceMeters = this.calculateDistanceMeters(
            booking.member?.currentLat,
            booking.member?.currentLng,
            trainerProfile?.isOnline && trainerProfile?.liveLocationLat != null && trainerProfile?.liveLocationLng != null
                ? trainerProfile.liveLocationLat
                : trainerProfile?.baseLocationLat,
            trainerProfile?.isOnline && trainerProfile?.liveLocationLat != null && trainerProfile?.liveLocationLng != null
                ? trainerProfile.liveLocationLng
                : trainerProfile?.baseLocationLng,
        );

        return new MemberNextWorkoutResponseDto({
            bookingId: booking.id,
            fitnessClassId: booking.fitnessClassId,
            availabilitySlotId: booking.availabilitySlotId,
            bookingStatus: booking.bookingStatus,
            paymentStatus: booking.paymentStatus,
            class: new MemberNextWorkoutClassResponseDto({
                id: booking.fitnessClass.id,
                name: booking.fitnessClass.name,
                classType: booking.fitnessClass.classType,
                sessionPlanType: booking.fitnessClass.sessionPlanType,
                durationMinutes: booking.fitnessClass.durationMinutes,
                sessionFormat: booking.fitnessClass.sessionFormat,
            }),
            trainer: new MemberNextWorkoutTrainerResponseDto({
                id: trainer.id,
                name: trainer.displayName ?? trainer.firstName ?? null,
                profileImageUrl: trainer.profileImageUrl ?? null,
                phoneNumber: trainer.phoneNumber ?? null,
                classesTaught: trainerProfile?.classesTaught ?? null,
                averageRating,
                reviewCount: reviewRatings.length,
                distanceMeters,
                locationLabel: distanceMeters != null ? (trainerProfile?.isOnline ? 'Active Now' : 'Based Nearby') : (trainer.location ?? null),
            }),
            locationTime: new MemberNextWorkoutLocationTimeResponseDto({
                location: booking.location ?? trainer.location ?? null,
                scheduledDate: booking.scheduledDate,
                startTime: booking.startTime,
                endTime: booking.endTime,
                startAt: booking.availabilitySlot?.startAt ?? this.buildSlotDateTime(booking.scheduledDate, booking.startTime),
                endAt: booking.availabilitySlot?.endAt ?? this.buildSlotDateTime(booking.scheduledDate, booking.endTime),
            }),
            totalAmount: booking.totalAmount?.toString?.() ?? String(booking.totalAmount),
            confirmedAt: booking.confirmedAt ?? null,
            rescheduleRequestedByUserId: booking.rescheduleRequestedByUserId ?? null,
            rescheduleRequestedAt: booking.rescheduleRequestedAt ?? null,
            proposedScheduledDate: booking.proposedScheduledDate ?? null,
            proposedStartTime: booking.proposedStartTime ?? null,
            proposedEndTime: booking.proposedEndTime ?? null,
            memberRescheduleAcceptedAt: booking.memberRescheduleAcceptedAt ?? null,
            trainerRescheduleAcceptedAt: booking.trainerRescheduleAcceptedAt ?? null,
            rescheduledAt: booking.rescheduledAt ?? null,
            memberCheckedInAt: booking.memberCheckedInAt ?? null,
            trainerCheckedInAt: booking.trainerCheckedInAt ?? null,
            memberCompletedAt: booking.memberCompletedAt ?? null,
            trainerCompletedAt: booking.trainerCompletedAt ?? null,
            completedAt: booking.completedAt ?? null,
            actions: this.getMemberWorkoutActions(booking),
        });
    }

    private getMemberCancelRefundPercent(booking: any): number {
        const startAt = booking.availabilitySlot?.startAt
            ? new Date(booking.availabilitySlot.startAt)
            : this.buildSlotDateTime(booking.scheduledDate, booking.startTime);
        const hoursUntilClass = (startAt.getTime() - Date.now()) / (1000 * 60 * 60);
        if (hoursUntilClass > 48) return 1.0;
        if (hoursUntilClass > 24) return 0.5;
        return 0;
    }

    private getMemberWorkoutActions(booking: any): MemberWorkoutActionsResponseDto {
        const now = new Date();
        const startAt = booking.availabilitySlot?.startAt
            ? new Date(booking.availabilitySlot.startAt)
            : this.buildSlotDateTime(booking.scheduledDate, booking.startTime);
        const endAt = booking.availabilitySlot?.endAt
            ? new Date(booking.availabilitySlot.endAt)
            : this.buildSlotDateTime(booking.scheduledDate, booking.endTime);
        const isActive = ['CONFIRMED', 'RESCHEDULED'].includes(booking.bookingStatus);
        const isReschedulePending = booking.bookingStatus === 'RESCHEDULE_REQUESTED';
        const canAcceptReschedule = isReschedulePending
            && booking.rescheduleRequestedByUserId !== booking.memberUserId
            && !booking.memberRescheduleAcceptedAt;
        const canCheckIn = isActive
            && startAt <= now
            && !booking.memberCheckedInAt;
        const canReschedule = isActive && startAt > now;
        const canMarkComplete = isActive
            && endAt <= now
            && !booking.memberCompletedAt;

        let label = 'Upcoming';
        if (booking.bookingStatus === 'COMPLETED') {
            label = 'Completed';
        } else if (canMarkComplete) {
            label = 'Mark as complete';
        } else if (canCheckIn) {
            label = 'Check in';
        } else if (isReschedulePending) {
            label = canAcceptReschedule ? 'Accept reschedule' : 'Reschedule pending';
        } else if (startAt <= now && endAt > now) {
            label = 'In progress';
        }

        return new MemberWorkoutActionsResponseDto({
            canCheckIn,
            canReschedule,
            canAcceptReschedule,
            canMarkComplete,
            label,
        });
    }

    private mapPaymentSummary(payment: any, requestedCouponCode?: string): BookingPaymentSummaryResponseDto {
        return new BookingPaymentSummaryResponseDto({
            id: payment.id,
            subtotalAmount: payment.subtotalAmount?.toString?.() ?? String(payment.subtotalAmount),
            discountAmount: payment.discountAmount?.toString?.() ?? String(payment.discountAmount ?? 0),
            taxAmount: payment.taxAmount?.toString?.() ?? String(payment.taxAmount ?? 0),
            totalAmount: payment.totalAmount?.toString?.() ?? String(payment.totalAmount),
            currency: payment.currency ?? 'USD',
            couponCode: requestedCouponCode?.trim() || payment.couponCode || null,
            couponPlaceholder: Boolean(requestedCouponCode?.trim()),
            status: payment.status,
            expiresAt: payment.expiresAt,
        });
    }

    private mapToTrainerAvailabilityCalendar(
        trainerUserId: string,
        month: string,
        startDate: string,
        endDate: string,
        slots: any[],
    ): TrainerAvailabilityCalendarResponseDto {
        const daysByDate = new Map<string, TrainerAvailabilitySlotResponseDto[]>();

        for (const slot of slots) {
            const responseSlot = new TrainerAvailabilitySlotResponseDto({
                id: slot.id,
                fitnessClassId: slot.fitnessClassId,
                className: slot.fitnessClass.name,
                classType: slot.fitnessClass.classType,
                sessionPlanType: slot.fitnessClass.sessionPlanType,
                sessionFormat: slot.fitnessClass.sessionFormat,
                durationMinutes: slot.fitnessClass.durationMinutes,
                pricePerMember: slot.fitnessClass.pricePerMember?.toString?.() ?? String(slot.fitnessClass.pricePerMember),
                date: slot.date,
                startTime: slot.startTime,
                endTime: slot.endTime,
                startAt: slot.startAt,
                endAt: slot.endAt,
                status: slot.status,
                availabilityStatus: slot.availabilityStatus,
                bookedCount: slot.bookedCount,
                heldCount: slot.heldCount,
                capacity: slot.capacity,
                spotsRemaining: slot.spotsRemaining,
            });

            const daySlots = daysByDate.get(slot.date) ?? [];
            daySlots.push(responseSlot);
            daysByDate.set(slot.date, daySlots);
        }

        const days = Array.from(daysByDate.entries())
            .sort(([firstDate], [secondDate]) => firstDate.localeCompare(secondDate))
            .map(([date, daySlots]) => {
                const availableSlotCount = daySlots.filter((slot) => slot.availabilityStatus === 'AVAILABLE').length;
                const bookedSlotCount = daySlots.filter((slot) => slot.availabilityStatus === 'BOOKED').length;
                const heldSlotCount = daySlots.filter((slot) => slot.availabilityStatus === 'HELD').length;
                const blockedSlotCount = daySlots.filter((slot) => slot.availabilityStatus === 'BLOCKED').length;
                const isAvailable = availableSlotCount > 0;

                return new TrainerAvailabilityDayResponseDto({
                    date,
                    day: Number(date.slice(8, 10)),
                    status: isAvailable ? 'AVAILABLE' : 'BOOKED',
                    isAvailable,
                    totalSlotCount: daySlots.length,
                    availableSlotCount,
                    bookedSlotCount,
                    heldSlotCount,
                    blockedSlotCount,
                    slots: daySlots,
                });
            });

        return new TrainerAvailabilityCalendarResponseDto({
            trainerUserId,
            month,
            startDate,
            endDate,
            days,
        });
    }

    private validateSessionFormatCapacity(sessionFormat: FitnessSessionFormat, capacity?: number | null): void {
        if (sessionFormat === FitnessSessionFormat.GROUP && capacity == null) {
            throw new BadRequestAppException('Capacity is required for group sessions.', ['CAPACITY_REQUIRED']);
        }

        if (sessionFormat === FitnessSessionFormat.PRIVATE && capacity != null) {
            throw new BadRequestAppException('Capacity is only allowed for group sessions.', ['CAPACITY_NOT_ALLOWED']);
        }
    }

    private validateBookedClassEdit(
        model: UpdateFitnessClassDto,
        existingClass: FitnessClassEntity,
        bookingState: { activeBookingCount: number; pendingReservationCount: number; bookedMemberCount: number },
    ): void {
        const hasBookingsOrReservations = bookingState.activeBookingCount > 0 || bookingState.pendingReservationCount > 0;
        if (!hasBookingsOrReservations) return;

        const protectedChanges = this.getProtectedClassEditFields(model, existingClass);
        if (!protectedChanges.length) return;

        if (bookingState.pendingReservationCount > 0 && bookingState.activeBookingCount === 0) {
            throw new BadRequestAppException(
                'This class has pending booking reservations and cannot be edited right now.',
                ['CLASS_HAS_PENDING_RESERVATIONS', ...protectedChanges],
            );
        }

        throw new BadRequestAppException(
            'Booked classes cannot be edited directly. Please request a reschedule instead.',
            ['CLASS_HAS_ACTIVE_BOOKINGS', ...protectedChanges],
        );
    }

    private getProtectedClassEditFields(
        model: UpdateFitnessClassDto,
        existingClass: FitnessClassEntity,
    ): string[] {
        const protectedChanges: string[] = [];

        if (model.availableSlots !== undefined) {
            protectedChanges.push('AVAILABLE_SLOTS_LOCKED');
        }

        if (model.sessionPlanType !== undefined && model.sessionPlanType !== existingClass.sessionPlanType) {
            protectedChanges.push('SESSION_PLAN_TYPE_LOCKED');
        }

        if (model.durationMinutes !== undefined && model.durationMinutes !== existingClass.durationMinutes) {
            protectedChanges.push('DURATION_LOCKED');
        }

        if (
            model.pricePerMember !== undefined
            && Number(model.pricePerMember) !== Number(existingClass.pricePerMember)
        ) {
            protectedChanges.push('PRICE_LOCKED');
        }

        if (model.sessionFormat !== undefined && model.sessionFormat !== existingClass.sessionFormat) {
            protectedChanges.push('SESSION_FORMAT_LOCKED');
        }

        if (model.capacity !== undefined && model.capacity !== (existingClass.capacity ?? null)) {
            protectedChanges.push('CAPACITY_LOCKED');
        }

        return protectedChanges;
    }

    private validateSlotCountForPlan(sessionPlanType: string, slots: AvailabilitySlotDto[]): void {
        if (!slots?.length) {
            throw new BadRequestAppException('At least one available slot is required.', ['CLASS_SLOT_REQUIRED']);
        }

        if (sessionPlanType === 'SINGLE_SESSION' && slots.length !== 1) {
            throw new BadRequestAppException('Single session classes must have exactly one slot.', ['SINGLE_SESSION_ONLY_ONE_SLOT']);
        }
    }

    private buildSlotRecords(
        trainerUserId: string,
        slots: AvailabilitySlotDto[],
        durationMinutes: number,
        timeZone?: string | null,
        overrides: Record<string, unknown> = {},
    ): any[] {
        return slots.map((slot) => {
            const startAt = this.buildSlotDateTime(slot.date, slot.startTime, timeZone);
            const endAt = this.buildSlotDateTime(slot.date, slot.endTime, timeZone);
            const duration = (endAt.getTime() - startAt.getTime()) / 60000;

            if (endAt <= startAt) {
                throw new BadRequestAppException('Slot end time must be after start time.', ['INVALID_SLOT_TIME_RANGE']);
            }

            if (duration !== durationMinutes) {
                throw new BadRequestAppException('Slot duration must match class duration.', ['SLOT_DURATION_MISMATCH']);
            }

            return {
                trainerUserId,
                date: slot.date,
                startTime: slot.startTime,
                endTime: slot.endTime,
                startAt,
                endAt,
                status: 'AVAILABLE',
                ...overrides,
            };
        });
    }

    private buildSlotDateTime(date: string, time: string, timeZone?: string | null): Date {
        return DateTimeUtils.fromLocalDateTime(date, time, timeZone);
    }

    private getRequestedSlotIds(model: CreateClassBookingDto): string[] {
        const ids = model.availabilitySlotIds?.length
            ? model.availabilitySlotIds
            : model.availabilitySlotId
                ? [model.availabilitySlotId]
                : [];

        return Array.from(new Set(ids));
    }

    private validateRequestedSlotsForBooking(fitnessClass: FitnessClassEntity, requestedSlotIds: string[]): void {
        const slotsById = new Map((fitnessClass.availableSlots ?? []).map((slot: any) => [slot.id, slot]));
        const missingSlotIds = requestedSlotIds.filter((slotId) => !slotsById.has(slotId));
        if (missingSlotIds.length) {
            throw new BadRequestAppException(
                'Selected slot does not belong to this class.',
                ['CLASS_SLOT_MISMATCH', ...missingSlotIds],
            );
        }

        const now = new Date();
        const pastSlotIds = requestedSlotIds.filter((slotId) => {
            const slot: any = slotsById.get(slotId);
            return slot.startAt && new Date(slot.startAt) < now;
        });
        if (pastSlotIds.length) {
            throw new BadRequestAppException(
                'Selected slot has already passed.',
                ['CLASS_SLOT_PAST', ...pastSlotIds],
            );
        }

        const unavailableSlotIds = requestedSlotIds.filter((slotId) => {
            const slot: any = slotsById.get(slotId);
            return slot.availabilityStatus !== 'AVAILABLE' || (slot.spotsRemaining !== null && slot.spotsRemaining <= 0);
        });
        if (unavailableSlotIds.length) {
            throw new BadRequestAppException(
                'Selected slot is not available.',
                ['CLASS_SLOT_UNAVAILABLE', ...unavailableSlotIds],
            );
        }
    }

    private throwBookingError(result?: any): void {
        const error = result?.error;
        if (!error) return;

        const notFoundErrors = new Set(['CLASS_OR_SLOT_NOT_FOUND', 'BOOKING_NOT_FOUND', 'PAYMENT_NOT_FOUND']);
        if (notFoundErrors.has(error)) {
            throw new NotFoundAppException('Booking resource not found.', error);
        }

        const messages: Record<string, string> = {
            TRAINER_NOT_APPROVED: 'Trainer is not approved.',
            TRAINER_PAYOUT_NOT_READY: 'This trainer has not completed payout setup and cannot accept bookings at this time.',
            SLOT_NOT_AVAILABLE: 'Selected slot is not available.',
            SLOT_FULL: 'Selected slot is full.',
            DUPLICATE_BOOKING: 'You already have a booking for one of these slots.',
            BOOKING_CONFLICT: 'This slot was just booked by someone else. Please try another slot.',
            PAYMENT_EXPIRED: 'Booking payment reservation has expired.',
            BOOKING_NOT_RESCHEDULABLE: 'Booking cannot be rescheduled.',
            INVALID_RESCHEDULE_TIME: 'Reschedule time must be in the future.',
            RESCHEDULE_NOT_REQUESTED: 'No reschedule request is pending for this booking.',
            RESCHEDULE_CONFLICT: 'Reschedule slot was just booked by someone else.',
            BOOKING_NOT_CHECK_IN_ELIGIBLE: 'Booking cannot be checked in.',
            BOOKING_NOT_STARTED: result.startTime
                ? `Booking session has not started yet. It starts at ${result.startTime} on ${result.scheduledDate}.`
                : 'Booking session has not started yet.',
            BOOKING_ALREADY_COMPLETED: 'Booking is already completed.',
            TRAINER_CHECK_IN_NOT_ELIGIBLE: 'Trainer can check in only after the member checks in.',
            BOOKING_NOT_CANCELLABLE: 'Booking cannot be cancelled.',
            BOOKING_ALREADY_CANCELLED: 'Booking is already cancelled.',
            RESCHEDULE_REJECT_NOT_ELIGIBLE: 'No pending reschedule request from trainer to reject.',
            BOOKING_NOT_COMPLETABLE: 'Booking cannot be completed.',
            BOOKING_NOT_ENDED: result.endTime 
                ? `Booking session has not ended yet. It ends at ${result.endTime} on ${result.scheduledDate}.` 
                : 'Booking session has not ended yet.',
            TRAINER_NOT_ELIGIBLE: 'Trainer can complete only after member marks the booking complete.',
        };

        throw new BadRequestAppException(messages[error] ?? 'Booking request could not be completed.', [error]);
    }

    private toStripeAmount(amount: any): number {
        return Math.round(Number(amount) * 100);
    }

    private calculateDistanceMeters(
        originLat?: number | null,
        originLng?: number | null,
        targetLat?: number | null,
        targetLng?: number | null,
    ): number | null {
        if (originLat == null || originLng == null || targetLat == null || targetLng == null) {
            return null;
        }

        const toRadians = (value: number) => (value * Math.PI) / 180;
        const earthRadiusMeters = 6371000;
        const dLat = toRadians(targetLat - originLat);
        const dLng = toRadians(targetLng - originLng);
        const lat1 = toRadians(originLat);
        const lat2 = toRadians(targetLat);

        const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return Math.round(earthRadiusMeters * c);
    }

    private getMonthDateRange(month: string): { startDate: string; endDate: string } {
        const [yearValue, monthValue] = month.split('-').map(Number);
        const endDay = new Date(Date.UTC(yearValue, monthValue, 0)).getUTCDate();

        return {
            startDate: `${month}-01`,
            endDate: `${month}-${String(endDay).padStart(2, '0')}`,
        };
    }

}
