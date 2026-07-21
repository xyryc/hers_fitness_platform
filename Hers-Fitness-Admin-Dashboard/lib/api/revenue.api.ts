import { adminApiFetch } from '@/lib/auth-api';
import type {
  CommissionConfig,
  EarningsPeriod,
  RevenueEarnings,
  RevenueStats,
  TrainerRevenueList,
} from '@/lib/types/revenue.types';

const BASE = '/api/admin';

export const revenueApi = {
  getStats: () =>
    adminApiFetch<{ data: RevenueStats }>(`${BASE}/dashboard/revenue/stats`).then(
      (res) => res.data,
    ),

  getEarnings: (
    period: EarningsPeriod = 'monthly',
    extra?: { date?: string; year?: number },
  ) => {
    const params = new URLSearchParams({ period });
    if (extra?.date) params.set('date', extra.date);
    if (extra?.year != null) params.set('year', String(extra.year));

    return adminApiFetch<{ data: RevenueEarnings }>(
      `${BASE}/dashboard/revenue/earnings?${params.toString()}`,
    ).then((res) => res.data);
  },

  getTrainerRevenue: (limit = 10, offset = 0) =>
    adminApiFetch<{ data: TrainerRevenueList }>(
      `${BASE}/dashboard/revenue/trainers?limit=${limit}&offset=${offset}`,
    ).then((res) => res.data),

  getCommission: () =>
    adminApiFetch<{ data: CommissionConfig }>(`${BASE}/commission`).then(
      (res) => res.data,
    ),

  updateCommission: (commissionRate: number) =>
    adminApiFetch<{ data: CommissionConfig }>(
      `${BASE}/commission`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ commissionRate }),
      },
    ).then((res) => res.data),
};
