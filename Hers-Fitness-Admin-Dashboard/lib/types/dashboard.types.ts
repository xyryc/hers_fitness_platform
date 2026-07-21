// ── Summary ──────────────────────────────────────────────────────────────────

export interface MetricWithTrend {
  value: number;
  trend?: number; // % change vs previous period (positive = growth)
}

export interface DashboardSummary {
  totalRevenue:         MetricWithTrend;
  platformCommission:   MetricWithTrend;
  pendingVerifications: { value: number };
  totalMembers:         MetricWithTrend;
  activeMembers:        MetricWithTrend;
  trainers:             MetricWithTrend;
  bookingsThisWeek:     MetricWithTrend;
}

// ── Chart ─────────────────────────────────────────────────────────────────────

export type ChartRange = '7d' | '30d';

export interface ChartDataPoint {
  label:   string; // "Mon" / "25 Apr"
  revenue: number;
  hires:   number;
}

// ── Activities ────────────────────────────────────────────────────────────────

export type ActivityType = 'NEW_MEMBER' | 'PENDING_APPROVAL';

export interface ActivityItem {
  type:       ActivityType;
  title:      string;
  person:     string;
  occurredAt: string; // ISO 8601
}
