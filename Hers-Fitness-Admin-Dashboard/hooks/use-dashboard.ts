import { useQuery } from '@tanstack/react-query';

import { dashboardApi } from '@/lib/api/dashboard.api';
import type { ChartRange } from '@/lib/types/dashboard.types';

export const DASHBOARD_KEYS = {
  summary:    ['admin', 'dashboard', 'summary']               as const,
  chart:      (range: ChartRange) => ['admin', 'dashboard', 'chart', range]      as const,
  activities: (limit: number)     => ['admin', 'dashboard', 'activities', limit] as const,
};

export function useDashboardSummary() {
  return useQuery({
    queryKey: DASHBOARD_KEYS.summary,
    queryFn:  dashboardApi.getSummary,
    staleTime: 60_000,
  });
}

export function useDashboardChart(range: ChartRange = '7d') {
  return useQuery({
    queryKey: DASHBOARD_KEYS.chart(range),
    queryFn:  () => dashboardApi.getChartData(range),
    staleTime: 60_000,
  });
}

export function useDashboardActivities(limit = 10) {
  return useQuery({
    queryKey: DASHBOARD_KEYS.activities(limit),
    queryFn:  () => dashboardApi.getActivities(limit),
    staleTime: 30_000,
  });
}
