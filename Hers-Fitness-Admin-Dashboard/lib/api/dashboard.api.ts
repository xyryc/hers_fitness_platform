import { adminApiFetch } from '@/lib/auth-api';
import type {
  ActivityItem,
  ChartDataPoint,
  ChartRange,
  DashboardSummary,
} from '@/lib/types/dashboard.types';

const BASE = '/api/admin';

export const dashboardApi = {
  getSummary: () =>
    adminApiFetch<{ data: DashboardSummary }>(`${BASE}/dashboard/summary`).then(
      (res) => res.data,
    ),

  getChartData: (range: ChartRange = '7d') =>
    adminApiFetch<{ data: ChartDataPoint[] }>(
      `${BASE}/dashboard/chart-data?range=${range}`,
    ).then((res) => res.data),

  getActivities: (limit = 10) =>
    adminApiFetch<{ data: ActivityItem[] }>(
      `${BASE}/dashboard/activities?limit=${limit}`,
    ).then((res) => res.data),
};
