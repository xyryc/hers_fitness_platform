"use client";

import { useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { useDashboardChart } from "@/hooks/use-dashboard";
import type { ChartRange } from "@/lib/types/dashboard.types";
import { cn } from "@/lib/utils";

type Range = ChartRange;

type ChartPoint = {
  label: string;
  revenue: number;
  hires: number;
};

// Fallback data used while the API response is loading
const fallbackWeekly: ChartPoint[] = [
  { label: "Mon", revenue: 0, hires: 12 },
  { label: "Tue", revenue: 29000, hires: 32 },
  { label: "Wed", revenue: 30000, hires: 30 },
  { label: "Thu", revenue: 26000, hires: 26 },
  { label: "Fri", revenue: 23000, hires: 20 },
  { label: "Sat", revenue: 30000, hires: 30 },
  { label: "Sun", revenue: 27000, hires: 27 },
];

const fallbackMonthly: ChartPoint[] = Array.from({ length: 30 }, (_, index) => {
  const day = index + 1;
  const revenuePattern = [
    12000, 18000, 24000, 17000, 29000, 22000, 27000, 31000, 19000, 26000,
    33000, 21000, 25000, 30000, 28000,
  ];
  const hiresPattern = [11, 16, 22, 18, 32, 21, 27, 34, 17, 26, 35, 20, 24, 30, 28];

  return {
    label: String(day),
    revenue: revenuePattern[index % revenuePattern.length],
    hires: hiresPattern[index % hiresPattern.length],
  };
});

const ranges: Array<{ label: string; value: Range }> = [
  { label: "7 Days", value: "7d" },
  { label: "30 Days", value: "30d" },
];

const revenueMax = 40000;
const hiresMax = 40;

export function RevenueChart() {
  const [range, setRange] = useState<Range>("7d");
  const { data: apiData, isLoading } = useDashboardChart(range);

  const data: ChartPoint[] =
    !isLoading && apiData && apiData.length > 0
      ? apiData
      : range === "7d"
        ? fallbackWeekly
        : fallbackMonthly;

  const visibleLabels = useMemo(() => {
    if (range === "7d") {
      return new Set(data.map((item) => item.label));
    }

    return new Set(["1", "5", "10", "15", "20", "25", "30"]);
  }, [data, range]);

  return (
    <Card className="min-h-[430px] rounded-[10px] border-[#e0e0e0] bg-white p-4 shadow-none sm:min-h-[450px] sm:p-5 xl:col-span-2">
      <CardHeader className="mb-4 flex flex-col items-start justify-between gap-4 sm:mb-5 sm:flex-row">
        <h2 className="text-xl font-medium leading-7 text-[#121212] sm:text-2xl sm:leading-8">
          Hiring & Revenue
        </h2>
        <div
          className="flex w-full rounded-[14px] bg-white p-1 shadow-[0_1px_3px_rgba(0,0,0,0.1)] sm:w-auto"
          aria-label="Chart range"
          role="group"
        >
          {ranges.map((item) => (
            <Button
              key={item.value}
              type="button"
              variant={range === item.value ? "default" : "ghost"}
              className={cn(
                "h-10 flex-1 rounded-[10px] px-2 text-sm sm:flex-none sm:px-3",
                range === item.value
                  ? "bg-[#f7869a] text-white hover:bg-[#f7869a]"
                  : "hover:bg-[#fdf2f4]",
              )}
              aria-pressed={range === item.value}
              onClick={() => setRange(item.value)}
            >
              <CalendarIcon className="mr-2 size-4" />
              {item.label}
            </Button>
          ))}
        </div>
      </CardHeader>
      <CardContent className="min-h-0 flex-1 overflow-x-auto overflow-y-hidden pb-2">
        <div
          className={cn(
            "grid h-[300px] grid-cols-[30px_minmax(0,1fr)_23px] grid-rows-[1fr_24px] sm:h-85",
            range === "7d" ? "min-w-[430px] sm:min-w-[600px]" : "min-w-[600px]",
          )}
        >
          <AxisLabels labels={["40k", "30k", "20k", "10k", "0k"]} />
          <div className="relative border-b border-[rgba(0,0,26,0.3)]">
            <div className="absolute inset-0 grid grid-rows-5">
              {Array.from({ length: 5 }).map((_, index) => (
                <span
                  key={index}
                  className="border-t border-dashed border-[#d5d9e3]"
                />
              ))}
            </div>
            <div
              className="absolute inset-0 grid"
              style={{ gridTemplateColumns: `repeat(${data.length}, minmax(0, 1fr))` }}
            >
              {data.map((item) => (
                <span
                  key={item.label}
                  className="border-l border-dashed border-[#d5d9e3]"
                />
              ))}
            </div>
            <div className="relative flex h-full items-end">
              {data.map((item, index) => (
                <ChartBar
                  key={item.label}
                  item={item}
                  compact={range === "30d"}
                  tooltipAlign={
                    index === 0
                      ? "start"
                      : index === data.length - 1
                        ? "end"
                        : "center"
                  }
                />
              ))}
            </div>
          </div>
          <AxisLabels labels={["40", "30", "20", "10", "0"]} />
          <div />
          <div className="flex pl-[29px] text-center text-xs leading-4 text-[#7a7a7a]">
            {data.map((item) => (
              <span key={item.label} className="flex-1">
                {visibleLabels.has(item.label) ? item.label : ""}
              </span>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ChartBar({
  item,
  compact,
  tooltipAlign,
}: {
  item: ChartPoint;
  compact: boolean;
  tooltipAlign: "start" | "center" | "end";
}) {
  const revenueHeight = `${Math.max(2, (item.revenue / revenueMax) * 100)}%`;
  const hiresHeight = `${Math.max(2, (item.hires / hiresMax) * 100)}%`;
  const barWidth = compact ? "w-[15px] sm:w-[18px]" : "w-[47px]";
  const bgWidth = compact ? "w-[18px] sm:w-[22px]" : "w-[37px]";

  return (
    <button
      type="button"
      className="group relative flex h-full flex-1 justify-center px-1 outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
      aria-label={`${item.label}: revenue ${item.revenue.toLocaleString()}, hires ${item.hires}`}
    >
      <span
        aria-hidden="true"
        className={cn("absolute bottom-0 top-0 bg-[#eef0f7] opacity-80", bgWidth)}
      />
      <span className={cn("relative flex h-full items-end", barWidth)}>
        <span
          aria-hidden="true"
          className="absolute bottom-0 w-full rounded-t-[5px] bg-black opacity-70 transition-opacity group-hover:opacity-80 group-focus-visible:opacity-80"
          style={{ height: hiresHeight }}
        />
        {item.revenue > 0 ? (
          <span
            aria-hidden="true"
            className="absolute bottom-0 w-full rounded-t-[5px] bg-[#fbc3cc] transition-colors group-hover:bg-[#f9aaba] group-focus-visible:bg-[#f9aaba]"
            style={{ height: revenueHeight }}
          />
        ) : null}
      </span>
      <span
        className={cn(
          "pointer-events-none absolute top-2 z-10 flex translate-y-1 flex-col items-center text-left text-xs leading-[18px] text-white opacity-0 transition group-hover:translate-y-0 group-hover:opacity-100 group-focus-visible:translate-y-0 group-focus-visible:opacity-100",
          tooltipAlign === "start" && "left-1",
          tooltipAlign === "center" && "left-1/2 -translate-x-1/2",
          tooltipAlign === "end" && "right-1",
        )}
      >
        <span className="min-w-[104px] rounded-lg bg-[#f7869a] px-3 py-1 shadow-[0_8px_18px_rgba(247,134,154,0.28)]">
          <span className="block">{item.label}</span>
          <span className="block">Rev :{item.revenue.toLocaleString()}</span>
          <span className="block">Hire : {item.hires}</span>
        </span>
        <span className="h-0 w-0 border-x-[5px] border-t-[6px] border-x-transparent border-t-[#f7869a]" />
      </span>
    </button>
  );
}

function AxisLabels({ labels }: { labels: string[] }) {
  return (
    <div className="flex h-full flex-col items-end justify-between px-1 text-xs leading-4 text-[#7a7a7a]">
      {labels.map((label) => (
        <span key={label}>{label}</span>
      ))}
    </div>
  );
}

function CalendarIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="5" y="6" width="14" height="13" rx="2" stroke="currentColor" strokeWidth="1.7" />
      <path d="M8 4v4M16 4v4M5 10h14" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}
