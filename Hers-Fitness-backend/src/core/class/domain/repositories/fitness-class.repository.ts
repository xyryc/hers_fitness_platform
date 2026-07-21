import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { CreateFitnessClassDto } from '../../dto/create-fitness-class.dto';
import { FitnessClassEntity } from '../entities/fitness-class.entity';
import { Roles } from 'src/common/enums/roles.enum';
import { DateTimeUtils } from 'src/utils/date-time.utils';
import { AdminRepository } from 'src/core/admin/domain/admin.repository';

@Injectable()
export class FitnessClassRepository {
    constructor(
        private readonly prisma: PrismaService,
        private readonly adminRepository: AdminRepository,
    ) { }

    /** Calculate platform fee and trainer payout given a total and commission rate (%). */
    private applyCommission(totalAmount: number, commissionRate: number): {
        platformFeeAmount: number;
        trainerPayoutAmount: number;
    } {
        const platformFeeAmount = this.roundMoney(totalAmount * commissionRate / 100);
        const trainerPayoutAmount = this.roundMoney(totalAmount - platformFeeAmount);
        return { platformFeeAmount, trainerPayoutAmount };
    }

    private readonly reservationMinutes = 10;
    private readonly activeBookingStatuses = ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED'];
    private readonly slotOccupyingBookingStatuses = ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'];
    private readonly completableBookingStatuses = ['CONFIRMED', 'RESCHEDULED'];
    private readonly memberBookedClassStatuses = ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'];
    private readonly scheduleBookingStatuses = ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'];

    private getIncludePattern() {
        return {
            trainer: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                    timezone: true,
                },
            },
            availabilitySlots: {
                orderBy: {
                    startAt: 'asc',
                },
                include: {
                    _count: {
                        select: {
                            bookings: true,
                        },
                    },
                    bookings: {
                        select: {
                            memberUserId: true,
                            bookingStatus: true,
                            paymentStatus: true,
                            reservedUntil: true,
                        },
                    },
                },
            },
            bookings: {
                where: {
                    bookingStatus: {
                        in: ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'],
                    },
                    paymentStatus: 'PAID',
                },
                select: {
                    id: true,
                    memberUserId: true,
                    bookingStatus: true,
                    paymentStatus: true,
                    scheduledDate: true,
                    startTime: true,
                    endTime: true,
                    memberCheckedInAt: true,
                    memberCompletedAt: true,
                    completedAt: true,
                    member: {
                        select: {
                            id: true,
                            displayName: true,
                            firstName: true,
                            profileImageUrl: true,
                        },
                    },
                },
                orderBy: {
                    createdAt: 'asc',
                },
            },
        };
    }

    private getBookableIncludePattern(now: Date) {
        return {
            trainer: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                    timezone: true,
                },
            },
            availabilitySlots: {
                where: {
                    startAt: {
                        gte: now,
                    },
                },
                orderBy: {
                    startAt: 'asc',
                },
                include: {
                    _count: {
                        select: {
                            bookings: true,
                        },
                    },
                    bookings: {
                        select: {
                            memberUserId: true,
                            bookingStatus: true,
                            paymentStatus: true,
                            reservedUntil: true,
                        },
                    },
                },
            },
            bookings: {
                select: {
                    memberUserId: true,
                    bookingStatus: true,
                    paymentStatus: true,
                },
            },
        };
    }

    async create(trainerUserId: string, model: CreateFitnessClassDto, slots: any[]): Promise<FitnessClassEntity> {
        const fitnessClass = await (this.prisma as any).$transaction(async (tx: any) => {
            const createdClass = await tx.fitnessClass.create({
                data: {
                    trainerUserId,
                    name: model.name.trim(),
                    classType: model.classType,
                    sessionPlanType: model.sessionPlanType ?? 'SINGLE_SESSION',
                    durationMinutes: model.durationMinutes,
                    pricePerMember: model.pricePerMember,
                    sessionFormat: model.sessionFormat,
                    maxMembers: model.capacity ?? null,
                    status: 'ACTIVE',
                    availabilitySlots: {
                        create: slots,
                    },
                },
                include: this.getIncludePattern(),
            });

            return createdClass;
        });

        return this.mapToEntity(fitnessClass);
    }

    async findAll(): Promise<FitnessClassEntity[]> {
        await this.expireHeldBookings();

        const fitnessClasses = await (this.prisma as any).fitnessClass.findMany({
            where: {
                status: 'ACTIVE',
            },
            include: this.getIncludePattern(),
            orderBy: {
                createdAt: 'desc',
            },
        });

        return fitnessClasses.map((fitnessClass: any) => {
            const mappedClass = this.mapToEntity(fitnessClass);
            return {
                ...mappedClass,
                availableSlots: mappedClass.availableSlots.filter((slot) => slot.availabilityStatus === 'AVAILABLE'),
            };
        });
    }

    async findByTrainerUserId(trainerUserId: string, date?: string, includeCompleted = false): Promise<FitnessClassEntity[]> {
        await this.expireHeldBookings();
        await this.autoCompleteExpiredClasses();

        const statusFilter = includeCompleted
            ? { in: ['ACTIVE', 'COMPLETED'] }
            : 'ACTIVE';

        const where: any = { trainerUserId, status: statusFilter };
        if (date) {
            where.availabilitySlots = { some: { date } };
        }

        const fitnessClasses = await (this.prisma as any).fitnessClass.findMany({
            where,
            include: this.getIncludePattern(),
            orderBy: { createdAt: 'desc' },
        });

        return fitnessClasses.map((fitnessClass: any) => this.mapToEntity(fitnessClass));
    }

    async findTrainerDashboardStats(trainerUserId: string): Promise<{
        totalClasses: number;
        totalAttendance: number;
        totalRevenue: number;
        overallRating: number | null;
    }> {
        const paidBookingWhere = {
            trainerUserId,
            paymentStatus: 'PAID',
            bookingStatus: { in: ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'] },
        };

        const [totalClasses, totalAttendance, paidBookings, ratingAggregate] = await Promise.all([
            (this.prisma as any).fitnessClass.count({
                where: {
                    trainerUserId,
                    status: { in: ['ACTIVE', 'COMPLETED'] },
                },
            }),
            (this.prisma as any).booking.count({
                where: paidBookingWhere,
            }),
            // Sum trainerPayoutAmount from BookingPayment (net earnings after commission).
            // Fall back to booking.totalAmount for rows created before the commission feature.
            (this.prisma as any).booking.findMany({
                where: paidBookingWhere,
                select: {
                    totalAmount: true,
                    bookingPayment: {
                        select: { trainerPayoutAmount: true, commissionRate: true },
                    },
                },
            }),
            (this.prisma as any).trainerReview.aggregate({
                where: { trainerUserId },
                _avg: { rating: true },
            }),
        ]);

        const overallRating = ratingAggregate._avg?.rating != null
            ? Number(Number(ratingAggregate._avg.rating).toFixed(2))
            : null;

        // Use trainerPayoutAmount when it is available (commission feature enabled),
        // otherwise fall back to the raw booking amount (pre-commission rows).
        const totalRevenue = Number(
            paidBookings.reduce((sum: number, b: any) => {
                const payout = Number(b.bookingPayment?.trainerPayoutAmount ?? 0);
                return sum + (payout > 0 ? payout : Number(b.totalAmount));
            }, 0).toFixed(2),
        );

        return { totalClasses, totalAttendance, totalRevenue, overallRating };
    }

    async findTrainerEarningsData(trainerUserId: string): Promise<{ scheduledDate: string; totalAmount: any }[]> {
        const bookings = await (this.prisma as any).booking.findMany({
            where: {
                trainerUserId,
                paymentStatus: 'PAID',
                bookingStatus: { in: ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'] },
            },
            select: {
                scheduledDate: true,
                totalAmount: true,
                bookingPayment: {
                    select: { trainerPayoutAmount: true },
                },
            },
        });

        // Normalise: use payout amount (net) when available, else gross booking amount.
        return bookings.map((b: any) => {
            const payout = Number(b.bookingPayment?.trainerPayoutAmount ?? 0);
            return {
                scheduledDate: b.scheduledDate,
                totalAmount: payout > 0 ? payout : b.totalAmount,
            };
        });
    }

    async findTrainerTopClasses(trainerUserId: string, limit = 5): Promise<any[]> {
        const classes = await (this.prisma as any).fitnessClass.findMany({
            where: {
                trainerUserId,
                status: { in: ['ACTIVE', 'COMPLETED'] },
            },
            select: {
                id: true,
                name: true,
                classType: true,
                sessionFormat: true,
                bookings: {
                    where: {
                        paymentStatus: 'PAID',
                        bookingStatus: { in: this.slotOccupyingBookingStatuses },
                    },
                    select: {
                        totalAmount: true,
                        bookingPayment: { select: { trainerPayoutAmount: true } },
                    },
                },
            },
        });

        return classes
            .map((c: any) => ({
                id: c.id,
                name: c.name,
                classType: c.classType,
                sessionFormat: c.sessionFormat,
                bookingCount: c.bookings.length,
                totalRevenue: Number(
                    c.bookings.reduce((sum: number, b: any) => {
                        const payout = Number(b.bookingPayment?.trainerPayoutAmount ?? 0);
                        return sum + (payout > 0 ? payout : Number(b.totalAmount));
                    }, 0).toFixed(2),
                ),
            }))
            .sort((a: any, b: any) => b.bookingCount - a.bookingCount || b.totalRevenue - a.totalRevenue)
            .slice(0, limit);
    }

    async findAvailableForMember(): Promise<FitnessClassEntity[]> {
        await this.expireHeldBookings();
        const now = new Date();

        const fitnessClasses = await (this.prisma as any).fitnessClass.findMany({
            where: {
                status: 'ACTIVE',
                trainer: {
                    verification: {
                        verificationStatus: 'APPROVED',
                    },
                },
                availabilitySlots: {
                    some: {
                        status: 'AVAILABLE',
                        startAt: {
                            gte: now,
                        },
                    },
                },
            },
            include: this.getBookableIncludePattern(now),
            orderBy: {
                createdAt: 'desc',
            },
        });

        return fitnessClasses.map((fitnessClass: any) => this.mapToEntity(fitnessClass));
    }

    async findTrainerAvailabilitySlots(
        trainerUserId: string,
        startDate: string,
        endDate: string,
    ): Promise<any[]> {
        await this.expireHeldBookings();
        const now = new Date();

        const slots = await (this.prisma as any).fitnessClassAvailabilitySlot.findMany({
            where: {
                trainerUserId,
                date: {
                    gte: startDate,
                    lte: endDate,
                },
                isRescheduleProposal: false,
                status: {
                    not: 'CANCELLED',
                },
                fitnessClass: {
                    status: 'ACTIVE',
                    trainer: {
                        verification: {
                            verificationStatus: 'APPROVED',
                        },
                    },
                },
            },
            include: {
                fitnessClass: {
                    select: {
                        id: true,
                        name: true,
                        classType: true,
                        sessionPlanType: true,
                        durationMinutes: true,
                        pricePerMember: true,
                        sessionFormat: true,
                        maxMembers: true,
                    },
                },
                bookings: {
                    where: {
                        OR: [
                            { bookingStatus: { in: this.slotOccupyingBookingStatuses } },
                            {
                                bookingStatus: 'HELD',
                                reservedUntil: {
                                    gt: now,
                                },
                            },
                        ],
                    },
                    select: {
                        bookingStatus: true,
                        reservedUntil: true,
                    },
                },
            },
            orderBy: [
                { startAt: 'asc' },
                { createdAt: 'asc' },
            ],
        });

        return slots.map((slot: any) => {
            const maxBookings = this.getMaxBookingsForClass(slot.fitnessClass);
            const bookings = slot.bookings ?? [];
            const bookedCount = bookings.filter((booking: any) => this.slotOccupyingBookingStatuses.includes(booking.bookingStatus)).length;
            const heldCount = bookings.filter((booking: any) =>
                booking.bookingStatus === 'HELD' && booking.reservedUntil && booking.reservedUntil > now,
            ).length;
            const activeCount = bookedCount + heldCount;

            return {
                ...slot,
                availabilityStatus: this.getSlotAvailabilityStatus(slot.status, bookedCount, heldCount, maxBookings),
                bookedCount,
                heldCount,
                capacity: maxBookings,
                spotsRemaining: Math.max(maxBookings - activeCount, 0),
            };
        });
    }

    async findById(id: string): Promise<FitnessClassEntity | null> {
        await this.expireHeldBookings();

        const fitnessClass = await (this.prisma as any).fitnessClass.findUnique({
            where: { id },
            include: this.getIncludePattern(),
        });

        return fitnessClass ? this.mapToEntity(fitnessClass) : null;
    }

    async findByIdAndTrainerUserId(id: string, trainerUserId: string): Promise<FitnessClassEntity | null> {
        await this.expireHeldBookings();

        const fitnessClass = await (this.prisma as any).fitnessClass.findFirst({
            where: {
                id,
                trainerUserId,
            },
            include: this.getIncludePattern(),
        });

        return fitnessClass ? this.mapToEntity(fitnessClass) : null;
    }

    async findActiveMemberIdsByClass(id: string, trainerUserId: string): Promise<string[]> {
        const bookings = await (this.prisma as any).booking.findMany({
            where: {
                fitnessClassId: id,
                trainerUserId,
                bookingStatus: {
                    in: this.activeBookingStatuses,
                },
            },
            select: {
                memberUserId: true,
            },
        });

        return Array.from(new Set(bookings.map((booking: any) => booking.memberUserId)));
    }

    async findClassEditBookingState(id: string, trainerUserId: string): Promise<{
        activeBookingCount: number;
        pendingReservationCount: number;
        bookedMemberCount: number;
    }> {
        await this.expireHeldBookings();
        const now = new Date();

        const bookings = await (this.prisma as any).booking.findMany({
            where: {
                fitnessClassId: id,
                trainerUserId,
                OR: [
                    {
                        bookingStatus: {
                            in: this.slotOccupyingBookingStatuses,
                        },
                    },
                    {
                        bookingStatus: 'HELD',
                        reservedUntil: {
                            gt: now,
                        },
                    },
                ],
            },
            select: {
                memberUserId: true,
                bookingStatus: true,
                paymentStatus: true,
            },
        });

        const activeBookings = bookings.filter((booking: any) =>
            this.slotOccupyingBookingStatuses.includes(booking.bookingStatus),
        );

        return {
            activeBookingCount: activeBookings.length,
            pendingReservationCount: bookings.filter((booking: any) => booking.bookingStatus === 'HELD').length,
            bookedMemberCount: this.getBookedMemberCount(activeBookings),
        };
    }

    async updateByIdAndTrainerUserId(
        id: string,
        trainerUserId: string,
        data: Record<string, unknown>,
        slots?: any[],
    ): Promise<FitnessClassEntity | null> {
        const fitnessClass = await (this.prisma as any).$transaction(async (tx: any) => {
            const updateResult = await tx.fitnessClass.updateMany({
                where: {
                    id,
                    trainerUserId,
                },
                data,
            });

            if (updateResult.count === 0) return null;

            if (slots !== undefined) {
                await tx.fitnessClassAvailabilitySlot.updateMany({
                    where: {
                        fitnessClassId: id,
                        trainerUserId,
                        status: 'AVAILABLE',
                    },
                    data: {
                        status: 'CANCELLED',
                    },
                });

                if (slots.length > 0) {
                    await tx.fitnessClassAvailabilitySlot.createMany({
                        data: slots.map((slot) => ({
                            ...slot,
                            fitnessClassId: id,
                        })),
                    });
                }
            }

            return tx.fitnessClass.findUnique({
                where: { id },
                include: this.getIncludePattern(),
            });
        });

        return fitnessClass ? this.mapToEntity(fitnessClass) : null;
    }

    async requestRescheduleByTrainer(
        id: string,
        trainerUserId: string,
        data: Record<string, unknown>,
        proposedSlots: any[],
    ): Promise<FitnessClassEntity | null> {
        const fitnessClass = await (this.prisma as any).$transaction(async (tx: any) => {
            const updateResult = await tx.fitnessClass.updateMany({
                where: {
                    id,
                    trainerUserId,
                    status: 'ACTIVE',
                },
                data,
            });

            if (updateResult.count === 0) return null;

            await tx.fitnessClassAvailabilitySlot.updateMany({
                where: {
                    fitnessClassId: id,
                    trainerUserId,
                    isRescheduleProposal: true,
                    rescheduleStatus: 'PENDING_MEMBER_APPROVAL',
                },
                data: {
                    status: 'CANCELLED',
                    rescheduleStatus: 'CANCELLED',
                },
            });

            await tx.fitnessClassAvailabilitySlot.createMany({
                data: proposedSlots.map((slot) => ({
                    ...slot,
                    fitnessClassId: id,
                })),
            });

            return tx.fitnessClass.findUnique({
                where: { id },
                include: this.getIncludePattern(),
            });
        });

        return fitnessClass ? this.mapToEntity(fitnessClass) : null;
    }

    async createBooking(
        memberUserId: string,
        fitnessClassId: string,
        model: any,
    ): Promise<any> {
        await this.expireHeldBookings();

        const requestedSlotIds = this.getRequestedSlotIds(model);
        const now = new Date();
        const reservedUntil = new Date(now.getTime() + this.reservationMinutes * 60000);

        try {
            return await (this.prisma as any).$transaction(async (tx: any) => {
                const fitnessClass = await tx.fitnessClass.findFirst({
                    where: {
                        id: fitnessClassId,
                        status: 'ACTIVE',
                    },
                    include: {
                        availabilitySlots: {
                            where: {
                                id: {
                                    in: requestedSlotIds,
                                },
                                startAt: {
                                    gte: now,
                                },
                            },
                            orderBy: {
                                startAt: 'asc',
                            },
                            include: {
                                bookings: {
                                    where: {
                                        OR: [
                                            { bookingStatus: { in: this.slotOccupyingBookingStatuses } },
                                            {
                                                bookingStatus: 'HELD',
                                                reservedUntil: {
                                                    gt: now,
                                                },
                                            },
                                        ],
                                    },
                                    select: {
                                        memberUserId: true,
                                        bookingStatus: true,
                                        reservedUntil: true,
                                    },
                                },
                            },
                        },
                        trainer: {
                            include: {
                                verification: true,
                                trainerProfile: {
                                    select: {
                                        stripeConnectAccountId: true,
                                        stripeConnectOnboardingComplete: true,
                                        stripeChargesEnabled: true,
                                        stripePayoutsEnabled: true,
                                    },
                                },
                            },
                        },
                    },
                });

                const slots = fitnessClass?.availabilitySlots ?? [];
                if (!fitnessClass || slots.length !== requestedSlotIds.length) {
                    return { error: 'CLASS_OR_SLOT_NOT_FOUND' };
                }

                if (fitnessClass.trainer?.verification?.verificationStatus !== 'APPROVED') {
                    return { error: 'TRAINER_NOT_APPROVED' };
                }

                const trainerProfile = fitnessClass.trainer?.trainerProfile;
                const payoutReady = Boolean(
                    trainerProfile?.stripeConnectAccountId
                    && trainerProfile?.stripeConnectOnboardingComplete
                    && trainerProfile?.stripeChargesEnabled
                    && trainerProfile?.stripePayoutsEnabled,
                );
                if (!payoutReady) {
                    return { error: 'TRAINER_PAYOUT_NOT_READY' };
                }

                if (slots.some((slot: any) => slot.status !== 'AVAILABLE')) {
                    return { error: 'SLOT_NOT_AVAILABLE' };
                }

                const maxBookings = this.getMaxBookingsForClass(fitnessClass);
                if (slots.some((slot: any) => slot.bookings.length >= maxBookings)) {
                    return { error: 'SLOT_FULL' };
                }

                if (slots.some((slot: any) => slot.bookings.some((booking: any) => booking.memberUserId === memberUserId))) {
                    return { error: 'DUPLICATE_BOOKING' };
                }

                const subtotalAmount = Number(fitnessClass.pricePerMember) * slots.length;

                // Snapshot the current commission rate so the split is always
                // based on the rate in effect when the member books, not when
                // they pay (or when the admin later changes the rate).
                const commissionConfig = await this.adminRepository.getCommissionConfig();
                const commissionRate = Number(commissionConfig.commissionRate ?? 0);
                const { platformFeeAmount, trainerPayoutAmount } = this.applyCommission(subtotalAmount, commissionRate);

                const payment = await tx.bookingPayment.create({
                    data: {
                        memberUserId,
                        fitnessClassId: fitnessClass.id,
                        subtotalAmount,
                        discountAmount: 0,
                        taxAmount: 0,
                        totalAmount: subtotalAmount,
                        commissionRate,
                        platformFeeAmount,
                        trainerPayoutAmount,
                        status: 'PENDING',
                        expiresAt: reservedUntil,
                    },
                });

                const bookings: any[] = [];
                for (const slot of slots) {
                    const booking = await tx.booking.create({
                        data: {
                            memberUserId,
                            trainerUserId: fitnessClass.trainerUserId,
                            fitnessClassId: fitnessClass.id,
                            availabilitySlotId: slot.id,
                            bookingPaymentId: payment.id,
                            fullName: model.fullName.trim(),
                            email: model.email,
                            phoneNumber: model.phoneNumber,
                            location: model.location,
                            comment: model.comment ?? null,
                            scheduledDate: slot.date,
                            startTime: slot.startTime,
                            endTime: slot.endTime,
                            totalAmount: fitnessClass.pricePerMember,
                            bookingStatus: 'HELD',
                            paymentStatus: 'PENDING',
                            reservedUntil,
                            reminderEnabled: model.reminderEnabled ?? false,
                        },
                        include: this.getBookingIncludePattern(),
                    });

                    bookings.push(booking);

                    const nextActiveCount = slot.bookings.length + 1;
                    if (nextActiveCount >= maxBookings) {
                        await tx.fitnessClassAvailabilitySlot.update({
                            where: {
                                id: slot.id,
                            },
                            data: {
                                status: 'BOOKED',
                            },
                        });
                    }
                }

                return {
                    bookings,
                    payment,
                    reservedUntil,
                };
            }, {
                isolationLevel: 'Serializable',
            });
        } catch (error: any) {
            if (error?.code === 'P2034') {
                return { error: 'BOOKING_CONFLICT' };
            }

            throw error;
        }
    }

    private getRequestedSlotIds(model: any): string[] {
        const ids = model.availabilitySlotIds?.length
            ? model.availabilitySlotIds
            : model.availabilitySlotId
                ? [model.availabilitySlotId]
                : [];

        return Array.from(new Set(ids));
    }

    async findBookingsByMember(memberUserId: string): Promise<any[]> {
        await this.expireHeldBookings();

        return (this.prisma as any).booking.findMany({
            where: {
                memberUserId,
            },
            include: this.getBookingIncludePattern(),
            orderBy: {
                createdAt: 'desc',
            },
        });
    }

    async findBookedClassesByMember(memberUserId: string): Promise<any[]> {
        await this.expireHeldBookings();
        const now = new Date();

        const baseWhere = {
            memberUserId,
            bookingStatus: {
                in: this.memberBookedClassStatuses,
            },
        };

        const [upcomingBookings, pastBookings] = await Promise.all([
            (this.prisma as any).booking.findMany({
                where: {
                    ...baseWhere,
                    availabilitySlot: {
                        startAt: {
                            gte: now,
                        },
                    },
                },
                include: this.getBookingIncludePattern(),
                orderBy: [
                    {
                        availabilitySlot: {
                            startAt: 'asc',
                        },
                    },
                    {
                        createdAt: 'asc',
                    },
                ],
            }),
            (this.prisma as any).booking.findMany({
                where: {
                    ...baseWhere,
                    availabilitySlot: {
                        startAt: {
                            lt: now,
                        },
                    },
                },
                include: this.getBookingIncludePattern(),
                orderBy: [
                    {
                        availabilitySlot: {
                            startAt: 'desc',
                        },
                    },
                    {
                        createdAt: 'desc',
                    },
                ],
            }),
        ]);

        return [...upcomingBookings, ...pastBookings];
    }

    async findScheduleBookingsByTrainer(
        trainerUserId: string,
        startDate: string,
        endDate: string,
    ): Promise<any[]> {
        await this.expireHeldBookings();

        return (this.prisma as any).booking.findMany({
            where: {
                trainerUserId,
                paymentStatus: 'PAID',
                bookingStatus: {
                    in: this.scheduleBookingStatuses,
                },
                scheduledDate: {
                    gte: startDate,
                    lte: endDate,
                },
            },
            include: this.getBookingIncludePattern(),
            orderBy: [
                {
                    availabilitySlot: {
                        startAt: 'asc',
                    },
                },
                {
                    createdAt: 'asc',
                },
            ],
        });
    }

    async findNextBookingByMember(memberUserId: string): Promise<any | null> {
        await this.expireHeldBookings();

        return (this.prisma as any).booking.findFirst({
            where: {
                memberUserId,
                bookingStatus: {
                    in: ['CONFIRMED', 'RESCHEDULED'],
                },
                availabilitySlot: {
                    startAt: {
                        gte: new Date(),
                    },
                },
            },
            include: this.getBookingIncludePattern(),
            orderBy: [
                {
                    availabilitySlot: {
                        startAt: 'asc',
                    },
                },
                {
                    createdAt: 'asc',
                },
            ],
        });
    }

    async findNextWorkoutsByMember(memberUserId: string, take: number = 5): Promise<any[]> {
        await this.expireHeldBookings();
        const now = new Date();

        return (this.prisma as any).booking.findMany({
            where: {
                memberUserId,
                paymentStatus: 'PAID',
                bookingStatus: {
                    in: ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED'],
                },
                OR: [
                    // upcoming sessions
                    { availabilitySlot: { startAt: { gte: now } } },
                    // in-progress or ended but member hasn't completed yet
                    { memberCompletedAt: null },
                ],
            },
            include: this.getNextWorkoutIncludePattern(),
            orderBy: [
                {
                    availabilitySlot: {
                        startAt: 'asc',
                    },
                },
                {
                    createdAt: 'asc',
                },
            ],
            take,
        });
    }

    async requestBookingReschedule(
        bookingId: string,
        currentUserId: string,
        role: Roles.Member | Roles.Trainer,
        newDate: string,
        newStartTime: string,
    ): Promise<any> {
        await this.expireHeldBookings();

        const now = new Date();
        const ownershipWhere = role === Roles.Member
            ? { memberUserId: currentUserId }
            : { trainerUserId: currentUserId };

        const booking = await (this.prisma as any).booking.findFirst({
            where: {
                id: bookingId,
                ...ownershipWhere,
            },
            include: {
                fitnessClass: true,
                trainer: {
                    select: {
                        timezone: true,
                    },
                },
                member: {
                    select: {
                        timezone: true,
                    },
                },
            },
        });

        if (!booking) {
            return { error: 'BOOKING_NOT_FOUND' };
        }

        if (!['CONFIRMED', 'RESCHEDULED'].includes(booking.bookingStatus)) {
            return { error: 'BOOKING_NOT_RESCHEDULABLE' };
        }

        const scheduleTimeZone = booking.trainer?.timezone ?? booking.member?.timezone;
        const startAt = this.buildDateTime(newDate, newStartTime, scheduleTimeZone);
        if (startAt <= now) {
            return { error: 'INVALID_RESCHEDULE_TIME' };
        }

        const endAt = new Date(startAt.getTime() + booking.fitnessClass.durationMinutes * 60000);
        const newEndTime = this.formatTime(endAt, scheduleTimeZone);

        const updatedBooking = await (this.prisma as any).booking.update({
            where: { id: booking.id },
            data: {
                bookingStatus: 'RESCHEDULE_REQUESTED',
                rescheduleRequestedByUserId: currentUserId,
                rescheduleRequestedAt: now,
                proposedScheduledDate: newDate,
                proposedStartTime: newStartTime,
                proposedEndTime: newEndTime,
                memberRescheduleAcceptedAt: role === Roles.Member ? now : null,
                trainerRescheduleAcceptedAt: role === Roles.Trainer ? now : null,
                rescheduledAt: null,
            },
            include: this.getBookingIncludePattern(),
        });

        await this.refreshSlotStatuses(this.prisma, [booking.availabilitySlotId]);

        return { booking: updatedBooking };
    }

    async acceptBookingReschedule(
        bookingId: string,
        currentUserId: string,
        role: Roles.Member | Roles.Trainer,
    ): Promise<any> {
        await this.expireHeldBookings();

        try {
            return await (this.prisma as any).$transaction(async (tx: any) => {
                const now = new Date();
                const ownershipWhere = role === Roles.Member
                    ? { memberUserId: currentUserId }
                    : { trainerUserId: currentUserId };

                const booking = await tx.booking.findFirst({
                    where: {
                        id: bookingId,
                        ...ownershipWhere,
                    },
                    include: {
                        fitnessClass: true,
                        trainer: {
                            select: {
                                timezone: true,
                            },
                        },
                        member: {
                            select: {
                                timezone: true,
                            },
                        },
                    },
                });

                if (!booking) {
                    return { error: 'BOOKING_NOT_FOUND' };
                }

                if (
                    booking.bookingStatus !== 'RESCHEDULE_REQUESTED'
                    || !booking.proposedScheduledDate
                    || !booking.proposedStartTime
                    || !booking.proposedEndTime
                ) {
                    return { error: 'RESCHEDULE_NOT_REQUESTED' };
                }

                const acceptedBooking = await tx.booking.update({
                    where: { id: booking.id },
                    data: role === Roles.Member
                        ? { memberRescheduleAcceptedAt: now }
                        : { trainerRescheduleAcceptedAt: now },
                });

                const memberAcceptedAt = role === Roles.Member
                    ? now
                    : acceptedBooking.memberRescheduleAcceptedAt;
                const trainerAcceptedAt = role === Roles.Trainer
                    ? now
                    : acceptedBooking.trainerRescheduleAcceptedAt;

                if (!memberAcceptedAt || !trainerAcceptedAt) {
                    const pendingBooking = await tx.booking.findUnique({
                        where: { id: booking.id },
                        include: this.getBookingIncludePattern(),
                    });

                    return { booking: pendingBooking };
                }

                const scheduleTimeZone = booking.trainer?.timezone ?? booking.member?.timezone;
                const startAt = this.buildDateTime(booking.proposedScheduledDate, booking.proposedStartTime, scheduleTimeZone);
                if (startAt <= now) {
                    return { error: 'INVALID_RESCHEDULE_TIME' };
                }

                const targetSlot = await this.findOrCreateRescheduleSlot(tx, booking, startAt);
                const activeBookings = targetSlot.bookings.filter((slotBooking: any) =>
                    slotBooking.id !== booking.id
                    && (
                        this.slotOccupyingBookingStatuses.includes(slotBooking.bookingStatus)
                        || (slotBooking.bookingStatus === 'HELD' && slotBooking.reservedUntil && slotBooking.reservedUntil > now)
                    ),
                );
                const maxBookings = this.getMaxBookingsForClass(booking.fitnessClass);

                if (activeBookings.length >= maxBookings) {
                    return { error: 'SLOT_FULL' };
                }

                await tx.booking.update({
                    where: { id: booking.id },
                    data: {
                        availabilitySlotId: targetSlot.id,
                        scheduledDate: booking.proposedScheduledDate,
                        startTime: booking.proposedStartTime,
                        endTime: booking.proposedEndTime,
                        bookingStatus: 'RESCHEDULED',
                        rescheduledAt: now,
                    },
                });

                await this.refreshSlotStatuses(tx, [booking.availabilitySlotId, targetSlot.id]);

                const rescheduledBooking = await tx.booking.findUnique({
                    where: { id: booking.id },
                    include: this.getBookingIncludePattern(),
                });

                return { booking: rescheduledBooking };
            }, {
                isolationLevel: 'Serializable',
            });
        } catch (error: any) {
            if (error?.code === 'P2034') {
                return { error: 'RESCHEDULE_CONFLICT' };
            }

            throw error;
        }
    }

    async markBookingComplete(
        bookingId: string,
        currentUserId: string,
        role: Roles.Member | Roles.Trainer,
    ): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();
            const ownershipWhere = role === Roles.Member
                ? { memberUserId: currentUserId }
                : { trainerUserId: currentUserId };

            const booking = await tx.booking.findFirst({
                where: {
                    id: bookingId,
                    ...ownershipWhere,
                },
                include: {
                    fitnessClass: true,
                    availabilitySlot: true,
                    trainer: {
                        select: {
                            timezone: true,
                        },
                    },
                    member: {
                        select: {
                            timezone: true,
                        },
                    },
                },
            });

            if (!booking) {
                return { error: 'BOOKING_NOT_FOUND' };
            }

            const isCompletableStatus = this.completableBookingStatuses.includes(booking.bookingStatus)
                || (booking.bookingStatus === 'COMPLETED' && !booking.completedAt);
            if (!isCompletableStatus) {
                return { error: 'BOOKING_NOT_COMPLETABLE' };
            }

            const bookingEndAt = this.buildDateTime(
                booking.scheduledDate,
                booking.endTime,
                booking.trainer?.timezone ?? booking.member?.timezone,
            );
            if (bookingEndAt > now) {
                return {
                    error: 'BOOKING_NOT_ENDED',
                    scheduledDate: booking.scheduledDate,
                    endTime: booking.endTime,
                };
            }

            if (role === Roles.Trainer && !booking.memberCompletedAt) {
                return { error: 'TRAINER_NOT_ELIGIBLE' };
            }

            const updateData: Record<string, any> = role === Roles.Member
                ? { memberCompletedAt: booking.memberCompletedAt ?? now }
                : { trainerCompletedAt: booking.trainerCompletedAt ?? now };

            const memberCompletedAt = role === Roles.Member
                ? updateData.memberCompletedAt
                : booking.memberCompletedAt;
            const trainerCompletedAt = role === Roles.Trainer
                ? updateData.trainerCompletedAt
                : booking.trainerCompletedAt;

            if (memberCompletedAt && trainerCompletedAt) {
                updateData.bookingStatus = 'COMPLETED';
                updateData.completedAt = booking.completedAt ?? now;
            }

            await tx.booking.update({
                where: { id: booking.id },
                data: updateData,
            });

            if (memberCompletedAt && trainerCompletedAt) {
                await this.markClassCompletedIfReady(tx, booking.fitnessClassId);
                await this.refreshSlotStatuses(tx, [booking.availabilitySlotId]);
            }

            const completedBooking = await tx.booking.findUnique({
                where: { id: booking.id },
                include: this.getBookingIncludePattern(),
            });

            return { booking: completedBooking };
        });
    }

    async cancelBookingByMember(memberUserId: string, bookingId: string): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();

            const booking = await tx.booking.findFirst({
                where: { id: bookingId, memberUserId },
                include: {
                    fitnessClass: true,
                    availabilitySlot: true,
                    bookingPayment: {
                        select: {
                            id: true,
                            providerSessionId: true,
                            status: true,
                        },
                    },
                    trainer: { select: { timezone: true } },
                    member: { select: { timezone: true } },
                },
            });

            if (!booking) {
                return { error: 'BOOKING_NOT_FOUND' };
            }

            if (!['CONFIRMED', 'RESCHEDULED'].includes(booking.bookingStatus)) {
                return { error: 'BOOKING_NOT_CANCELLABLE' };
            }

            await tx.booking.update({
                where: { id: booking.id },
                data: {
                    bookingStatus: 'CANCELLED',
                    paymentStatus: 'REFUNDED',
                    cancelledAt: now,
                },
            });

            await this.refreshSlotStatuses(tx, [booking.availabilitySlotId]);

            const cancelledBooking = await tx.booking.findUnique({
                where: { id: booking.id },
                include: {
                    ...this.getBookingIncludePattern(),
                    bookingPayment: {
                        select: {
                            id: true,
                            providerSessionId: true,
                            status: true,
                        },
                    },
                },
            });

            return { booking: cancelledBooking };
        });
    }

    async rejectBookingRescheduleByMember(memberUserId: string, bookingId: string): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();

            const booking = await tx.booking.findFirst({
                where: { id: bookingId, memberUserId },
                include: {
                    fitnessClass: true,
                    availabilitySlot: true,
                    bookingPayment: {
                        select: {
                            id: true,
                            providerSessionId: true,
                            status: true,
                        },
                    },
                },
            });

            if (!booking) {
                return { error: 'BOOKING_NOT_FOUND' };
            }

            if (
                booking.bookingStatus !== 'RESCHEDULE_REQUESTED'
                || booking.rescheduleRequestedByUserId !== booking.trainerUserId
            ) {
                return { error: 'RESCHEDULE_REJECT_NOT_ELIGIBLE' };
            }

            await tx.booking.update({
                where: { id: booking.id },
                data: {
                    bookingStatus: 'CANCELLED',
                    paymentStatus: 'REFUNDED',
                    cancelledAt: now,
                },
            });

            await this.refreshSlotStatuses(tx, [booking.availabilitySlotId]);

            const cancelledBooking = await tx.booking.findUnique({
                where: { id: booking.id },
                include: {
                    ...this.getBookingIncludePattern(),
                    bookingPayment: {
                        select: {
                            id: true,
                            providerSessionId: true,
                            status: true,
                        },
                    },
                },
            });

            return { booking: cancelledBooking };
        });
    }

    async markBookingCheckIn(
        bookingId: string,
        currentUserId: string,
        role: Roles.Member | Roles.Trainer,
    ): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();
            const ownershipWhere = role === Roles.Member
                ? { memberUserId: currentUserId }
                : { trainerUserId: currentUserId };

            const booking = await tx.booking.findFirst({
                where: {
                    id: bookingId,
                    ...ownershipWhere,
                },
                include: {
                    fitnessClass: true,
                    availabilitySlot: true,
                    trainer: {
                        select: {
                            timezone: true,
                        },
                    },
                    member: {
                        select: {
                            timezone: true,
                        },
                    },
                },
            });

            if (!booking) {
                return { error: 'BOOKING_NOT_FOUND' };
            }

            if (!['CONFIRMED', 'RESCHEDULED'].includes(booking.bookingStatus)) {
                return { error: 'BOOKING_NOT_CHECK_IN_ELIGIBLE' };
            }

            const bookingStartAt = this.buildDateTime(
                booking.scheduledDate,
                booking.startTime,
                booking.trainer?.timezone ?? booking.member?.timezone,
            );
            if (bookingStartAt > now) {
                return {
                    error: 'BOOKING_NOT_STARTED',
                    scheduledDate: booking.scheduledDate,
                    startTime: booking.startTime,
                };
            }

            const bookingEndAt = this.buildDateTime(
                booking.scheduledDate,
                booking.endTime,
                booking.trainer?.timezone ?? booking.member?.timezone,
            );
            if (bookingEndAt < now && booking.completedAt) {
                return { error: 'BOOKING_ALREADY_COMPLETED' };
            }

            if (role === Roles.Trainer && !booking.memberCheckedInAt) {
                return { error: 'TRAINER_CHECK_IN_NOT_ELIGIBLE' };
            }

            const updateData = role === Roles.Member
                ? { memberCheckedInAt: booking.memberCheckedInAt ?? now }
                : { trainerCheckedInAt: booking.trainerCheckedInAt ?? now };

            await tx.booking.update({
                where: { id: booking.id },
                data: updateData,
            });

            const checkedInBooking = await tx.booking.findUnique({
                where: { id: booking.id },
                include: this.getBookingIncludePattern(),
            });

            return { booking: checkedInBooking };
        });
    }

    async confirmBookingPayment(memberUserId: string, paymentId: string, model: any): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();
            const payment = await tx.bookingPayment.findFirst({
                where: {
                    memberUserId,
                    status: 'PENDING',
                    OR: this.getPaymentOrBookingIdWhere(paymentId),
                },
                include: {
                    bookings: true,
                },
            });

            if (!payment) {
                return { error: 'PAYMENT_NOT_FOUND' };
            }

            if (payment.expiresAt <= now) {
                await this.expirePaymentInTransaction(tx, payment.id, now);
                await this.refreshSlotStatuses(tx, payment.bookings.map((booking: any) => booking.availabilitySlotId));
                return { error: 'PAYMENT_EXPIRED' };
            }

            await tx.bookingPayment.update({
                where: { id: payment.id },
                data: {
                    status: 'PAID',
                    paidAt: now,
                    provider: model.provider ?? payment.provider,
                    paymentMethod: model.paymentMethod ?? payment.paymentMethod,
                    providerSessionId: model.providerSessionId ?? payment.providerSessionId,
                },
            });

            await tx.booking.updateMany({
                where: {
                    bookingPaymentId: payment.id,
                    bookingStatus: 'HELD',
                    reservedUntil: {
                        gt: now,
                    },
                },
                data: {
                    bookingStatus: 'CONFIRMED',
                    paymentStatus: 'PAID',
                    confirmedAt: now,
                },
            });

            await this.refreshSlotStatuses(tx, payment.bookings.map((booking: any) => booking.availabilitySlotId));

            const bookings = await tx.booking.findMany({
                where: {
                    bookingPaymentId: payment.id,
                },
                include: this.getBookingIncludePattern(),
                orderBy: {
                    startTime: 'asc',
                },
            });

            return { bookings };
        }, {
            isolationLevel: 'Serializable',
        });
    }

    async applyBookingCoupon(memberUserId: string, paymentId: string, couponCode: string): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();
            const payment = await tx.bookingPayment.findFirst({
                where: {
                    memberUserId,
                    status: 'PENDING',
                    OR: this.getPaymentOrBookingIdWhere(paymentId),
                },
                include: {
                    bookings: true,
                },
            });

            if (!payment) {
                return { error: 'PAYMENT_NOT_FOUND' };
            }

            if (payment.expiresAt <= now) {
                await this.expirePaymentInTransaction(tx, payment.id, now);
                await this.refreshSlotStatuses(tx, payment.bookings.map((booking: any) => booking.availabilitySlotId));
                return { error: 'PAYMENT_EXPIRED' };
            }

            const coupon = this.resolveCoupon(couponCode);
            if (!coupon) {
                return { error: 'COUPON_NOT_FOUND' };
            }

            if (coupon.firstPaidBookingOnly) {
                const paidBookingPayments = await tx.bookingPayment.count({
                    where: {
                        memberUserId,
                        status: 'PAID',
                    },
                });

                if (paidBookingPayments > 0) {
                    return { error: 'COUPON_NOT_ELIGIBLE' };
                }
            }

            const subtotalAmount = Number(payment.subtotalAmount);
            const discountAmount = this.roundMoney(subtotalAmount * coupon.discountRate);
            const taxAmount = 0;
            const totalAmount = Math.max(this.roundMoney(subtotalAmount - discountAmount + taxAmount), 0);

            // Recalculate commission split against the discounted total.
            const commissionRate = Number(payment.commissionRate ?? 0);
            const { platformFeeAmount, trainerPayoutAmount } = this.applyCommission(totalAmount, commissionRate);

            const updatedPayment = await tx.bookingPayment.update({
                where: {
                    id: payment.id,
                },
                data: {
                    discountAmount,
                    taxAmount,
                    totalAmount,
                    platformFeeAmount,
                    trainerPayoutAmount,
                    couponCode: coupon.code,
                    provider: null,
                    providerSessionId: null,
                    paymentMethod: null,
                },
            });

            return { payment: updatedPayment };
        }, {
            isolationLevel: 'Serializable',
        });
    }

    async failBookingPayment(memberUserId: string, paymentId: string, model: any): Promise<any> {
        await this.expireHeldBookings();

        return (this.prisma as any).$transaction(async (tx: any) => {
            const now = new Date();
            const payment = await tx.bookingPayment.findFirst({
                where: {
                    memberUserId,
                    status: 'PENDING',
                    OR: this.getPaymentOrBookingIdWhere(paymentId),
                },
                include: {
                    bookings: true,
                },
            });

            if (!payment) {
                return { error: 'PAYMENT_NOT_FOUND' };
            }

            await tx.bookingPayment.update({
                where: { id: payment.id },
                data: {
                    status: 'FAILED',
                    failedAt: now,
                    provider: model.provider ?? payment.provider,
                    paymentMethod: model.paymentMethod ?? payment.paymentMethod,
                    providerSessionId: model.providerSessionId ?? payment.providerSessionId,
                },
            });

            await tx.booking.updateMany({
                where: {
                    bookingPaymentId: payment.id,
                    bookingStatus: 'HELD',
                },
                data: {
                    bookingStatus: 'PAYMENT_FAILED',
                    paymentStatus: 'FAILED',
                    cancelledAt: now,
                },
            });

            await this.refreshSlotStatuses(tx, payment.bookings.map((booking: any) => booking.availabilitySlotId));

            return { paymentId: payment.id };
        }, {
            isolationLevel: 'Serializable',
        });
    }

    async findPendingBookingPaymentForMember(memberUserId: string, paymentId: string): Promise<any | null> {
        await this.expireHeldBookings();

        return (this.prisma as any).bookingPayment.findFirst({
            where: {
                memberUserId,
                status: 'PENDING',
                OR: this.getPaymentOrBookingIdWhere(paymentId),
            },
            include: {
                bookings: {
                    select: {
                        id: true,
                        memberUserId: true,
                        trainerUserId: true,
                        fitnessClassId: true,
                        trainer: {
                            select: {
                                trainerProfile: {
                                    select: {
                                        stripeConnectAccountId: true,
                                        stripeConnectOnboardingComplete: true,
                                        stripeChargesEnabled: true,
                                        stripePayoutsEnabled: true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });
    }

    async updateBookingPaymentProviderSession(
        memberUserId: string,
        paymentId: string,
        providerSessionId: string,
    ): Promise<any | null> {
        const payment = await (this.prisma as any).bookingPayment.findFirst({
            where: {
                memberUserId,
                status: 'PENDING',
                OR: this.getPaymentOrBookingIdWhere(paymentId),
            },
            select: {
                id: true,
            },
        });

        if (!payment) return null;

        return (this.prisma as any).bookingPayment.update({
            where: {
                id: payment.id,
            },
            data: {
                provider: 'stripe',
                providerSessionId,
            },
        });
    }

    private getBookingIncludePattern() {
        return {
            fitnessClass: {
                select: {
                    id: true,
                    name: true,
                    classType: true,
                    sessionPlanType: true,
                    durationMinutes: true,
                    sessionFormat: true,
                    status: true,
                },
            },
            trainer: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                    phoneNumber: true,
                    timezone: true,
                },
            },
            availabilitySlot: {
                select: {
                    startAt: true,
                    endAt: true,
                },
            },
        };
    }

    private getNextWorkoutIncludePattern() {
        return {
            member: {
                select: {
                    currentLat: true,
                    currentLng: true,
                },
            },
            availabilitySlot: {
                select: {
                    startAt: true,
                    endAt: true,
                },
            },
            fitnessClass: {
                select: {
                    id: true,
                    name: true,
                    classType: true,
                    sessionPlanType: true,
                    durationMinutes: true,
                    sessionFormat: true,
                },
            },
            trainer: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    profileImageUrl: true,
                    phoneNumber: true,
                    location: true,
                    timezone: true,
                    trainerProfile: {
                        select: {
                            classesTaught: true,
                            baseLocationLat: true,
                            baseLocationLng: true,
                            liveLocationLat: true,
                            liveLocationLng: true,
                            isOnline: true,
                        },
                    },
                    trainerReviews: {
                        select: {
                            rating: true,
                        },
                    },
                },
            },
        };
    }

    /**
     * Automatically marks ACTIVE classes as COMPLETED when:
     *  - ALL their availability slots have already started (startAt < now), AND
     *  - They have no remaining active bookings (CONFIRMED / RESCHEDULE_REQUESTED / RESCHEDULED).
     *
     * This prevents stale ACTIVE classes from piling up indefinitely in trainer responses.
     */
    async autoCompleteExpiredClasses(): Promise<void> {
        const now = new Date();

        await (this.prisma as any).fitnessClass.updateMany({
            where: {
                status: 'ACTIVE',
                // No future slot exists (all slots are in the past)
                availabilitySlots: {
                    none: {
                        startAt: { gte: now },
                        isRescheduleProposal: false,
                    },
                },
                // No active booking still running
                bookings: {
                    none: {
                        bookingStatus: {
                            in: this.activeBookingStatuses,
                        },
                    },
                },
            },
            data: {
                status: 'COMPLETED',
            },
        });
    }

    async expireHeldBookings(): Promise<void> {
        const now = new Date();

        await (this.prisma as any).$transaction(async (tx: any) => {
            const expiredPayments = await tx.bookingPayment.findMany({
                where: {
                    status: 'PENDING',
                    expiresAt: {
                        lte: now,
                    },
                },
                include: {
                    bookings: true,
                },
            });

            if (!expiredPayments.length) return;

            const slotIds = expiredPayments.flatMap((payment: any) =>
                payment.bookings.map((booking: any) => booking.availabilitySlotId),
            );

            await tx.bookingPayment.updateMany({
                where: {
                    id: {
                        in: expiredPayments.map((payment: any) => payment.id),
                    },
                    status: 'PENDING',
                },
                data: {
                    status: 'EXPIRED',
                },
            });

            await tx.booking.updateMany({
                where: {
                    bookingPaymentId: {
                        in: expiredPayments.map((payment: any) => payment.id),
                    },
                    bookingStatus: 'HELD',
                },
                data: {
                    bookingStatus: 'EXPIRED',
                    paymentStatus: 'EXPIRED',
                    expiredAt: now,
                },
            });

            await this.refreshSlotStatuses(tx, slotIds);
        });
    }

    private async expirePaymentInTransaction(tx: any, paymentId: string, now: Date): Promise<void> {
        await tx.bookingPayment.update({
            where: { id: paymentId },
            data: {
                status: 'EXPIRED',
            },
        });

        await tx.booking.updateMany({
            where: {
                bookingPaymentId: paymentId,
                bookingStatus: 'HELD',
            },
            data: {
                bookingStatus: 'EXPIRED',
                paymentStatus: 'EXPIRED',
                expiredAt: now,
            },
        });
    }

    private async refreshSlotStatuses(tx: any, slotIds: string[]): Promise<void> {
        const uniqueSlotIds = Array.from(new Set(slotIds)).filter(Boolean);
        if (!uniqueSlotIds.length) return;

        const now = new Date();
        const slots = await tx.fitnessClassAvailabilitySlot.findMany({
            where: {
                id: {
                    in: uniqueSlotIds,
                },
                status: {
                    in: ['AVAILABLE', 'BOOKED'],
                },
            },
            include: {
                fitnessClass: true,
                bookings: {
                    where: {
                        OR: [
                            { bookingStatus: { in: this.slotOccupyingBookingStatuses } },
                            {
                                bookingStatus: 'HELD',
                                reservedUntil: {
                                    gt: now,
                                },
                            },
                        ],
                    },
                    select: {
                        id: true,
                    },
                },
            },
        });

        for (const slot of slots) {
            const maxBookings = this.getMaxBookingsForClass(slot.fitnessClass);
            const nextStatus = slot.bookings.length >= maxBookings ? 'BOOKED' : 'AVAILABLE';
            if (slot.status !== nextStatus) {
                await tx.fitnessClassAvailabilitySlot.update({
                    where: {
                        id: slot.id,
                    },
                    data: {
                        status: nextStatus,
                    },
                });
            }
        }
    }

    private async markClassCompletedIfReady(tx: any, fitnessClassId: string): Promise<void> {
        const now = new Date();
        const [unfinishedBookings, completedBookings, futureSlots] = await Promise.all([
            tx.booking.count({
                where: {
                    fitnessClassId,
                    paymentStatus: 'PAID',
                    bookingStatus: {
                        in: this.activeBookingStatuses,
                    },
                },
            }),
            tx.booking.count({
                where: {
                    fitnessClassId,
                    paymentStatus: 'PAID',
                    bookingStatus: 'COMPLETED',
                },
            }),
            tx.fitnessClassAvailabilitySlot.count({
                where: {
                    fitnessClassId,
                    status: {
                        in: ['AVAILABLE', 'BOOKED'],
                    },
                    endAt: {
                        gt: now,
                    },
                },
            }),
        ]);

        if (completedBookings > 0 && unfinishedBookings === 0 && futureSlots === 0) {
            await tx.fitnessClass.update({
                where: { id: fitnessClassId },
                data: {
                    status: 'COMPLETED',
                },
            });
        }
    }

    private async findOrCreateRescheduleSlot(tx: any, booking: any, startAt: Date): Promise<any> {
        const slot = await tx.fitnessClassAvailabilitySlot.findFirst({
            where: {
                fitnessClassId: booking.fitnessClassId,
                trainerUserId: booking.trainerUserId,
                date: booking.proposedScheduledDate,
                startTime: booking.proposedStartTime,
                endTime: booking.proposedEndTime,
                status: {
                    in: ['AVAILABLE', 'BOOKED'],
                },
            },
            include: {
                bookings: {
                    select: {
                        id: true,
                        bookingStatus: true,
                        reservedUntil: true,
                    },
                },
            },
        });

        if (slot) {
            return slot;
        }

        return tx.fitnessClassAvailabilitySlot.create({
            data: {
                fitnessClassId: booking.fitnessClassId,
                trainerUserId: booking.trainerUserId,
                date: booking.proposedScheduledDate,
                startTime: booking.proposedStartTime,
                endTime: booking.proposedEndTime,
                startAt,
                endAt: new Date(startAt.getTime() + booking.fitnessClass.durationMinutes * 60000),
                status: 'AVAILABLE',
            },
            include: {
                bookings: {
                    select: {
                        id: true,
                        bookingStatus: true,
                        reservedUntil: true,
                    },
                },
            },
        });
    }

    private buildDateTime(date: string, time: string, timeZone?: string | null): Date {
        return DateTimeUtils.fromLocalDateTime(date, time, timeZone);
    }

    private getPaymentOrBookingIdWhere(id: string): any[] {
        return [
            { id },
            {
                bookings: {
                    some: {
                        id,
                    },
                },
            },
        ];
    }

    private formatTime(date: Date, timeZone?: string | null): string {
        return DateTimeUtils.formatTime(date, timeZone);
    }

    private getMaxBookingsForClass(fitnessClass: any): number {
        const capacity = fitnessClass.sessionFormat === 'GROUP' ? fitnessClass.maxMembers : 1;
        return capacity ?? 1;
    }

    private resolveCoupon(couponCode: string): { code: string; discountRate: number; firstPaidBookingOnly: boolean } | null {
        const normalizedCode = couponCode.trim().toUpperCase();
        const coupons = new Map([
            ['FIRSTTIME20', { code: 'FIRSTTIME20', discountRate: 0.2, firstPaidBookingOnly: true }],
        ]);

        return coupons.get(normalizedCode) ?? null;
    }

    private roundMoney(amount: number): number {
        return Math.round((amount + Number.EPSILON) * 100) / 100;
    }

    private mapToEntity(fitnessClass: any): FitnessClassEntity {
        const trainerName = fitnessClass.trainer?.displayName ?? fitnessClass.trainer?.firstName ?? null;
        const trainerImageUrl = fitnessClass.trainer?.profileImageUrl ?? null;
        const joinedMembers = (fitnessClass.bookings ?? [])
            .filter((booking: any) => booking.id && booking.scheduledDate)
            .map((booking: any) => ({
                bookingId: booking.id,
                memberUserId: booking.memberUserId,
                name: booking.member?.displayName ?? booking.member?.firstName ?? null,
                profileImageUrl: booking.member?.profileImageUrl ?? null,
                bookingStatus: booking.bookingStatus,
                scheduledDate: booking.scheduledDate,
                startTime: booking.startTime,
                endTime: booking.endTime,
                memberCheckedInAt: booking.memberCheckedInAt ?? null,
                memberCompletedAt: booking.memberCompletedAt ?? null,
                completedAt: booking.completedAt ?? null,
            }));

        return {
            id: fitnessClass.id,
            trainerUserId: fitnessClass.trainerUserId,
            name: fitnessClass.name,
            scheduledAt: fitnessClass.scheduledAt ?? null,
            classType: fitnessClass.classType,
            sessionPlanType: fitnessClass.sessionPlanType ?? 'SINGLE_SESSION',
            durationMinutes: fitnessClass.durationMinutes,
            pricePerMember: fitnessClass.pricePerMember?.toString?.() ?? String(fitnessClass.pricePerMember),
            sessionFormat: fitnessClass.sessionFormat,
            capacity: fitnessClass.maxMembers,
            status: fitnessClass.status,
            bookedMemberCount: new Set(joinedMembers.map((m: any) => m.memberUserId)).size,
            joinedMembers,
            rescheduleStatus: fitnessClass.rescheduleStatus ?? null,
            rescheduleRequestedByUserId: fitnessClass.rescheduleRequestedByUserId ?? null,
            rescheduleRequestedAt: fitnessClass.rescheduleRequestedAt ?? null,
            rescheduleNote: fitnessClass.rescheduleNote ?? null,
            trainerImageUrl,
            trainer: {
                id: fitnessClass.trainer.id,
                name: trainerName,
                imageUrl: trainerImageUrl,
                timezone: fitnessClass.trainer.timezone ?? null,
            },
            availableSlots: (fitnessClass.availabilitySlots ?? [])
                .filter((slot: any) => !slot.isRescheduleProposal)
                .map((slot: any) => {
                const now = new Date();
                const maxBookings = this.getMaxBookingsForClass(fitnessClass);
                const bookings = slot.bookings ?? [];
                const bookedCount = bookings.filter((booking: any) => this.slotOccupyingBookingStatuses.includes(booking.bookingStatus)).length;
                const heldCount = bookings.filter((booking: any) =>
                    booking.bookingStatus === 'HELD' && booking.reservedUntil && booking.reservedUntil > now,
                ).length;
                const activeCount = bookedCount + heldCount;

                return {
                    id: slot.id,
                    date: slot.date,
                    startTime: slot.startTime,
                    endTime: slot.endTime,
                    startAt: slot.startAt,
                    endAt: slot.endAt,
                    status: slot.status,
                    availabilityStatus: this.getSlotAvailabilityStatus(slot.status, bookedCount, heldCount, maxBookings),
                    isRescheduleProposal: slot.isRescheduleProposal ?? false,
                    rescheduleStatus: slot.rescheduleStatus ?? null,
                    bookedCount,
                    heldCount,
                    capacity: maxBookings,
                    spotsRemaining: Math.max(maxBookings - activeCount, 0),
                };
            }),
            bookedSlots: (fitnessClass.availabilitySlots ?? [])
                .filter((slot: any) => !slot.isRescheduleProposal)
                .map((slot: any) => {
                const now = new Date();
                const maxBookings = this.getMaxBookingsForClass(fitnessClass);
                const bookings = slot.bookings ?? [];
                const bookedCount = bookings.filter((booking: any) => this.slotOccupyingBookingStatuses.includes(booking.bookingStatus)).length;
                const heldCount = bookings.filter((booking: any) =>
                    booking.bookingStatus === 'HELD' && booking.reservedUntil && booking.reservedUntil > now,
                ).length;
                const activeCount = bookedCount + heldCount;
                const availabilityStatus = this.getSlotAvailabilityStatus(slot.status, bookedCount, heldCount, maxBookings);

                return {
                    id: slot.id,
                    date: slot.date,
                    startTime: slot.startTime,
                    endTime: slot.endTime,
                    startAt: slot.startAt,
                    endAt: slot.endAt,
                    status: slot.status,
                    availabilityStatus,
                    isRescheduleProposal: slot.isRescheduleProposal ?? false,
                    rescheduleStatus: slot.rescheduleStatus ?? null,
                    bookedCount,
                    heldCount,
                    capacity: maxBookings,
                    spotsRemaining: Math.max(maxBookings - activeCount, 0),
                };
            }).filter((slot: any) => slot.availabilityStatus !== 'AVAILABLE'),
            proposedRescheduleSlots: (fitnessClass.availabilitySlots ?? [])
                .filter((slot: any) => slot.isRescheduleProposal && slot.rescheduleStatus === 'PENDING_MEMBER_APPROVAL')
                .map((slot: any) => {
                    const now = new Date();
                    const maxBookings = this.getMaxBookingsForClass(fitnessClass);
                    const bookings = slot.bookings ?? [];
                    const bookedCount = bookings.filter((booking: any) => this.slotOccupyingBookingStatuses.includes(booking.bookingStatus)).length;
                    const heldCount = bookings.filter((booking: any) =>
                        booking.bookingStatus === 'HELD' && booking.reservedUntil && booking.reservedUntil > now,
                    ).length;
                    const activeCount = bookedCount + heldCount;

                    return {
                        id: slot.id,
                        date: slot.date,
                        startTime: slot.startTime,
                        endTime: slot.endTime,
                        startAt: slot.startAt,
                        endAt: slot.endAt,
                        status: slot.status,
                        availabilityStatus: this.getSlotAvailabilityStatus(slot.status, bookedCount, heldCount, maxBookings),
                        isRescheduleProposal: slot.isRescheduleProposal ?? false,
                        rescheduleStatus: slot.rescheduleStatus ?? null,
                        bookedCount,
                        heldCount,
                        capacity: maxBookings,
                        spotsRemaining: Math.max(maxBookings - activeCount, 0),
                    };
                }),
            createdAt: fitnessClass.createdAt,
            updatedAt: fitnessClass.updatedAt,
        };
    }

    private getBookedMemberCount(bookings: any[]): number {
        const statuses = new Set(['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED']);
        return new Set(
            bookings
                .filter((booking) => statuses.has(booking.bookingStatus) && booking.paymentStatus === 'PAID')
                .map((booking) => booking.memberUserId),
        ).size;
    }

    private getSlotAvailabilityStatus(
        slotStatus: string,
        bookedCount: number,
        heldCount: number,
        capacity: number,
    ): string {
        if (slotStatus !== 'AVAILABLE') {
            return slotStatus;
        }

        if (bookedCount >= capacity) {
            return 'BOOKED';
        }

        if (bookedCount + heldCount >= capacity) {
            return 'HELD';
        }

        return 'AVAILABLE';
    }
}
