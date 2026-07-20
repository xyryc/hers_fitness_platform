import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { getStaticContentLookupKeys } from '../../user/static-content.utils';

@Injectable()
export class AdminRepository {
    constructor(private readonly prisma: PrismaService) { }

    // ─── Commission config ────────────────────────────────────────────────────

    /** Always returns the singleton row (creates it with 0% if missing). */
    async getCommissionConfig(): Promise<any> {
        const existing = await (this.prisma as any).adminCommissionConfig.findFirst();
        if (existing) return existing;

        return (this.prisma as any).adminCommissionConfig.create({
            data: { commissionRate: 0 },
        });
    }

    async updateCommissionConfig(commissionRate: number, updatedByUserId: string): Promise<any> {
        const existing = await this.getCommissionConfig();
        return (this.prisma as any).adminCommissionConfig.update({
            where: { id: existing.id },
            data: {
                commissionRate,
                updatedByUserId,
            },
        });
    }

    async findUserByEmail(email: string): Promise<{ id: string } | null> {
        return (this.prisma as any).user.findUnique({
            where: { email },
            select: { id: true },
        });
    }

    async updateAdminProfile(adminUserId: string, data: Record<string, any>): Promise<any> {
        return (this.prisma as any).user.update({
            where: { id: adminUserId },
            data,
        });
    }

    // ─── Revenue stats ────────────────────────────────────────────────────────

    async getRevenueStats(): Promise<{
        totalGrossRevenue: number;
        totalPlatformFee: number;
        totalTrainerPayout: number;
        totalPaidBookings: number;
        activeTrainerCount: number;
    }> {
        const [aggregate, activeTrainerCount] = await Promise.all([
            (this.prisma as any).bookingPayment.aggregate({
                where: { status: 'PAID' },
                _sum: {
                    totalAmount: true,
                    platformFeeAmount: true,
                    trainerPayoutAmount: true,
                },
                _count: { id: true },
            }),
            (this.prisma as any).booking.findMany({
                where: {
                    paymentStatus: 'PAID',
                    bookingStatus: { in: ['CONFIRMED', 'RESCHEDULE_REQUESTED', 'RESCHEDULED', 'COMPLETED'] },
                },
                select: { trainerUserId: true },
                distinct: ['trainerUserId'],
            }).then((rows: any[]) => rows.length),
        ]);

        return {
            totalGrossRevenue: Number(aggregate._sum?.totalAmount ?? 0),
            totalPlatformFee: Number(aggregate._sum?.platformFeeAmount ?? 0),
            totalTrainerPayout: Number(aggregate._sum?.trainerPayoutAmount ?? 0),
            totalPaidBookings: aggregate._count?.id ?? 0,
            activeTrainerCount,
        };
    }

    /** Raw paid-payment rows used to build earnings charts. */
    async getPaidPaymentsForChart(): Promise<{ paidAt: Date; totalAmount: any; platformFeeAmount: any; trainerPayoutAmount: any }[]> {
        return (this.prisma as any).bookingPayment.findMany({
            where: { status: 'PAID', paidAt: { not: null } },
            select: {
                paidAt: true,
                totalAmount: true,
                platformFeeAmount: true,
                trainerPayoutAmount: true,
            },
        });
    }

    // ─── Dashboard overview ───────────────────────────────────────────────────

    /**
     * Fetches all raw numbers needed to build the Summary card row.
     * Two time windows are compared: current calendar month vs previous one,
     * and current ISO week (Mon–Sun) vs the previous one.
     */
    async getDashboardSummaryData(): Promise<{
        allTimeRevenue: number;
        allTimeCommission: number;
        currentMonthRevenue: number;
        lastMonthRevenue: number;
        currentMonthCommission: number;
        lastMonthCommission: number;
        pendingVerificationsCount: number;
        totalMembersCount: number;
        newMembersThisMonth: number;
        newMembersLastMonth: number;
        activeMembersCount: number;
        newActiveMembersThisMonth: number;
        newActiveMembersLastMonth: number;
        totalTrainersCount: number;
        newTrainersThisMonth: number;
        newTrainersLastMonth: number;
        bookingsThisWeekCount: number;
        bookingsLastWeekCount: number;
    }> {
        const now = new Date();

        // Month windows (UTC)
        const currentMonthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
        const lastMonthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));

        // ISO-week windows (Mon = first day)
        const dowNow = now.getUTCDay(); // 0=Sun … 6=Sat
        const diffToMon = dowNow === 0 ? -6 : 1 - dowNow;
        const thisWeekStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + diffToMon));
        const lastWeekStart = new Date(thisWeekStart);
        lastWeekStart.setUTCDate(thisWeekStart.getUTCDate() - 7);

        const [
            allTimeAgg,
            currentMonthAgg,
            lastMonthAgg,
            pendingVerificationsCount,
            totalMembersCount,
            newMembersThisMonth,
            newMembersLastMonth,
            activeMembersCount,
            newActiveMembersThisMonth,
            newActiveMembersLastMonth,
            totalTrainersCount,
            newTrainersThisMonth,
            newTrainersLastMonth,
            bookingsThisWeekCount,
            bookingsLastWeekCount,
        ] = await Promise.all([
            // All-time revenue + commission
            (this.prisma as any).bookingPayment.aggregate({
                where: { status: 'PAID' },
                _sum: { totalAmount: true, platformFeeAmount: true },
            }),
            // This month revenue + commission
            (this.prisma as any).bookingPayment.aggregate({
                where: { status: 'PAID', paidAt: { gte: currentMonthStart } },
                _sum: { totalAmount: true, platformFeeAmount: true },
            }),
            // Last month revenue + commission
            (this.prisma as any).bookingPayment.aggregate({
                where: { status: 'PAID', paidAt: { gte: lastMonthStart, lt: currentMonthStart } },
                _sum: { totalAmount: true, platformFeeAmount: true },
            }),
            // Pending identity verifications
            (this.prisma as any).userVerification.count({
                where: { verificationStatus: 'PENDING' },
            }),
            // All members ever
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'MEMBER' } } } },
            }),
            // Members joined this month
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'MEMBER' } } }, createdAt: { gte: currentMonthStart } },
            }),
            // Members joined last month
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'MEMBER' } } }, createdAt: { gte: lastMonthStart, lt: currentMonthStart } },
            }),
            // Active members (isActive flag)
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'MEMBER' } } }, isActive: true },
            }),
            // Active members joined this month
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'MEMBER' } } }, isActive: true, createdAt: { gte: currentMonthStart } },
            }),
            // Active members joined last month
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'MEMBER' } } }, isActive: true, createdAt: { gte: lastMonthStart, lt: currentMonthStart } },
            }),
            // All trainers ever
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'TRAINER' } } } },
            }),
            // Trainers joined this month
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'TRAINER' } } }, createdAt: { gte: currentMonthStart } },
            }),
            // Trainers joined last month
            (this.prisma as any).user.count({
                where: { roles: { some: { role: { name: 'TRAINER' } } }, createdAt: { gte: lastMonthStart, lt: currentMonthStart } },
            }),
            // Active (non-trivial) bookings this week
            (this.prisma as any).booking.count({
                where: {
                    bookingStatus: { notIn: ['CANCELLED', 'EXPIRED', 'PAYMENT_FAILED', 'HELD'] },
                    createdAt: { gte: thisWeekStart },
                },
            }),
            // Same for last week
            (this.prisma as any).booking.count({
                where: {
                    bookingStatus: { notIn: ['CANCELLED', 'EXPIRED', 'PAYMENT_FAILED', 'HELD'] },
                    createdAt: { gte: lastWeekStart, lt: thisWeekStart },
                },
            }),
        ]);

        return {
            allTimeRevenue: Number(allTimeAgg._sum?.totalAmount ?? 0),
            allTimeCommission: Number(allTimeAgg._sum?.platformFeeAmount ?? 0),
            currentMonthRevenue: Number(currentMonthAgg._sum?.totalAmount ?? 0),
            lastMonthRevenue: Number(lastMonthAgg._sum?.totalAmount ?? 0),
            currentMonthCommission: Number(currentMonthAgg._sum?.platformFeeAmount ?? 0),
            lastMonthCommission: Number(lastMonthAgg._sum?.platformFeeAmount ?? 0),
            pendingVerificationsCount,
            totalMembersCount,
            newMembersThisMonth,
            newMembersLastMonth,
            activeMembersCount,
            newActiveMembersThisMonth,
            newActiveMembersLastMonth,
            totalTrainersCount,
            newTrainersThisMonth,
            newTrainersLastMonth,
            bookingsThisWeekCount,
            bookingsLastWeekCount,
        };
    }

    /**
     * Returns raw paid-payment rows and new-user rows within a date range,
     * used to build the Hiring & Revenue chart.
     */
    async getChartRawData(startDate: Date, endDate: Date): Promise<{
        payments: { paidAt: Date; totalAmount: any }[];
        newUsers: { createdAt: Date }[];
    }> {
        const [payments, newUsers] = await Promise.all([
            (this.prisma as any).bookingPayment.findMany({
                where: { status: 'PAID', paidAt: { gte: startDate, lt: endDate } },
                select: { paidAt: true, totalAmount: true },
            }),
            // Count new trainers + members (users with either role) created in range
            (this.prisma as any).user.findMany({
                where: {
                    createdAt: { gte: startDate, lt: endDate },
                    roles: { some: { role: { name: { in: ['MEMBER', 'TRAINER'] } } } },
                },
                select: { createdAt: true },
            }),
        ]);

        return { payments, newUsers };
    }

    /**
     * Returns the most recent significant events for the activity feed.
     * Fetches `limit` of each type, then the service merges and re-sorts them.
     */
    async getRecentActivityRawData(limit: number): Promise<{
        newMembers: { id: string; displayName: string | null; firstName: string | null; createdAt: Date }[];
        pendingVerifications: { createdAt: Date; user: { displayName: string | null; firstName: string | null } }[];
    }> {
        const [newMembers, pendingVerifications] = await Promise.all([
            (this.prisma as any).user.findMany({
                where: { roles: { some: { role: { name: 'MEMBER' } } } },
                select: { id: true, displayName: true, firstName: true, createdAt: true },
                orderBy: { createdAt: 'desc' },
                take: limit,
            }),
            (this.prisma as any).userVerification.findMany({
                where: { verificationStatus: 'PENDING' },
                select: {
                    createdAt: true,
                    user: { select: { displayName: true, firstName: true } },
                },
                orderBy: { createdAt: 'desc' },
                take: limit,
            }),
        ]);

        return { newMembers, pendingVerifications };
    }

    /** Per-trainer revenue breakdown (paginated). */
    async getTrainerRevenue(limit: number, offset: number): Promise<{ items: any[]; total: number }> {
        // Group bookingPayments by fitnessClass.trainerUserId
        const allPayments = await (this.prisma as any).bookingPayment.findMany({
            where: { status: 'PAID' },
            select: {
                totalAmount: true,
                platformFeeAmount: true,
                trainerPayoutAmount: true,
                fitnessClass: {
                    select: {
                        trainerUserId: true,
                        trainer: {
                            select: {
                                id: true,
                                displayName: true,
                                firstName: true,
                                profileImageUrl: true,
                            },
                        },
                    },
                },
            },
        });

        // Aggregate in-process (avoids raw SQL / unsupported groupBy with joins)
        const trainerMap = new Map<string, {
            trainerUserId: string;
            trainerName: string | null;
            profileImageUrl: string | null;
            totalGrossRevenue: number;
            totalPlatformFee: number;
            totalTrainerPayout: number;
            totalBookings: number;
        }>();

        for (const payment of allPayments) {
            const trainer = payment.fitnessClass?.trainer;
            if (!trainer) continue;
            const userId = trainer.id as string;
            const existing = trainerMap.get(userId);

            if (existing) {
                existing.totalGrossRevenue += Number(payment.totalAmount);
                existing.totalPlatformFee += Number(payment.platformFeeAmount);
                existing.totalTrainerPayout += Number(payment.trainerPayoutAmount);
                existing.totalBookings += 1;
            } else {
                trainerMap.set(userId, {
                    trainerUserId: userId,
                    trainerName: trainer.displayName ?? trainer.firstName ?? null,
                    profileImageUrl: trainer.profileImageUrl ?? null,
                    totalGrossRevenue: Number(payment.totalAmount),
                    totalPlatformFee: Number(payment.platformFeeAmount),
                    totalTrainerPayout: Number(payment.trainerPayoutAmount),
                    totalBookings: 1,
                });
            }
        }

        const sorted = Array.from(trainerMap.values())
            .sort((a, b) => b.totalGrossRevenue - a.totalGrossRevenue);

        return {
            total: sorted.length,
            items: sorted.slice(offset, offset + limit),
        };
    }

    // ─── Static content (Privacy Policy, Terms of Service, About Us) ──────────

    async listStaticContent(): Promise<any[]> {
        return (this.prisma as any).staticContent.findMany({
            where: {
                key: { in: ['privacy-policy', 'terms-of-service', 'about-us', 'privacy_policy', 'terms_of_service', 'about_us'] },
            },
            orderBy: { key: 'asc' },
        });
    }

    async findStaticContentByKey(key: string): Promise<any | null> {
        const keys = getStaticContentLookupKeys(key);
        const rows = await (this.prisma as any).staticContent.findMany({
            where: { key: { in: keys } },
        });

        return rows.find((row: any) => row.key === keys[0]) ?? rows[0] ?? null;
    }

    /** Creates the row if it does not exist yet, otherwise updates it. */
    async upsertStaticContent(key: string, title: string, content: string): Promise<any> {
        const existing = await this.findStaticContentByKey(key);
        if (existing) {
            return (this.prisma as any).staticContent.update({
                where: { id: existing.id },
                data: { key, title, content },
            });
        }

        return (this.prisma as any).staticContent.upsert({
            where: { key },
            create: { key, title, content },
            update: { title, content },
        });
    }
}
