import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { revenueApi } from '@/lib/api/revenue.api';
import type { EarningsPeriod } from '@/lib/types/revenue.types';

export const REVENUE_KEYS = {
  stats:           ['admin', 'revenue', 'stats']                                as const,
  earnings:        (period: EarningsPeriod, extra?: { date?: string; year?: number }) =>
                     ['admin', 'revenue', 'earnings', period, extra ?? {}]      as const,
  trainers:        (limit: number, offset: number) =>
                     ['admin', 'revenue', 'trainers', limit, offset]            as const,
  commission:      ['admin', 'commission']                                      as const,
};

export function useRevenueStats() {
  return useQuery({
    queryKey: REVENUE_KEYS.stats,
    queryFn:  revenueApi.getStats,
    staleTime: 60_000,
  });
}

export function useRevenueEarnings(
  period: EarningsPeriod = 'monthly',
  extra?: { date?: string; year?: number },
) {
  return useQuery({
    queryKey: REVENUE_KEYS.earnings(period, extra),
    queryFn:  () => revenueApi.getEarnings(period, extra),
    staleTime: 60_000,
  });
}

export function useTrainerRevenue(limit = 10, offset = 0) {
  return useQuery({
    queryKey: REVENUE_KEYS.trainers(limit, offset),
    queryFn:  () => revenueApi.getTrainerRevenue(limit, offset),
    staleTime: 60_000,
  });
}

export function useCommissionConfig() {
  return useQuery({
    queryKey: REVENUE_KEYS.commission,
    queryFn:  revenueApi.getCommission,
    staleTime: 300_000, // rarely changes — 5 min
  });
}

export function useUpdateCommission() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (rate: number) => revenueApi.updateCommission(rate),
    onSuccess: () => {
      // Refresh both commission config and stats (which shows currentCommissionRate)
      queryClient.invalidateQueries({ queryKey: REVENUE_KEYS.commission });
      queryClient.invalidateQueries({ queryKey: REVENUE_KEYS.stats });
    },
  });
}
