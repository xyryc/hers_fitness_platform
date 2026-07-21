"use client";

import Image from "next/image";
import { useMemo, useRef, useState } from "react";
import { toast } from "react-toastify";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import {
  useCommissionConfig,
  useRevenueEarnings,
  useRevenueStats,
  useTrainerRevenue,
  useUpdateCommission,
} from "@/hooks/use-revenue";
import type { EarningsPeriod, EarningsDataPoint } from "@/lib/types/revenue.types";
import { cn } from "@/lib/utils";

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function fmtMoney(val: string | number) {
  const n = typeof val === "string" ? parseFloat(val) : val;
  if (Number.isNaN(n)) return "—";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(n);
}

function fmtNum(val: number) {
  return new Intl.NumberFormat("en-US").format(val);
}

function todayISO() {
  return new Date().toISOString().split("T")[0];
}

function currentYear() {
  return new Date().getFullYear();
}

// ─────────────────────────────────────────────────────────────────────────────
// Main section
// ─────────────────────────────────────────────────────────────────────────────

export function RevenueSection() {
  return (
    <section
      id="revenue"
      aria-labelledby="revenue-title"
      className="flex w-full flex-col gap-6 pb-6"
    >
      <h1 id="revenue-title" className="sr-only">
        Revenue
      </h1>

      {/* Stats + Commission */}
      <RevenueStatsGrid />

      {/* Earnings chart */}
      <EarningsChart />

      {/* Trainer revenue table */}
      <TrainerRevenueTable />
    </section>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats grid
// ─────────────────────────────────────────────────────────────────────────────

function RevenueStatsGrid() {
  const { data: stats, isLoading: statsLoading } = useRevenueStats();
  const { data: commission, isLoading: commLoading } = useCommissionConfig();

  const isLoading = statsLoading || commLoading;

  const tiles = stats
    ? [
        {
          label: "Total Gross Revenue",
          value: fmtMoney(stats.totalGrossRevenue),
          icon: <DollarCircleIcon className="size-6 text-[#f7869a]" />,
          accent: false,
        },
        {
          label: "Platform Commission",
          value: fmtMoney(stats.totalPlatformFee),
          icon: <PercentIcon className="size-6 text-[#f7869a]" />,
          accent: false,
        },
        {
          label: "Trainer Payouts",
          value: fmtMoney(stats.totalTrainerPayout),
          icon: <WalletIcon className="size-6 text-[#16a34a]" />,
          accent: false,
        },
        {
          label: "Paid Bookings",
          value: fmtNum(stats.totalPaidBookings),
          icon: <BookingIcon className="size-6 text-[#f7869a]" />,
          accent: false,
        },
        {
          label: "Active Trainers",
          value: fmtNum(stats.activeTrainerCount),
          icon: <TrainerRevenueIcon className="size-6 text-[#f7869a]" />,
          accent: false,
        },
      ]
    : Array.from({ length: 5 }, (_, i) => ({
        label: ["Total Gross Revenue", "Platform Commission", "Trainer Payouts", "Paid Bookings", "Active Trainers"][i],
        value: "—",
        icon: <div className="size-6 rounded bg-[#f2f2f2]" />,
        accent: false,
      }));

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {tiles.map((tile) => (
        <RevenueTile
          key={tile.label}
          label={tile.label}
          value={tile.value}
          icon={tile.icon}
          isLoading={isLoading}
        />
      ))}

      {/* Commission rate tile — spans remaining space */}
      <CommissionTile
        currentRate={commission?.commissionRate}
        isLoading={commLoading}
      />
    </div>
  );
}

function RevenueTile({
  label,
  value,
  icon,
  isLoading,
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  isLoading: boolean;
}) {
  return (
    <Card className="relative min-h-[120px] overflow-hidden border-[0.5px] border-[rgba(247,134,154,0.3)] bg-[rgba(247,134,154,0.06)] p-5 shadow-[0_1px_2px_rgba(0,0,0,0.04)] transition-all duration-200 hover:-translate-y-0.5 hover:border-[#f7869a] hover:shadow-md">
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 flex-1 flex-col gap-2">
          <p className="text-sm font-medium leading-5 text-[#7a7a7a]">{label}</p>
          {isLoading ? (
            <div className="h-8 w-28 animate-pulse rounded-lg bg-[#f2f2f2]" />
          ) : (
            <p className="text-[28px] font-bold leading-none text-[#121212]">
              {value}
            </p>
          )}
        </div>
        <span className="flex size-10 shrink-0 items-center justify-center rounded-[10px] bg-white shadow-sm">
          {icon}
        </span>
      </div>
    </Card>
  );
}

function CommissionTile({
  currentRate,
  isLoading,
}: {
  currentRate?: string;
  isLoading: boolean;
}) {
  const [isEditing, setIsEditing] = useState(false);
  const [draft, setDraft] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const updateMutation = useUpdateCommission();

  const handleEdit = () => {
    setDraft(currentRate ?? "");
    setIsEditing(true);
    setTimeout(() => inputRef.current?.select(), 0);
  };

  const handleCancel = () => {
    setIsEditing(false);
    setDraft("");
  };

  const handleSave = () => {
    const parsed = parseFloat(draft);
    if (Number.isNaN(parsed) || parsed < 0 || parsed > 100) {
      toast.error("Commission rate must be between 0 and 100.");
      return;
    }
    updateMutation.mutate(parsed, {
      onSuccess: () => {
        toast.success("Commission rate updated successfully.");
        setIsEditing(false);
        setDraft("");
      },
      onError: (err) => {
        toast.error(
          err instanceof Error ? err.message : "Failed to update commission rate.",
        );
      },
    });
  };

  return (
    <Card className="relative min-h-[120px] overflow-hidden border-[0.5px] border-[rgba(247,134,154,0.3)] bg-[rgba(247,134,154,0.06)] p-5 shadow-[0_1px_2px_rgba(0,0,0,0.04)] transition-all duration-200 hover:-translate-y-0.5 hover:border-[#f7869a] hover:shadow-md">
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 flex-1 flex-col gap-2">
          <p className="text-sm font-medium leading-5 text-[#7a7a7a]">
            Commission Rate
          </p>

          {isLoading ? (
            <div className="h-8 w-20 animate-pulse rounded-lg bg-[#f2f2f2]" />
          ) : isEditing ? (
            <div className="flex items-center gap-2">
              <div className="relative flex items-center">
                <input
                  ref={inputRef}
                  type="number"
                  min={0}
                  max={100}
                  step={0.01}
                  value={draft}
                  onChange={(e) => setDraft(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleSave();
                    if (e.key === "Escape") handleCancel();
                  }}
                  className="h-9 w-20 rounded-lg border border-[#f7869a] bg-white px-3 pr-6 text-sm font-medium text-[#121212] outline-none ring-4 ring-[#f7869a]/15"
                />
                <span className="pointer-events-none absolute right-2 text-sm font-medium text-[#7a7a7a]">
                  %
                </span>
              </div>
              <button
                type="button"
                onClick={handleSave}
                disabled={updateMutation.isPending}
                className="flex h-9 items-center justify-center rounded-lg bg-[#f7869a] px-3 text-xs font-semibold text-white transition-opacity hover:opacity-90 disabled:opacity-60"
              >
                {updateMutation.isPending ? "…" : "Save"}
              </button>
              <button
                type="button"
                onClick={handleCancel}
                className="flex h-9 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-3 text-xs font-semibold text-[#4a4a4a] transition-colors hover:bg-[#f7f7f7]"
              >
                Cancel
              </button>
            </div>
          ) : (
            <p className="text-[28px] font-bold leading-none text-[#121212]">
              {currentRate ? `${parseFloat(currentRate).toFixed(1)}%` : "—"}
            </p>
          )}

          {!isLoading && !isEditing && (
            <p className="text-xs font-normal text-[#7a7a7a]">
              Applies to future bookings only
            </p>
          )}
        </div>

        {!isEditing && (
          <button
            type="button"
            onClick={handleEdit}
            disabled={isLoading}
            className="flex size-10 shrink-0 items-center justify-center rounded-[10px] bg-white shadow-sm transition-colors hover:bg-[#fdf2f4] hover:text-[#f7869a] disabled:opacity-50"
            aria-label="Edit commission rate"
          >
            <EditPenIcon className="size-5 text-[#7a7a7a]" />
          </button>
        )}
      </div>
    </Card>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Earnings chart
// ─────────────────────────────────────────────────────────────────────────────

const PERIOD_OPTIONS: Array<{ label: string; value: EarningsPeriod }> = [
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
  { label: "Yearly", value: "yearly" },
];

function EarningsChart() {
  const [period, setPeriod] = useState<EarningsPeriod>("monthly");
  const [year, setYear] = useState(currentYear());

  // For weekly we always send today's date; the API returns the containing week
  const extra = useMemo(() => {
    if (period === "weekly") return { date: todayISO() };
    if (period === "monthly") return { year };
    return undefined;
  }, [period, year]);

  const { data, isLoading } = useRevenueEarnings(period, extra);

  const points: EarningsDataPoint[] = data?.data ?? [];

  // Dynamic max (rounded to a nice ceiling)
  const rawMax = points.reduce(
    (m, p) => Math.max(m, p.grossRevenue),
    0,
  );
  const chartMax = rawMax <= 0 ? 1000 : Math.ceil(rawMax / 1000) * 1000;

  // Axis labels: 5 steps
  const axisLabels = Array.from({ length: 5 }, (_, i) => {
    const v = chartMax * (1 - i / 4);
    return v >= 1000 ? `${(v / 1000).toFixed(0)}k` : String(v);
  });

  const visibleLabels = useMemo(() => {
    if (period === "weekly") return new Set(points.map((p) => p.label));
    if (period === "monthly") return new Set(["Jan", "Mar", "May", "Jul", "Sep", "Nov"]);
    return new Set(points.map((p) => p.label));
  }, [period, points]);

  const weekLabel =
    data?.weekStartDate && data?.weekEndDate
      ? `${fmtDate(data.weekStartDate)} – ${fmtDate(data.weekEndDate)}`
      : null;

  return (
    <Card className="rounded-[10px] border-[#e0e0e0] bg-white p-4 shadow-none sm:p-5">
      <CardHeader className="mb-4 flex flex-col items-start justify-between gap-4 sm:mb-5 sm:flex-row">
        <div>
          <h2 className="text-xl font-medium leading-7 text-[#121212] sm:text-2xl sm:leading-8">
            Earnings Overview
          </h2>
          {weekLabel && period === "weekly" ? (
            <p className="mt-0.5 text-sm font-normal text-[#7a7a7a]">{weekLabel}</p>
          ) : null}
          {period === "monthly" ? (
            <div className="mt-1 flex items-center gap-2">
              <button
                type="button"
                onClick={() => setYear((y) => y - 1)}
                className="flex size-6 items-center justify-center rounded text-[#7a7a7a] hover:bg-[#f7f7f7] hover:text-[#121212]"
                aria-label="Previous year"
              >
                <ChevronLeftSmIcon />
              </button>
              <span className="text-sm font-semibold text-[#121212]">{year}</span>
              <button
                type="button"
                onClick={() => setYear((y) => y + 1)}
                className="flex size-6 items-center justify-center rounded text-[#7a7a7a] hover:bg-[#f7f7f7] hover:text-[#121212]"
                aria-label="Next year"
              >
                <ChevronRightSmIcon />
              </button>
            </div>
          ) : null}
        </div>

        <div className="flex w-full items-center gap-3 sm:w-auto">
          {/* Legend */}
          <div className="hidden items-center gap-4 text-xs font-medium text-[#7a7a7a] lg:flex">
            <span className="flex items-center gap-1.5">
              <span className="inline-block size-2.5 rounded-sm bg-[#fbc3cc]" />
              Gross
            </span>
            <span className="flex items-center gap-1.5">
              <span className="inline-block size-2.5 rounded-sm bg-[#121212] opacity-70" />
              Platform fee
            </span>
          </div>

          <div
            className="flex rounded-[14px] bg-white p-1 shadow-[0_1px_3px_rgba(0,0,0,0.1)]"
            role="group"
            aria-label="Chart period"
          >
            {PERIOD_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                type="button"
                variant={period === opt.value ? "default" : "ghost"}
                className={cn(
                  "h-10 rounded-[10px] px-3 text-sm",
                  period === opt.value
                    ? "bg-[#f7869a] text-white hover:bg-[#f7869a]"
                    : "hover:bg-[#fdf2f4]",
                )}
                aria-pressed={period === opt.value}
                onClick={() => setPeriod(opt.value)}
              >
                {opt.label}
              </Button>
            ))}
          </div>
        </div>
      </CardHeader>

      <CardContent className="min-h-0 overflow-x-auto overflow-y-hidden pb-2">
        {isLoading ? (
          <div className="flex h-[300px] items-center justify-center sm:h-[340px]">
            <div className="flex flex-col items-center gap-2 text-sm font-medium text-[#7a7a7a]">
              <div className="size-8 animate-spin rounded-full border-2 border-[#f7869a] border-t-transparent" />
              Loading earnings…
            </div>
          </div>
        ) : points.length === 0 ? (
          <div className="flex h-[300px] items-center justify-center rounded-xl border border-dashed border-[#e0e0e0] bg-[#fafafa] text-sm font-medium text-[#7a7a7a] sm:h-[340px]">
            No earnings data for this period.
          </div>
        ) : (
          <div
            className={cn(
              "grid h-[300px] grid-cols-[36px_minmax(0,1fr)] grid-rows-[1fr_24px] sm:h-[340px]",
              period === "weekly"
                ? "min-w-[400px] sm:min-w-[560px]"
                : period === "yearly"
                  ? "min-w-[400px]"
                  : "min-w-[560px]",
            )}
          >
            {/* Y-axis */}
            <div className="flex h-full flex-col items-end justify-between px-1 text-xs leading-4 text-[#7a7a7a]">
              {axisLabels.map((l) => (
                <span key={l}>{l}</span>
              ))}
            </div>

            {/* Chart area */}
            <div className="relative border-b border-[rgba(0,0,26,0.3)]">
              {/* Horizontal grid lines */}
              <div className="absolute inset-0 grid grid-rows-5">
                {Array.from({ length: 5 }).map((_, i) => (
                  <span key={i} className="border-t border-dashed border-[#d5d9e3]" />
                ))}
              </div>
              {/* Vertical grid lines */}
              <div
                className="absolute inset-0 grid"
                style={{ gridTemplateColumns: `repeat(${points.length}, minmax(0, 1fr))` }}
              >
                {points.map((p) => (
                  <span key={p.key} className="border-l border-dashed border-[#d5d9e3]" />
                ))}
              </div>

              {/* Bars */}
              <div className="relative flex h-full items-end">
                {points.map((point, idx) => (
                  <EarningsBar
                    key={point.key}
                    point={point}
                    chartMax={chartMax}
                    compact={period === "monthly"}
                    tooltipAlign={
                      idx === 0 ? "start" : idx === points.length - 1 ? "end" : "center"
                    }
                  />
                ))}
              </div>
            </div>

            {/* spacer */}
            <div />

            {/* X-axis labels */}
            <div className="flex text-center text-xs leading-4 text-[#7a7a7a]">
              {points.map((p) => (
                <span key={p.key} className="flex-1">
                  {visibleLabels.has(p.label) ? p.label : ""}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Totals footer */}
        {!isLoading && data && (
          <div className="mt-4 grid grid-cols-3 divide-x divide-[#f2f2f2] rounded-xl border border-[#f2f2f2] bg-[#fafafa]">
            <EarningsSummaryCell label="Gross Revenue" value={fmtMoney(data.totalGrossRevenue)} />
            <EarningsSummaryCell label="Platform Fee" value={fmtMoney(data.totalPlatformFee)} />
            <EarningsSummaryCell label="Trainer Payout" value={fmtMoney(data.totalTrainerPayout)} />
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function EarningsBar({
  point,
  chartMax,
  compact,
  tooltipAlign,
}: {
  point: EarningsDataPoint;
  chartMax: number;
  compact: boolean;
  tooltipAlign: "start" | "center" | "end";
}) {
  const grossH = `${Math.max(2, (point.grossRevenue / chartMax) * 100)}%`;
  const feeH = `${Math.max(1, (point.platformFee / chartMax) * 100)}%`;
  const barW = compact ? "w-[16px] sm:w-[20px]" : "w-[44px]";
  const bgW = compact ? "w-[20px] sm:w-[24px]" : "w-[36px]";

  return (
    <button
      type="button"
      className="group relative flex h-full flex-1 justify-center px-1 outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
      aria-label={`${point.label}: gross ${fmtMoney(point.grossRevenue)}, platform fee ${fmtMoney(point.platformFee)}, payout ${fmtMoney(point.trainerPayout)}`}
    >
      {/* background column */}
      <span
        aria-hidden="true"
        className={cn("absolute bottom-0 top-0 bg-[#eef0f7] opacity-80", bgW)}
      />

      <span className={cn("relative flex h-full items-end", barW)}>
        {/* platform fee bar (dark, back layer) */}
        {point.platformFee > 0 && (
          <span
            aria-hidden="true"
            className="absolute bottom-0 w-full rounded-t-[5px] bg-[#121212] opacity-65 transition-opacity group-hover:opacity-80"
            style={{ height: feeH }}
          />
        )}
        {/* gross revenue bar (pink, front layer) */}
        {point.grossRevenue > 0 && (
          <span
            aria-hidden="true"
            className="absolute bottom-0 w-full rounded-t-[5px] bg-[#fbc3cc] transition-colors group-hover:bg-[#f9aaba]"
            style={{ height: grossH }}
          />
        )}
      </span>

      {/* Tooltip */}
      <span
        className={cn(
          "pointer-events-none absolute top-2 z-10 flex translate-y-1 flex-col items-center text-left text-xs leading-[18px] text-white opacity-0 transition group-hover:translate-y-0 group-hover:opacity-100 group-focus-visible:translate-y-0 group-focus-visible:opacity-100",
          tooltipAlign === "start" && "left-1",
          tooltipAlign === "center" && "left-1/2 -translate-x-1/2",
          tooltipAlign === "end" && "right-1",
        )}
      >
        <span className="min-w-[120px] rounded-lg bg-[#f7869a] px-3 py-1.5 shadow-[0_8px_18px_rgba(247,134,154,0.28)]">
          <span className="block font-semibold">{point.label}</span>
          <span className="block">Gross: {fmtMoney(point.grossRevenue)}</span>
          <span className="block">Fee: {fmtMoney(point.platformFee)}</span>
          <span className="block">Payout: {fmtMoney(point.trainerPayout)}</span>
        </span>
        <span className="h-0 w-0 border-x-[5px] border-t-[6px] border-x-transparent border-t-[#f7869a]" />
      </span>
    </button>
  );
}

function EarningsSummaryCell({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className="flex flex-col items-center gap-0.5 px-4 py-3">
      <p className="text-xs font-medium text-[#7a7a7a]">{label}</p>
      <p className="text-base font-bold text-[#121212]">{value}</p>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Trainer revenue table
// ─────────────────────────────────────────────────────────────────────────────

const PAGE_SIZE = 10;

function TrainerRevenueTable() {
  const [offset, setOffset] = useState(0);
  const { data, isLoading, isError, error, refetch } = useTrainerRevenue(
    PAGE_SIZE,
    offset,
  );

  const items = data?.items ?? [];
  const total = data?.total ?? 0;
  const page = Math.floor(offset / PAGE_SIZE) + 1;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const from = total === 0 ? 0 : offset + 1;
  const to = Math.min(offset + PAGE_SIZE, total);

  return (
    <Card className="flex min-h-0 flex-col gap-[14px] overflow-hidden rounded-[14px] border-[#e3e6f0] bg-white px-3 py-3.5 shadow-none">
      <div className="flex shrink-0 flex-col gap-2 sm:flex-row sm:items-center">
        <div className="min-w-0 flex-1">
          <h2 className="text-xl font-medium leading-8 tracking-[0.12px] text-[#1e293b]">
            Trainer Revenue Breakdown
          </h2>
          <p className="text-sm font-normal text-[#7a7a7a]">
            Sorted by highest earnings
          </p>
        </div>
      </div>

      <div className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-lg border border-[#c4cdd5]">
        <div className="min-h-0 flex-1 overflow-auto">
          <table className="w-full min-w-[780px] border-collapse text-left">
            <thead className="sticky top-0 z-10">
              <tr className="h-[52px] bg-white text-sm font-semibold leading-[22px] tracking-[0.22px] text-[#1c252e]">
                <TrainerTh className="w-[36%]">Trainer</TrainerTh>
                <TrainerTh className="w-[18%]">Gross Revenue</TrainerTh>
                <TrainerTh className="w-[16%]">Platform Fee</TrainerTh>
                <TrainerTh className="w-[18%]">Payout</TrainerTh>
                <TrainerTh className="w-[12%] text-right">Bookings</TrainerTh>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center text-sm font-medium text-[#7a7a7a]">
                    <div className="flex items-center justify-center gap-2">
                      <div className="size-5 animate-spin rounded-full border-2 border-[#f7869a] border-t-transparent" />
                      Loading trainer data…
                    </div>
                  </td>
                </tr>
              ) : isError ? (
                <tr>
                  <td colSpan={5} className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <p className="text-sm font-medium text-[#dc2626]">
                        {error instanceof Error ? error.message : "Unable to load trainer data."}
                      </p>
                      <button
                        type="button"
                        onClick={() => refetch()}
                        className="rounded-lg bg-[#fdf2f4] px-4 py-2 text-sm font-medium text-[#121212] transition-colors hover:bg-[#f9e8ec]"
                      >
                        Retry
                      </button>
                    </div>
                  </td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan={5} className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center text-sm font-medium text-[#7a7a7a]">
                    No trainer revenue data yet.
                  </td>
                </tr>
              ) : (
                items.map((trainer, idx) => (
                  <tr key={trainer.trainerUserId} className="h-[52px] bg-white">
                    {/* Rank + avatar + name */}
                    <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                      <div className="flex min-w-0 items-center gap-3">
                        <span className="flex size-6 shrink-0 items-center justify-center rounded-full bg-[#fdf2f4] text-xs font-semibold text-[#f7869a]">
                          {offset + idx + 1}
                        </span>
                        {trainer.profileImageUrl ? (
                          <Image
                            src={trainer.profileImageUrl}
                            alt=""
                            width={32}
                            height={32}
                            className="size-8 shrink-0 rounded-full object-cover"
                          />
                        ) : (
                          <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-[#f2f2f2] text-xs font-semibold text-[#7a7a7a]">
                            {(trainer.trainerName ?? "?")[0]?.toUpperCase()}
                          </div>
                        )}
                        <span className="truncate text-sm font-medium text-[#1c252e]">
                          {trainer.trainerName ?? "Unknown Trainer"}
                        </span>
                      </div>
                    </td>
                    <TrainerTd>{fmtMoney(trainer.totalGrossRevenue)}</TrainerTd>
                    <TrainerTd>
                      <span className="inline-flex h-6 items-center rounded bg-[#fef3c7] px-2 text-xs font-semibold text-[#d97706]">
                        {fmtMoney(trainer.totalPlatformFee)}
                      </span>
                    </TrainerTd>
                    <TrainerTd>
                      <span className="inline-flex h-6 items-center rounded bg-[#dcfce7] px-2 text-xs font-semibold text-[#16a34a]">
                        {fmtMoney(trainer.totalTrainerPayout)}
                      </span>
                    </TrainerTd>
                    <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-right text-sm font-medium text-[#1c252e]">
                      {fmtNum(trainer.totalBookings)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex h-14 shrink-0 items-center justify-between bg-white px-4 text-sm text-[#1c252e]">
          <p className="text-xs font-normal text-[#7a7a7a]">
            {total === 0 ? "No results" : `${from}–${to} of ${total} trainers`}
          </p>
          <div className="flex items-center gap-3">
            <span className="text-xs font-medium text-[#4a4a4a]">
              Page {page} / {totalPages}
            </span>
            <div className="flex items-center gap-1">
              <button
                type="button"
                disabled={offset === 0}
                onClick={() => setOffset(Math.max(0, offset - PAGE_SIZE))}
                className="flex size-7 items-center justify-center rounded-md text-[#454f5b] transition-colors hover:bg-[#f7f7f7] disabled:opacity-40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
                aria-label="Previous page"
              >
                <ChevronLeftSmIcon />
              </button>
              <button
                type="button"
                disabled={offset + PAGE_SIZE >= total}
                onClick={() => setOffset(offset + PAGE_SIZE)}
                className="flex size-7 items-center justify-center rounded-md text-[#454f5b] transition-colors hover:bg-[#f7f7f7] disabled:opacity-40 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
                aria-label="Next page"
              >
                <ChevronRightSmIcon />
              </button>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}

function TrainerTh({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <th className={cn("border-b border-[#c4cdd5] px-3 py-2", className)}>
      <div className="border-r border-[#c4cdd5] last:border-r-0">{children}</div>
    </th>
  );
}

function TrainerTd({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <td
      className={cn(
        "border-b border-dashed border-[#c4cdd5] px-3 py-2 text-sm font-normal leading-[22px] tracking-[0.22px] text-[#1c252e]",
        className,
      )}
    >
      {children}
    </td>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Date helpers
// ─────────────────────────────────────────────────────────────────────────────

function fmtDate(iso: string) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric" }).format(d);
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline icons (all SVG, matching the rest of the codebase style)
// ─────────────────────────────────────────────────────────────────────────────

function DollarCircleIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.7" />
      <path d="M12 7v1m0 8v1m3-6.5a3 3 0 0 0-3-1.5 2.5 2.5 0 0 0 0 5 2.5 2.5 0 0 1 0 5A3 3 0 0 1 9 18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function PercentIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="8.5" cy="8.5" r="2.5" stroke="currentColor" strokeWidth="1.7" />
      <circle cx="15.5" cy="15.5" r="2.5" stroke="currentColor" strokeWidth="1.7" />
      <path d="m18 6-12 12" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function WalletIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="2" y="7" width="20" height="13" rx="2.5" stroke="currentColor" strokeWidth="1.7" />
      <path d="M2 11h20M16 15.5h.01" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <path d="M6 7V5.5A2.5 2.5 0 0 1 8.5 3h7A2.5 2.5 0 0 1 18 5.5V7" stroke="currentColor" strokeWidth="1.7" />
    </svg>
  );
}

function BookingIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="4" y="5" width="16" height="16" rx="2.5" stroke="currentColor" strokeWidth="1.7" />
      <path d="M16 3v4M8 3v4M4 11h16M8 15h.01M12 15h.01M16 15h.01M8 19h.01M12 19h.01" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function TrainerRevenueIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="9" cy="7" r="4" stroke="currentColor" strokeWidth="1.7" />
      <path d="M3 21v-1a6 6 0 0 1 6-6h0" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <path d="M17 14v7M14 17l3-3 3 3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function EditPenIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m14.5 5.5 4 4L7 21H3v-4L14.5 5.5Z" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      <path d="m11.5 8.5 4 4" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function ChevronLeftSmIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={cn("size-4", className)} aria-hidden="true">
      <path d="m15 6-6 6 6 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ChevronRightSmIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={cn("size-4", className)} aria-hidden="true">
      <path d="m9 6 6 6-6 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
