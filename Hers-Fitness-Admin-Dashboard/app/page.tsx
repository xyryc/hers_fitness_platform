"use client";

import { useMutation } from "@tanstack/react-query";
import Image from "next/image";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import { RevenueChart } from "@/components/dashboard/revenue-chart";
import { RevenueSection } from "@/components/dashboard/revenue-section";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  ApiError,
  loginAdmin,
  logoutAdmin,
  refreshAccessToken,
} from "@/lib/auth-api";
import {
  type AdminVerification,
  useApproveAdminVerificationMutation,
  useGetAdminVerificationsQuery,
} from "@/lib/admin-verifications-api";
import { getStoredRefreshToken, useAuthStore } from "@/lib/auth-store";
import type { AdminMember, AdminMemberActivity } from "@/lib/members-api";
import type { AdminTrainer } from "@/lib/trainers-api";
import { cn } from "@/lib/utils";
import { useAdminMember, useAdminMembers } from "@/hooks/use-admin-members";
import {
  useAdminProfile,
  useUpdateAdminProfile,
  useUploadAdminProfileImage,
} from "@/hooks/use-admin-profile";
import { useAdminTrainer, useAdminTrainers } from "@/hooks/use-admin-trainers";
import {
  useDashboardActivities,
  useDashboardSummary,
} from "@/hooks/use-dashboard";
import {
  useFaqs,
  useCreateFaq,
  useUpdateFaq,
  useDeleteFaq,
  useReorderFaqs,
  useStaticContent,
  useSaveStaticContent,
} from "@/hooks/use-content";
import {
  useHelpTickets,
  useHelpTicket,
  useMarkTicketInReview,
  useResolveTicket,
} from "@/hooks/use-support";
import type { DashboardSummary } from "@/lib/types/dashboard.types";
import type { AdminProfile } from "@/lib/types/admin-profile.types";
import type { StaticContentKey } from "@/lib/types/content.types";
import type { TicketStatus } from "@/lib/types/support.types";
import { toast } from "react-toastify";
import { motion, AnimatePresence } from "framer-motion";

const navSections = [
  { label: "Overview", section: "overview", icon: OverviewIcon },
  { label: "Member", section: "members", icon: MembersIcon },
  { label: "Trainer", section: "trainers", icon: TrainerIcon },
  { label: "Verification", section: "verification", icon: ShieldIcon },
  { label: "Revenue", section: "revenue", icon: RevenueNavIcon },
  { label: "Transactions", section: "transactions", icon: CardIcon },
  { label: "Support", section: "support", icon: SupportIcon },
];

// ── helpers for live metric cards ─────────────────────────────────────────────

function formatMetricValue(value: number, prefix = "") {
  return `${prefix}${value.toLocaleString()}`;
}

function formatTrend(trend?: number): { text: string; tone: string } | null {
  if (trend == null) return null;
  const up = trend >= 0;
  return {
    text: `${up ? "+" : ""}${trend.toFixed(1)}%`,
    tone: up ? "text-[#16a34a]" : "text-[#f7869a]",
  };
}

function buildMetricCards(data: DashboardSummary) {
  const t = (m: { trend?: number }) => formatTrend(m.trend);
  return [
    {
      id: "overview" as const,
      title: "Total Revenue",
      value: formatMetricValue(data.totalRevenue.value, "$"),
      ...(t(data.totalRevenue)
        ? { trend: t(data.totalRevenue)!.text, trendTone: t(data.totalRevenue)!.tone }
        : {}),
    },
    {
      id: "transactions" as const,
      title: "Platform Commission",
      value: formatMetricValue(data.platformCommission.value, "$"),
      ...(t(data.platformCommission)
        ? { trend: t(data.platformCommission)!.text, trendTone: t(data.platformCommission)!.tone }
        : {}),
    },
    {
      id: "verification" as const,
      title: "Pending Verifications",
      value: String(data.pendingVerifications.value),
      warning: true,
    },
    {
      id: "members" as const,
      title: "Total Member",
      value: formatMetricValue(data.totalMembers.value),
      ...(t(data.totalMembers)
        ? { trend: t(data.totalMembers)!.text, trendTone: t(data.totalMembers)!.tone }
        : {}),
    },
    {
      id: "trainers" as const,
      title: "Active Trainers",
      value: formatMetricValue(data.activeMembers.value),
      ...(t(data.activeMembers)
        ? { trend: t(data.activeMembers)!.text, trendTone: t(data.activeMembers)!.tone }
        : {}),
    },
    {
      id: "overview" as const,
      title: "Bookings This Week",
      value: formatMetricValue(data.bookingsThisWeek.value),
      ...(t(data.bookingsThisWeek)
        ? { trend: t(data.bookingsThisWeek)!.text, trendTone: t(data.bookingsThisWeek)!.tone }
        : {}),
    },
  ];
}

// Static fallback cards shown while the API response loads
const fallbackMetricCards = [
  { id: "overview"      as const, title: "Total Revenue",         value: "—" },
  { id: "transactions"  as const, title: "Platform Commission",   value: "—" },
  { id: "verification"  as const, title: "Pending Verifications", value: "—", warning: true },
  { id: "members"       as const, title: "Total Member",          value: "—" },
  { id: "trainers"      as const, title: "Active Trainers",       value: "—" },
  { id: "overview"      as const, title: "Bookings This Week",    value: "—" },
];

const transactions = [
  {
    id: "TXN-9925",
    date: "25 Dec 2019",
    payBy: "Luna Ian",
    payBySub: "Sophia",
    amount: "$500",
    fee: "10%",
    trainerGet: "$1 300",
    status: "Completed",
  },
  {
    id: "TXN-9925",
    date: "1 Feb 2020",
    payBy: "Emma",
    payBySub: "Emma",
    amount: "$1 300",
    fee: "10%",
    trainerGet: "$1 900",
    status: "Completed",
  },
  {
    id: "TXN-9925",
    date: "24 Oct 2019",
    payBy: "Olivia",
    payBySub: "Olivia",
    amount: "$1 200",
    fee: "10%",
    trainerGet: "$400",
    status: "Processing",
  },
  {
    id: "TXN-9925",
    date: "17 Oct 2019",
    payBy: "USR-9123",
    payBySub: "Ava",
    amount: "$1 500",
    fee: "10%",
    trainerGet: "$1 100",
    status: "Completed",
  },
  {
    id: "TXN-9925",
    date: "3 Jan 2020",
    payBy: "Isabella",
    payBySub: "Isabella",
    amount: "$2 000",
    fee: "10%",
    trainerGet: "$1 000",
    status: "Processing",
  },
  {
    id: "TXN-9925",
    date: "8 Jun 2020",
    payBy: "USR-4559",
    payBySub: "Mia",
    amount: "$1 000",
    fee: "10%",
    trainerGet: "$800",
    status: "Completed",
  },
  {
    id: "TXN-9925",
    date: "21 Sep 2018",
    payBy: "Evelyn",
    payBySub: "Evelyn",
    amount: "$1 700",
    fee: "10%",
    trainerGet: "$300",
    status: "Processing",
  },
  {
    id: "TXN-9925",
    date: "7 Oct 2019",
    payBy: "Abigail",
    payBySub: "Abigail",
    amount: "$1 900",
    fee: "10%",
    trainerGet: "$600",
    status: "Completed",
  },
  {
    id: "TXN-9925",
    date: "8 Sep 2020",
    payBy: "Ella",
    payBySub: "Ella",
    amount: "$1 600",
    fee: "10%",
    trainerGet: "$500",
    status: "Completed",
  },
  {
    id: "TXN-9925",
    date: "13 Feb 2020",
    payBy: "Harper",
    payBySub: "Harper",
    amount: "$700",
    fee: "10%",
    trainerGet: "$1 700",
    status: "Completed",
  },
  {
    id: "TXN-9926",
    date: "15 Jul 2020",
    payBy: "Lucas",
    payBySub: "Lucas",
    amount: "$2 300",
    fee: "15%",
    trainerGet: "$1 200",
    status: "Pending",
  },
];


type DashboardSection =
  | "overview"
  | "members"
  | "trainers"
  | "verification"
  | "revenue"
  | "transactions"
  | "support"
  | "settings";

export default function Home() {
  const accessToken = useAuthStore((state) => state.accessToken);
  const isReady = useAuthStore((state) => state.isReady);
  const markReady = useAuthStore((state) => state.markReady);
  const clearSession = useAuthStore((state) => state.clearSession);
  const [activeSection, setActiveSection] =
    useState<DashboardSection>("overview");
  const [selectedMember, setSelectedMember] =
    useState<AdminMember | null>(null);
  const [selectedTrainer, setSelectedTrainer] =
    useState<AdminTrainer | null>(null);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const refreshSessionMutation = useMutation({
    mutationFn: refreshAccessToken,
    onError: () => {
      clearSession();
    },
  });
  const {
    mutate: refreshSession,
    isPending: isRefreshingSession,
  } = refreshSessionMutation;
  const logoutMutation = useMutation({
    mutationFn: logoutAdmin,
    onSettled: () => {
      clearSession();
      setSelectedMember(null);
      setSelectedTrainer(null);
      setIsMobileMenuOpen(false);
      toast.success("Logged out successfully.");
    },
  });

  useEffect(() => {
    if (accessToken || isReady || isRefreshingSession) return;

    if (getStoredRefreshToken()) {
      refreshSession();
      return;
    }

    markReady();
  }, [accessToken, isReady, isRefreshingSession, markReady, refreshSession]);

  if (!isReady) {
    return (
      <main className="grid min-h-screen place-items-center bg-white text-sm font-medium text-[#7a7a7a]">
        Restoring session...
      </main>
    );
  }

  if (!accessToken) {
    return <SignInScreen />;
  }

  return (
    <main className="h-screen overflow-hidden bg-white text-[#121212]">
      <div className="flex h-screen overflow-hidden lg:grid lg:grid-cols-[272px_minmax(0,1fr)]">
        {isMobileMenuOpen && (
          <div
            className="fixed inset-0 z-40 bg-black/50 lg:hidden"
            onClick={() => setIsMobileMenuOpen(false)}
          />
        )}
        <Sidebar
          activeSection={activeSection}
          onNavigate={(section) => {
            setActiveSection(section);
            setIsMobileMenuOpen(false);
          }}
          onLogout={() => logoutMutation.mutate()}
          isMobileMenuOpen={isMobileMenuOpen}
        />
        <div className="flex min-h-0 min-w-0 flex-1 flex-col">
          <Topbar
            onNavigate={setActiveSection}
            onToggleMobileMenu={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          />
          <section
            aria-labelledby={`${activeSection}-title`}
            className={cn(
              "flex min-h-0 w-full flex-1 flex-col gap-6 overflow-y-auto px-6 lg:px-8",
              activeSection === "verification" ? "py-4" : "py-6",
            )}
          >
            {activeSection === "overview" ? <OverviewSection onNavigate={setActiveSection} /> : null}
            {activeSection === "members" ? (
              <MemberSection onOpenMemberDetails={setSelectedMember} />
            ) : null}
            {activeSection === "trainers" ? (
              <TrainerSection onOpenTrainerDetails={setSelectedTrainer} />
            ) : null}
            {activeSection === "verification" ? (
              <VerificationSection
                onNavigate={setActiveSection}
                onOpenMemberDetails={setSelectedMember}
                onOpenTrainerDetails={setSelectedTrainer}
              />
            ) : null}
            {activeSection === "revenue" ? <RevenueSection /> : null}
            {activeSection === "transactions" ? <TransactionsSection /> : null}
            {activeSection === "support" ? <SupportSection /> : null}
            {activeSection === "settings" ? <SettingsSection /> : null}
            {activeSection !== "overview" &&
              activeSection !== "members" &&
              activeSection !== "trainers" &&
              activeSection !== "verification" &&
              activeSection !== "revenue" &&
              activeSection !== "transactions" &&
              activeSection !== "support" &&
              activeSection !== "settings" ? (
              <ComingSoonSection section={activeSection} />
            ) : null}
          </section>
        </div>
      </div>
      <AnimatePresence>
        {selectedMember && (
          <MemberDetailsModal
            member={selectedMember}
            onClose={() => setSelectedMember(null)}
          />
        )}
      </AnimatePresence>
      <AnimatePresence>
        {selectedTrainer && (
          <TrainerDetailsModal
            trainer={selectedTrainer}
            onClose={() => setSelectedTrainer(null)}
          />
        )}
      </AnimatePresence>
    </main>
  );
}

function SignInScreen() {
  const setSession = useAuthStore((state) => state.setSession);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(true);
  const loginMutation = useMutation({
    mutationFn: loginAdmin,
    onSuccess: (session) => {
      setSession(session);
      toast.success("Login successful.");
    },
    onError: (error) => {
      const message =
        error instanceof ApiError
          ? error.message
          : "Unable to log in. Please try again.";

      toast.error(message);
    },
  });

  return (
    <main className="login-figma-bg relative grid min-h-screen overflow-hidden px-5 py-8 text-[#121212]">
      <form
        aria-labelledby="sign-in-title"
        className="styled-form relative z-10 m-auto flex w-full max-w-[408px] flex-col items-center gap-4 p-10"
        onSubmit={(event) => {
          event.preventDefault();
          loginMutation.mutate({ username, password, rememberMe });
        }}
      >
        <Image
          src="/figma-assets/hers-fitness-logo.png"
          alt="Hers Fitness"
          width={280}
          height={168}
          priority
          className="h-auto w-[280px] max-w-full object-contain"
        />

        <h1
          id="sign-in-title"
          className="w-full pb-8 text-center text-2xl font-bold text-[#121212]"
        >
          Login
        </h1>

        <div className="flex w-full flex-col gap-[10px]">
          <label className="flex flex-col gap-2">
            <span className="sr-only">Enter your E-mail</span>
            <span className="styled-input-container flex h-12 items-center gap-3 px-4 py-3">
              <MailIcon className="size-6 shrink-0 text-[#7a7a7a]" />
              <input
                type="email"
                name="username"
                placeholder="Username"
                required
                autoComplete="username"
                value={username}
                onChange={(event) => setUsername(event.target.value)}
                className="min-w-0 flex-1 border-0 bg-transparent text-sm font-normal text-[#121212] outline-none placeholder:text-[#7a7a7a]"
              />
            </span>
          </label>

          <div className="flex flex-col gap-2">
            <label className="flex flex-col gap-2">
              <span className="sr-only">Password</span>
              <span className="styled-input-container flex h-12 items-center gap-3 px-4 py-3">
                <LockThinIcon className="size-6 shrink-0 text-[#7a7a7a]" />
                <input
                  type="password"
                  name="password"
                  placeholder="Password"
                  required
                  autoComplete="current-password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  className="min-w-0 flex-1 border-0 bg-transparent text-sm font-normal text-[#121212] outline-none placeholder:text-[#7a7a7a]"
                />
              </span>
            </label>

            <div className="mt-2 flex items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <div className="checkbox-styled-wrapper">
                  <label className="checkbox-container" aria-label="Remember me">
                    <input
                      type="checkbox"
                      checked={rememberMe}
                      onChange={(event) => setRememberMe(event.target.checked)}
                    />
                    <div className="checkmark" />
                  </label>
                </div>
                <span className="text-sm font-medium text-[#4a4a4a]">
                  Remember me
                </span>
              </div>
              <button
                type="button"
                className="text-sm font-medium text-[#121212] transition-colors hover:text-[#f7869a]"
              >
                Forgot password?
              </button>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={loginMutation.isPending}
          className="styled-btn mt-8 flex h-12 items-center justify-center self-center px-6 text-base font-medium text-black"
        >
          {loginMutation.isPending ? "Signing in..." : "Submit"}
        </button>
      </form>
    </main>
  );
}

function OverviewSection({
  onNavigate,
}: {
  onNavigate: (section: DashboardSection) => void;
}) {
  const { data: summaryData } = useDashboardSummary();
  const cards = summaryData ? buildMetricCards(summaryData) : fallbackMetricCards;

  return (
    <>
      <h1 id="overview-title" className="sr-only">
        Overview
      </h1>
      <section
        aria-label="Dashboard metrics"
        className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3"
      >
        {cards.map((metric) => (
          <MetricCard
            key={metric.title}
            {...metric}
            onClick={() => onNavigate(metric.id as DashboardSection)}
          />
        ))}
      </section>
      <section
        className="grid grid-cols-1 gap-6 xl:grid-cols-3"
        aria-label="Hiring revenue and recent activity"
      >
        <RevenueChart />
        <RecentActivity />
      </section>
    </>
  );
}

function Sidebar({
  activeSection,
  onNavigate,
  onLogout,
  isMobileMenuOpen,
}: {
  activeSection: DashboardSection;
  onNavigate: (section: DashboardSection) => void;
  onLogout: () => void;
  isMobileMenuOpen?: boolean;
}) {
  return (
    <aside
      className={cn(
        "fixed inset-y-0 left-0 z-50 flex w-[272px] flex-col overflow-hidden border-r border-[#e0e0e0] bg-white px-[18px] py-[30px] transition-transform duration-300 lg:static lg:flex lg:translate-x-0",
        isMobileMenuOpen ? "translate-x-0" : "-translate-x-full",
      )}
    >
      <div className="flex min-h-0 w-full flex-1 flex-col gap-[27px]">
        <a className="mx-auto block h-[77px] w-[216px]" href="#overview">
          <Image
            src="/figma-assets/hers-fitness-logo.png"
            alt="Hers Fitness"
            width={216}
            height={77}
            priority
            className="h-full w-full object-contain"
          />
        </a>

        <nav aria-label="Dashboard sections" className="flex min-h-0 flex-1 flex-col justify-between">
          <div className="flex flex-col gap-[35px]">
            <div className="flex flex-col gap-3">
              <p className="text-xs font-semibold leading-4 text-[#121212]">
                Main Menu
              </p>
              <div className="flex flex-col gap-1">
                {navSections.map((item) => (
                  <SidebarLink
                    key={item.label}
                    {...item}
                    active={activeSection === item.section}
                    onClick={() => onNavigate(item.section as DashboardSection)}
                  />
                ))}
              </div>
            </div>

            <div className="flex flex-col gap-3" id="settings">
              <p className="text-xs font-semibold leading-4 text-[#121212]">
                Other
              </p>
              <SidebarLink
                label="Settings"
                icon={SettingsIcon}
                active={activeSection === "settings"}
                onClick={() => onNavigate("settings")}
              />
            </div>
          </div>
        </nav>
      </div>

      <div className="mt-auto">
        <SidebarClockCard onLogout={onLogout} />
      </div>
    </aside>
  );
}

function SidebarClockCard({ onLogout }: { onLogout: () => void }) {
  const [now, setNow] = useState<Date | null>(null);

  useEffect(() => {
    const initialTimer = window.setTimeout(() => setNow(new Date()), 0);
    const timer = window.setInterval(() => setNow(new Date()), 1000);

    return () => {
      window.clearTimeout(initialTimer);
      window.clearInterval(timer);
    };
  }, []);

  const timeParts = now
    ? new Intl.DateTimeFormat("en-US", {
        hour: "numeric",
        minute: "2-digit",
        hour12: true,
      })
        .formatToParts(now)
        .reduce(
          (parts, part) => {
            if (part.type === "hour") parts.time = part.value;
            if (part.type === "minute") parts.time += `:${part.value}`;
            if (part.type === "dayPeriod") parts.period = part.value;
            return parts;
          },
          { time: "", period: "" },
        )
    : { time: "11:11", period: "PM" };

  const dayText = now
    ? `${new Intl.DateTimeFormat("en-US", { weekday: "long" }).format(now)}, ${new Intl.DateTimeFormat("en-US", { month: "long" }).format(now)} ${formatOrdinal(now.getDate())}`
    : "Wednesday, June 15th";

  return (
    <div
      className="group relative flex h-[196px] w-full flex-col overflow-hidden rounded-[15px] border border-[#f7869a]/25 bg-[linear-gradient(135deg,#fff7f9_0%,#fdf2f4_48%,#ffffff_100%)] text-[#121212] shadow-[0_12px_32px_rgba(247,134,154,0.18)] transition-shadow duration-300 hover:shadow-[0_16px_38px_rgba(247,134,154,0.26)]"
      aria-label={`${timeParts.time} ${timeParts.period}, ${dayText}`}
    >
      <div className="flex flex-1 flex-col justify-center px-4">
        <p className="text-[42px] font-semibold leading-none text-[#121212]">
          <span>{timeParts.time}</span>
          <span className="ml-1.5 align-baseline text-sm text-[#f7869a]">
            {timeParts.period}
          </span>
        </p>
        <p className="mt-3 text-[15px] font-medium leading-5 text-[#7a7a7a]">
          {dayText}
        </p>
      </div>

      <div className="px-4 pb-6">
        <button type="button" className="logout-3d" onClick={onLogout}>
          <LogoutIcon className="size-5 shrink-0" />
          <span>Logout</span>
        </button>
      </div>

      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 16 16"
        fill="currentColor"
        className="absolute right-4 top-4 size-5 text-[#f7869a] transition-all duration-300 group-hover:size-6"
        aria-hidden="true"
      >
        <path d="M6 .278a.768.768 0 0 1 .08.858 7.208 7.208 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277.527 0 1.04-.055 1.533-.16a.787.787 0 0 1 .81.316.733.733 0 0 1-.031.893A8.349 8.349 0 0 1 8.344 16C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.752.752 0 0 1 6 .278z" />
        <path d="M10.794 3.148a.217.217 0 0 1 .412 0l.387 1.162c.173.518.579.924 1.097 1.097l1.162.387a.217.217 0 0 1 0 .412l-1.162.387a1.734 1.734 0 0 0-1.097 1.097l-.387 1.162a.217.217 0 0 1-.412 0l-.387-1.162A1.734 1.734 0 0 0 9.31 6.593l-1.162-.387a.217.217 0 0 1 0-.412l1.162-.387a1.734 1.734 0 0 0 1.097-1.097l.387-1.162zM13.863.099a.145.145 0 0 1 .274 0l.258.774c.115.346.386.617.732.732l.774.258a.145.145 0 0 1 0 .274l-.774.258a1.156 1.156 0 0 0-.732.732l-.258.774a.145.145 0 0 1-.274 0l-.258-.774a1.156 1.156 0 0 0-.732-.732l-.774-.258a.145.145 0 0 1 0-.274l.774-.258c.346-.115.617-.386.732-.732L13.863.1z" />
      </svg>
    </div>
  );
}

function formatOrdinal(day: number) {
  if (day > 3 && day < 21) return `${day}th`;

  switch (day % 10) {
    case 1:
      return `${day}st`;
    case 2:
      return `${day}nd`;
    case 3:
      return `${day}rd`;
    default:
      return `${day}th`;
  }
}

function SidebarLink({
  label,
  icon: Icon,
  active,
  soft,
  onClick,
}: {
  label: string;
  icon: IconComponent;
  active?: boolean;
  soft?: boolean;
  onClick?: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex h-12 w-full items-center gap-3 rounded-[14px] px-3 text-left text-base leading-6 transition-colors focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30",
        active && "bg-[#f7869a] text-white shadow-[0_0_0_4px_rgba(247,134,154,0.3)]",
        soft && !active && "bg-[#fdf2f4] text-[#121212]",
        !active && !soft && "text-[#121212] hover:bg-[#fdf2f4]",
      )}
      aria-current={active ? "page" : undefined}
    >
      <Icon className="size-6 shrink-0" active={active} />
      <span>{label}</span>
    </button>
  );
}

function Topbar({
  onNavigate,
  onToggleMobileMenu,
}: {
  onNavigate: (section: DashboardSection) => void;
  onToggleMobileMenu?: () => void;
}) {
  const { data: profile } = useAdminProfile();
  const profileImageUrl = profile?.profileImageUrl ?? profile?.imageUrl;
  const profileName = profile?.fullName || "Heba Eid";

  return (
    <header className="flex flex-col gap-4 border-b border-[#e0e0e0] px-6 py-4 md:flex-row md:items-center md:justify-between lg:min-h-[108px] lg:px-8">
      <div className="flex w-full items-center gap-4 md:max-w-[498px]">
        <button
          type="button"
          onClick={onToggleMobileMenu}
          className="flex shrink-0 items-center justify-center rounded-lg p-2 text-[#121212] transition-colors hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 lg:hidden"
          aria-label="Toggle menu"
        >
          <MenuIcon className="size-6" />
        </button>
        <div className="relative min-w-0 flex-1">
          <SearchIcon className="pointer-events-none absolute left-4 top-1/2 size-6 -translate-y-1/2 text-[#121212]" />
          <Input
            aria-label="Search supplements"
            placeholder="Search supplements..."
            className="w-full"
          />
        </div>
      </div>
      <div className="flex w-full items-center justify-between gap-4 md:w-auto md:justify-end md:gap-8">
        <div className="flex items-center gap-4 md:gap-8">
          <BellButton />
          <div className="hidden h-[52px] w-px bg-[#e0e0e0] md:block" aria-hidden="true" />
        </div>
        <button
          type="button"
          onClick={() => onNavigate("settings")}
          className="flex items-center gap-2 rounded-lg px-3 py-2 text-lg font-medium leading-7 text-[#1f1f1f] transition-colors hover:bg-[#fdf2f4] hover:text-[#f7869a] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 md:px-[18px] md:py-3"
        >
          <span
            aria-hidden="true"
            className="size-10 rounded-full bg-cover bg-center md:size-12"
            style={{
              backgroundImage: `url("${profileImageUrl || "/figma-assets/heba-avatar.png"}")`,
            }}
          />
          <span className="truncate">{profileName}</span>
        </button>
      </div>
    </header>
  );
}

function BellButton() {
  return (
    <button
      type="button"
      aria-label="Notifications"
      className="flex size-[46px] items-center justify-center rounded-[25px] border-b-2 border-[#f7869a] bg-[#f7f7f7] p-3 text-[#121212] shadow-[0_1px_3px_rgba(0,0,0,0.1),0_1px_2px_-1px_rgba(0,0,0,0.1)] transition-transform hover:-translate-y-0.5 hover:bg-[#efefef] hover:shadow-[0_6px_16px_rgba(247,134,154,0.25),0_1px_2px_-1px_rgba(0,0,0,0.1)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
    >
      <BellIcon className="size-6" />
    </button>
  );
}

function MetricCard({
  id,
  title,
  value,
  trend,
  trendTone,
  warning,
  onClick,
}: {
  id?: string;
  title: string;
  value: string;
  trend?: string;
  trendTone?: string;
  warning?: boolean;
  onClick?: () => void;
}) {
  return (
    <Card
      id={id}
      className={cn(
        "group relative min-h-[136px] scroll-mt-28 cursor-pointer overflow-hidden border-[0.5px] p-0 shadow-[0_1px_2px_rgba(0,0,0,0.05)] transition-all duration-300 hover:-translate-y-1 hover:shadow-lg",
        warning
          ? "border-[#fef3c7] bg-[rgba(217,119,6,0.1)] hover:border-[#fbbf24]"
          : "border-[rgba(247,134,154,0.3)] bg-[rgba(247,134,154,0.1)] hover:border-[#f7869a]",
      )}
      onClick={onClick}
    >
      <button
        type="button"
        className="flex h-full w-full flex-col p-6 text-left outline-none"
        aria-label={`Navigate to ${title}`}
      >
        <div className="flex w-full items-start justify-between gap-4">
          <div className="flex min-w-0 flex-1 flex-col gap-[14px]">
            <p className="text-base font-medium leading-6 text-[#7a7a7a]">
              {title}
            </p>
            <p className="text-[32px] font-bold leading-none text-[#121212]">
              {value}
            </p>
            {trend ? (
              <p className="text-base font-medium leading-6 text-[#4a4a4a]">
                <span className={trendTone}>{trend}</span> than last month
              </p>
            ) : null}
          </div>
          <span className="flex size-10 shrink-0 items-center justify-center rounded-[10px] bg-white transition-all duration-300 group-hover:bg-[#f7869a] group-hover:text-white group-hover:shadow-md">
            <ArrowUpRightIcon className="size-6" />
          </span>
        </div>
      </button>
    </Card>
  );
}

function RecentActivity() {
  const { data: activityItems, isLoading } = useDashboardActivities(10);

  return (
    <Card className="flex h-[450px] flex-col overflow-hidden rounded-[14px] border-[#e2e8f0] bg-white shadow-none lg:h-[450px]">
      <CardHeader className="shrink-0 gap-2 px-4 py-2.5 text-[#0f172a]">
        <h2 className="text-base font-medium leading-6">Recent Activity</h2>
        <p className="text-xs font-medium leading-4 text-[#7a7a7a]">Latest updates and actions.</p>
      </CardHeader>
      <CardContent className="min-h-0 flex-1 overflow-y-auto pt-3">
        {isLoading ? (
          <div className="flex h-full items-center justify-center">
            <p className="text-sm font-medium text-[#7a7a7a]">Loading activity…</p>
          </div>
        ) : (activityItems ?? []).map((item, index) => (
          <article
            key={`${item.type}-${item.occurredAt}-${index}`}
            className="flex min-h-[70px] gap-3 border-t border-[#e2e8f0] px-3 py-[13px]"
          >
            <Image
              src="/figma-assets/activity-avatar.png"
              alt=""
              width={30}
              height={30}
              className="size-[30px] rounded-full object-cover"
            />
            <div className="min-w-0 flex-1">
              <div className="flex min-h-5 items-start gap-2">
                <p className="min-w-0 flex-1 text-sm font-medium leading-5 text-[#0f172a]">
                  {item.title}
                </p>
                <time
                  dateTime={item.occurredAt}
                  className="flex shrink-0 items-center gap-2 text-xs font-medium leading-4 text-[#344056]"
                >
                  <ClockIcon className="size-[17px]" />
                  {formatRelativeTime(item.occurredAt)}
                </time>
              </div>
              <p className="text-sm font-medium leading-5 text-[#344056]">
                {item.person}
              </p>
            </div>
          </article>
        ))}
      </CardContent>
    </Card>
  );
}

function formatRelativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  if (Number.isNaN(diff)) return iso;

  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes} min ago`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hr ago`;

  const days = Math.floor(hours / 24);
  return `${days} day${days === 1 ? "" : "s"} ago`;
}

function MemberSection({
  onOpenMemberDetails,
}: {
  onOpenMemberDetails: (member: AdminMember) => void;
}) {
  const {
    data: apiMembers = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useAdminMembers();

  return (
    <section
      id="members"
      aria-labelledby="members-title"
      className="min-h-0 flex-1"
    >
      <h2 id="members-title" className="sr-only">
        Members
      </h2>
      <Card className="flex h-full min-h-0 flex-col overflow-hidden rounded-lg border-[#c4cdd5] bg-white shadow-none">
        <div className="min-h-0 flex-1 overflow-auto">
          <table className="min-w-[900px] w-full border-collapse text-left font-['Public_Sans',Arial,sans-serif]">
            <thead>
              <tr className="h-[52px] bg-white text-sm font-semibold leading-[22px] tracking-[0.22px] text-[#1c252e]">
                <MemberHeader className="w-[43%]">User</MemberHeader>
                <MemberHeader className="w-[18%]">ID</MemberHeader>
                <MemberHeader className="w-[18%]">Status</MemberHeader>
                <MemberHeader className="w-[13%]">Joined</MemberHeader>
                <MemberHeader className="w-[8%] text-right">Actions</MemberHeader>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td
                    colSpan={5}
                    className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center text-sm font-medium text-[#7a7a7a]"
                  >
                    Loading members...
                  </td>
                </tr>
              ) : null}
              {isError ? (
                <tr>
                  <td
                    colSpan={5}
                    className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center"
                  >
                    <div className="flex flex-col items-center gap-3">
                      <p className="text-sm font-medium text-[#dc2626]">
                        {error instanceof Error
                          ? error.message
                          : "Unable to load members."}
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
              ) : null}
              {!isLoading && !isError && apiMembers.length === 0 ? (
                <tr>
                  <td
                    colSpan={5}
                    className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center text-sm font-medium text-[#7a7a7a]"
                  >
                    No members found.
                  </td>
                </tr>
              ) : null}
              {!isLoading && !isError ? apiMembers.map((member, index) => (
                <tr key={`${member.name}-${index}`} className="h-[52px]">
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                    <div className="flex min-w-0 items-center gap-3">
                      <Image
                        src={member.profileImageUrl || "/figma-assets/member-avatar.png"}
                        alt=""
                        width={32}
                        height={32}
                        className="size-8 rounded-full object-cover"
                      />
                      <div className="min-w-0">
                        <p className="truncate text-sm font-normal leading-[22px] tracking-[0.22px] text-[#1c252e]">
                          {member.name}
                        </p>
                        <p className="truncate text-xs font-normal leading-[18px] tracking-[0.18px] text-[#454f5b]">
                          {member.email}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-sm leading-[22px] tracking-[0.22px] text-[#1c252e]">
                    {member.id}
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                    <StatusBadge status={member.status} />
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-sm leading-[22px] tracking-[0.22px] text-[#1c252e]">
                    {member.joined}
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-right">
                    <button
                      type="button"
                      onClick={() => onOpenMemberDetails(member)}
                      className="inline-flex size-8 items-center justify-center rounded-md text-[#454f5b] hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
                      aria-label={`Open actions for ${member.name}`}
                    >
                      <KebabIcon className="size-5" />
                    </button>
                  </td>
                </tr>
              )) : null}
            </tbody>
          </table>
        </div>
        <TablePagination />
      </Card>
    </section>
  );
}

function formatAssessmentValue(val?: string | null) {
  if (!val) return "-";
  return val
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(" ");
}

function MemberDetailsModal({
  member,
  onClose,
}: {
  member: AdminMember;
  onClose: () => void;
}) {
  const [isAssessmentOpen, setIsAssessmentOpen] = useState(false);
  const {
    data: memberDetails,
    isLoading: isLoadingMemberDetails,
    isError: isMemberDetailsError,
    error: memberDetailsError,
    refetch: refetchMemberDetails,
  } = useAdminMember(member.id);
  const displayMember = memberDetails ?? member;

  const assessmentData = displayMember.memberFitnessAssessment;

  const assessment = displayMember.hasCompletedMemberFitnessAssessment && assessmentData ? [
    { 
      q: "What is your primary fitness goal?", 
      a: formatAssessmentValue(assessmentData.fitnessGoal) 
    },
    { 
      q: "Have you worked with a trainer before?", 
      a: assessmentData.hasPreviousFitnessExperience ? "Yes" : "No" 
    },
    { 
      q: "Physical Limitations", 
      a: assessmentData.physicalLimitations || "None",
      type: assessmentData.physicalLimitations ? "text" : "tags" 
    },
    { 
      q: "Supplements", 
      a: assessmentData.supplements && assessmentData.supplements.length > 0 
        ? assessmentData.supplements.map((s: string) => formatAssessmentValue(s)) 
        : ["None"], 
      type: "tags", 
      tagTone: "text-[#e06f83]", 
      bg: "bg-[#fff1f2]" 
    },
    { 
      q: "Health & Lifestyle Metrics", 
      a: [
        { label: "Current Age", value: `${assessmentData.age || "-"} yr` },
        { label: "Current Weight", value: `${assessmentData.weight || "-"} ${assessmentData.weightUnit || ""}` },
        { label: "Sleep Quality", value: formatAssessmentValue(assessmentData.sleepQuality) },
        { label: "Current Diet", value: formatAssessmentValue(assessmentData.dietPreference) },
        { label: "Calorie Goal", value: `${assessmentData.calorieGoal || "-"} ${assessmentData.calorieUnit || ""}` },
      ], 
      type: "metrics" 
    },
  ] : [];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex justify-end bg-black/45 p-3"
      role="presentation"
      onMouseDown={onClose}
    >
      <motion.section
        initial={{ x: "100%" }}
        animate={{ x: 0 }}
        exit={{ x: "100%" }}
        transition={{ type: "spring", damping: 25, stiffness: 200 }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="member-details-title"
        className="flex h-[calc(100vh-24px)] w-full max-w-[512px] flex-col overflow-hidden rounded-2xl bg-white shadow-[0_25px_25px_rgba(0,0,0,0.25)]"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="flex h-[77px] shrink-0 items-center justify-between border-b border-[#f3f4f6] px-6 pb-px">
          <h2
            id="member-details-title"
            className="text-xl font-medium leading-7 tracking-[0.1px] text-[#101828]"
          >
            Member Details
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex size-8 items-center justify-center rounded-full text-[#101828] transition-colors hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
            aria-label="Close member details"
          >
            <CloseIcon className="size-6" />
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto px-6 py-4">
          <div className="flex flex-col gap-4">
            <div className="flex items-start gap-4">
              <div className="flex min-w-0 flex-1 items-center gap-4">
                {displayMember.profileImageUrl ? (
                  <Image
                    src={displayMember.profileImageUrl}
                    alt=""
                    width={96}
                    height={96}
                    className="size-24 shrink-0 rounded-full border-4 border-white bg-[#d1d6db] object-cover shadow-[0_4px_6px_-1px_rgba(0,0,0,0.1),0_2px_4px_-2px_rgba(0,0,0,0.1)]"
                  />
                ) : (
                  <div className="size-24 shrink-0 rounded-full border-4 border-white bg-[#d1d6db] shadow-[0_4px_6px_-1px_rgba(0,0,0,0.1),0_2px_4px_-2px_rgba(0,0,0,0.1)]" />
                )}
                <div className="min-w-0 flex-1">
                  <h3 className="truncate text-2xl font-medium leading-8 tracking-[0.12px] text-[#121212]">
                    {displayMember.name.replace("...", "")}
                  </h3>
                  <p className="text-lg font-normal leading-7 tracking-[0.09px] text-[#4a4a4a]">
                    User ID : {displayMember.id}
                  </p>
                  <p className="text-lg font-normal leading-7 tracking-[0.09px] text-[#4a4a4a]">
                    Joined : {displayMember.joined}
                  </p>
                </div>
              </div>
              <span className={cn(
                "flex h-6 items-center justify-center rounded px-2 text-base font-medium leading-6 tracking-[0.08px]",
                displayMember.status === "Active" ? "bg-[#dcfce7] text-[#16a34a]" :
                displayMember.status === "Pending" ? "bg-[#fef3c7] text-[#d97706]" :
                displayMember.status === "Suspended" ? "bg-[#fee2e2] text-[#dc2626]" :
                displayMember.status === "Inactive" ? "bg-[#f1f5f9] text-[#64748b]" :
                "bg-[#f2f2f2] text-[#7a7a7a]"
              )}>
                {displayMember.status}
              </span>
            </div>

            {isLoadingMemberDetails ? (
              <p className="rounded-lg bg-[#fdf2f4] px-3 py-2 text-xs font-medium text-[#64748b]">
                Loading full member profile...
              </p>
            ) : null}
            {isMemberDetailsError ? (
              <div className="flex items-center justify-between gap-3 rounded-lg border border-[#fee2e2] bg-[#fff7f7] px-3 py-2">
                <p className="text-xs font-medium text-[#dc2626]">
                  {memberDetailsError instanceof Error
                    ? memberDetailsError.message
                    : "Unable to load full member profile."}
                </p>
                <button
                  type="button"
                  onClick={() => refetchMemberDetails()}
                  className="shrink-0 rounded bg-white px-2 py-1 text-xs font-medium text-[#121212]"
                >
                  Retry
                </button>
              </div>
            ) : null}

            <div className="border-t border-[#e0e0e0] pt-2">
              <div className="flex items-center gap-2">
                <ShieldIcon className="size-6 text-[#121212]" />
                <p className="text-sm font-normal leading-5 tracking-[0.07px] text-[#121212]">
                  Documents Provided
                </p>
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2">
                <DocumentButton href={displayMember.idCardFrontImageUrl}>
                  ID Front
                </DocumentButton>
                <DocumentButton href={displayMember.idCardBackImageUrl}>
                  ID Back
                </DocumentButton>
              </div>
              {displayMember.idCardType || displayMember.idCardNumber ? (
                <p className="mt-2 text-xs font-medium text-[#64748b]">
                  {[displayMember.idCardType, displayMember.idCardNumber]
                    .filter(Boolean)
                    .join(" - ")}
                </p>
              ) : null}
            </div>

            {/* Assessment Section */}
            {displayMember.hasCompletedMemberFitnessAssessment && (
              <div className="rounded-3xl border border-[#f2f2f2] bg-white shadow-[0_1px_1px_rgba(0,0,0,0.05)] overflow-hidden">
                <button
                  onClick={() => setIsAssessmentOpen(!isAssessmentOpen)}
                  className="flex w-full items-center justify-between p-4 transition-colors hover:bg-[#fcfcfc]"
                >
                  <div className="flex items-center gap-3">
                    <div className="flex size-10 items-center justify-center rounded-xl bg-[#fdf2f4]">
                      <DocumentNormalIcon className="size-5 text-[#f7869a]" />
                    </div>
                    <h3 className="text-base font-semibold leading-6 tracking-[0.08px] text-[#121212]">
                      Member Assessment
                    </h3>
                  </div>
                  <ChevronDownIcon className={cn(
                    "size-5 text-[#7a7a7a] transition-transform duration-200",
                    isAssessmentOpen && "rotate-180"
                  )} />
                </button>
                
                {isAssessmentOpen && (
                  <div className="border-t border-[#f2f2f2] bg-[#fdfdfd] p-4">
                    <div className="flex flex-col gap-5">
                      {assessment.map((item, idx) => (
                        <div key={idx} className="flex flex-col gap-1.5">
                          <p className="text-xs font-semibold uppercase tracking-wider text-[#f7869a]">
                            {item.type === "tags" || item.type === "metrics" ? item.q : `Question ${idx + 1}`}
                          </p>
                          {item.type !== "tags" && item.type !== "metrics" && (
                            <p className="text-sm font-medium leading-5 text-[#121212]">
                              {item.q}
                            </p>
                          )}
                          {item.type === "tags" ? (
                            <div className="flex flex-wrap gap-2">
                              {(item.a as string[]).map((tag) => (
                                <span
                                  key={tag}
                                  className={cn(
                                    "flex h-7 items-center justify-center rounded-[9px] px-2.5 py-1.5 text-center text-xs font-medium leading-5 tracking-[0.07px]",
                                    item.bg || "bg-[#fdf2f4]",
                                    item.tagTone || "text-[#f7869a]"
                                  )}
                                >
                                  {tag}
                                </span>
                              ))}
                            </div>
                          ) : item.type === "metrics" ? (
                            <div className="grid grid-cols-2 gap-2">
                              {(item.a as { label: string; value: string }[]).map((metric, mIdx) => (
                                <div key={mIdx} className="rounded-xl border border-[#f2f2f2] bg-white p-3">
                                  <p className="text-[10px] font-medium uppercase tracking-wider text-[#7a7a7a]">
                                    {metric.label}
                                  </p>
                                  <p className="text-sm font-semibold text-[#121212]">
                                    {metric.value}
                                  </p>
                                </div>
                              ))}
                            </div>
                          ) : (
                            <div className="rounded-xl border border-[#f2f2f2] bg-white p-3 text-sm font-normal leading-5 text-[#4a4a4a]">
                              {item.a as string}
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            <ContactCard
              icon={<ContactBookIcon className="size-6 text-[#f7869a]" />}
              title="Contact Info"
              lines={[
                displayMember.phoneNumber || "No phone number",
                displayMember.email,
              ]}
            />
            <ContactCard
              icon={<LocationPinIcon className="size-6 text-[#f7869a]" />}
              title="Location"
              lines={[
                [displayMember.location, displayMember.state].filter(Boolean).join(", ") ||
                  "No location provided",
              ]}
            />

            <section className="flex flex-col gap-3">
              <div className="border-b border-[#e0e0e0] pb-px">
                <h3 className="px-3.5 py-3 text-lg font-medium leading-7 tracking-[0.09px] text-[#4a4a4a]">
                  Recent Activity
                </h3>
              </div>
              {displayMember.recentActivity?.length ? (
                displayMember.recentActivity.map((activity) => (
                  <ActivityRow
                    key={`${activity.type}-${activity.occurredAt}`}
                    activity={activity}
                  />
                ))
              ) : (
                <p className="rounded-[14px] border border-[#f2f2f2] bg-[#fafafa] p-4 text-sm font-medium text-[#7a7a7a]">
                  No recent activity yet.
                </p>
              )}
            </section>
          </div>
        </div>

        <footer className="shrink-0 bg-white px-6 pb-4 pt-2">
          <button
            type="button"
            className="flex h-12 w-full items-center justify-center rounded-lg border border-[#d32f2f] bg-[#fee2e2] px-6 py-3 text-base font-medium leading-6 tracking-[0.08px] text-[#121212] shadow-[0_0_0_0_rgba(247,134,154,0.3)] transition-colors hover:bg-[#fbd4d4] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
          >
            Suspend User
          </button>
        </footer>
      </motion.section>
    </motion.div>
  );
}

function DocumentButton({
  children,
  href,
}: {
  children: React.ReactNode;
  href?: string | null;
}) {
  if (href) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noreferrer"
        className="group relative flex h-[136px] items-end justify-center overflow-hidden rounded-lg border border-[#f2dbe1] bg-white p-2 text-[10px] font-medium leading-[15px] text-white transition-colors hover:bg-[#fff7f9] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
      >
        <Image
          src={href}
          alt=""
          fill
          sizes="220px"
          className="object-contain p-2 transition-transform duration-200 group-hover:scale-[1.03]"
        />
        <span className="absolute left-2 top-2 z-10 rounded bg-black/60 px-2 py-1">
          {children}
        </span>
        <span className="relative z-10 rounded bg-black/60 px-2 py-1 opacity-0 transition-opacity group-hover:opacity-100">
          Open full image
        </span>
      </a>
    );
  }

  return (
    <button
      type="button"
      disabled
      className="flex h-[43px] items-center justify-center rounded-lg bg-[#fdf2f4] p-3.5 text-[10px] font-medium leading-[15px] text-[#64748b] transition-colors hover:bg-[#f9e8ec] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
    >
      {children}
    </button>
  );
}

function TagPanel({
  icon,
  tags,
  caption,
  tagTone = "text-[#f7869a]",
}: {
  icon: React.ReactNode;
  tags: string[];
  caption: string;
  tagTone?: string;
}) {
  return (
    <section className="flex flex-col gap-3 rounded-3xl border border-[#f2f2f2] bg-white p-3 shadow-[0_1px_1px_rgba(0,0,0,0.05)]">
      {icon}
      <div className="flex flex-col gap-2">
        <div className="flex flex-wrap gap-2">
          {tags.map((tag) => (
            <span
              key={tag}
              className={cn(
                "flex h-7 items-center justify-center rounded-[9px] bg-[#fdf2f4] px-2.5 py-1.5 text-center text-sm font-medium leading-5 tracking-[0.07px]",
                tagTone,
              )}
            >
              {tag}
            </span>
          ))}
        </div>
        <p className="text-xs font-normal leading-4 tracking-[0.06px] text-[#7a7a7a]">
          {caption}
        </p>
      </div>
    </section>
  );
}

function InfoTile({
  icon,
  value,
  unit,
  label,
  valueBadge,
}: {
  icon: React.ReactNode;
  value: string;
  unit?: string;
  label: string;
  valueBadge?: boolean;
}) {
  return (
    <article className="flex min-h-[104px] flex-col gap-2 rounded-3xl border border-[#f2f2f2] bg-white p-3.5 shadow-[0_1px_1px_rgba(0,0,0,0.05)]">
      {icon}
      <div className="flex flex-col gap-2">
        <p className="leading-none">
          <span
            className={cn(
              valueBadge
                ? "inline-flex h-7 items-center rounded-[9px] bg-[#fdf2f4] px-2.5 py-1.5 text-sm font-medium leading-5 tracking-[0.07px] text-[#f7869a]"
                : "text-base font-medium leading-6 tracking-[0.08px] text-[#121212]",
            )}
          >
            {value}
          </span>
          {unit ? (
            <span className="ml-0.5 text-sm font-normal leading-5 tracking-[0.07px] text-[#4a4a4a]">
              {unit}
            </span>
          ) : null}
        </p>
        <p className="text-xs font-normal leading-4 tracking-[0.06px] text-[#7a7a7a]">
          {label}
        </p>
      </div>
    </article>
  );
}

function ContactCard({
  icon,
  title,
  lines,
}: {
  icon: React.ReactNode;
  title: string;
  lines: string[];
}) {
  return (
    <article className="rounded-3xl border border-[#f2f2f2] bg-white p-3.5 shadow-[0_1px_1px_rgba(0,0,0,0.05)]">
      <div className="flex items-start gap-3">
        {icon}
        <h3 className="min-w-0 flex-1 text-base font-semibold leading-6 tracking-[0.08px] text-[#121212]">
          {title}
        </h3>
      </div>
      <div className="mt-2 flex flex-col items-end gap-2 text-right text-sm font-medium leading-5 tracking-[0.07px] text-[#454f5b]">
        {lines.map((line) => (
          <p key={line}>{line}</p>
        ))}
      </div>
    </article>
  );
}

function formatActivityTimestamp(occurredAt: string) {
  const date = new Date(occurredAt);

  if (Number.isNaN(date.getTime())) return "-";

  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

function ActivityRow({ activity }: { activity?: AdminMemberActivity }) {
  return (
    <article className="flex items-center gap-3 rounded-[14px] border-[0.8px] border-[#f2f2f2] bg-[#f3f3f4] p-2">
      <div className="flex self-stretch items-center justify-center p-2">
        <ClockIcon className="size-6 text-[#7a7a7a]" />
      </div>
      <div className="h-12 w-px bg-[#d9d9dd]" aria-hidden="true" />
      <div className="min-w-0 flex-1">
        <h3 className="text-lg font-medium leading-7 tracking-[0.09px] text-[#121212]">
          {activity?.title ?? "Team Meeting"}
        </h3>
        <p className="text-sm font-normal leading-5 tracking-[0.07px] text-[#4a4a4a]">
          {activity
            ? formatActivityTimestamp(activity.occurredAt)
            : "Oct 26, 2026 . 10:00 AM"}
        </p>
        {activity?.description ? (
          <p className="mt-1 text-xs font-normal leading-4 text-[#64748b]">
            {activity.description}
          </p>
        ) : null}
      </div>
    </article>
  );
}

function TrainerDetailsModal({
  trainer,
  onClose,
}: {
  trainer: AdminTrainer;
  onClose: () => void;
}) {
  const {
    data: trainerDetails,
    isLoading: isLoadingTrainerDetails,
    isError: isTrainerDetailsError,
    error: trainerDetailsError,
    refetch: refetchTrainerDetails,
  } = useAdminTrainer(trainer.id);
  const displayTrainer = trainerDetails ?? trainer;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex justify-end bg-black/45 p-0 sm:p-0"
      role="presentation"
      onMouseDown={onClose}
    >
      <motion.section
        initial={{ x: "100%" }}
        animate={{ x: 0 }}
        exit={{ x: "100%" }}
        transition={{ type: "spring", damping: 25, stiffness: 200 }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="trainer-details-title"
        className="flex h-screen w-full max-w-[512px] flex-col overflow-hidden rounded-none bg-white shadow-[0_25px_25px_rgba(0,0,0,0.25)] sm:m-0"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="flex h-[77px] shrink-0 items-center justify-between border-b border-[#f3f4f6] px-6 pb-px">
          <h2
            id="trainer-details-title"
            className="text-xl font-medium leading-7 tracking-[0.1px] text-[#101828]"
          >
            Trainer Details
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex size-8 items-center justify-center rounded-full text-[#101828] transition-colors hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
            aria-label="Close trainer details"
          >
            <CloseIcon className="size-6" />
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto px-6 py-4">
          <div className="flex flex-col gap-4">
            <div className="flex items-start gap-4">
              <div className="flex min-w-0 flex-1 items-center gap-4">
                {displayTrainer.profileImageUrl ? (
                  <Image
                    src={displayTrainer.profileImageUrl}
                    alt=""
                    width={96}
                    height={96}
                    className="size-24 shrink-0 rounded-full border-4 border-white bg-[#d1d6db] object-cover shadow-[0_4px_6px_-1px_rgba(0,0,0,0.1),0_2px_4px_-2px_rgba(0,0,0,0.1)]"
                  />
                ) : (
                  <div className="size-24 shrink-0 rounded-full border-4 border-white bg-[#d1d6db] shadow-[0_4px_6px_-1px_rgba(0,0,0,0.1),0_2px_4px_-2px_rgba(0,0,0,0.1)]" />
                )}
                <div className="min-w-0 flex-1">
                  <h3 className="truncate text-2xl font-medium leading-8 tracking-[0.12px] text-[#121212]">
                    {displayTrainer.name.replace("...", "")}
                  </h3>
                  <p className="text-lg font-normal leading-7 tracking-[0.09px] text-[#4a4a4a]">
                    User ID : {displayTrainer.id}
                  </p>
                  <p className="text-lg font-normal leading-7 tracking-[0.09px] text-[#4a4a4a]">
                    Joined : {displayTrainer.joined || "-"}
                  </p>
                </div>
              </div>
              <span className={cn(
                "flex h-6 items-center justify-center rounded px-2 text-base font-medium leading-6 tracking-[0.08px]",
                displayTrainer.status === "Active" ? "bg-[#dcfce7] text-[#16a34a]" :
                displayTrainer.status === "Pending" ? "bg-[#fef3c7] text-[#d97706]" :
                displayTrainer.status === "Suspended" ? "bg-[#fee2e2] text-[#dc2626]" :
                displayTrainer.status === "Inactive" ? "bg-[#f1f5f9] text-[#64748b]" :
                "bg-[#f2f2f2] text-[#7a7a7a]"
              )}>
                {displayTrainer.status}
              </span>
            </div>

            {isLoadingTrainerDetails ? (
              <p className="rounded-lg bg-[#fdf2f4] px-3 py-2 text-xs font-medium text-[#64748b]">
                Loading full trainer profile...
              </p>
            ) : null}
            {isTrainerDetailsError ? (
              <div className="flex items-center justify-between gap-3 rounded-lg border border-[#fee2e2] bg-[#fff7f7] px-3 py-2">
                <p className="text-xs font-medium text-[#dc2626]">
                  {trainerDetailsError instanceof Error
                    ? trainerDetailsError.message
                    : "Unable to load full trainer profile."}
                </p>
                <button
                  type="button"
                  onClick={() => refetchTrainerDetails()}
                  className="shrink-0 rounded bg-white px-2 py-1 text-xs font-medium text-[#121212]"
                >
                  Retry
                </button>
              </div>
            ) : null}

            <div className="border-t border-[#e0e0e0] pt-2">
              <div className="flex items-center gap-2">
                <ShieldIcon className="size-6 text-[#121212]" />
                <p className="text-sm font-normal leading-5 tracking-[0.07px] text-[#121212]">
                  Documents Provided
                </p>
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2">
                <DocumentButton href={displayTrainer.idCardFrontImageUrl}>
                  ID Front
                </DocumentButton>
                <DocumentButton href={displayTrainer.idCardBackImageUrl}>
                  ID Back
                </DocumentButton>
              </div>
              {displayTrainer.idCardType || displayTrainer.idCardNumber ? (
                <p className="mt-2 text-xs font-medium text-[#64748b]">
                  {[displayTrainer.idCardType, displayTrainer.idCardNumber]
                    .filter(Boolean)
                    .join(" - ")}
                </p>
              ) : null}
            </div>

            <section className="flex flex-col gap-2">
              <h3 className="text-base font-medium leading-6 tracking-[0.08px] text-[#303030]">
                Personal Bio
              </h3>
              <div className="flex h-24 rounded-[18px] border border-[#e0e0e0] bg-white p-4 text-sm font-normal leading-5 tracking-[0.07px] text-[#7a7a7a]">
                {displayTrainer.bio || displayTrainer.tagline || "No bio provided."}
              </div>
            </section>

            <div className="grid grid-cols-2 gap-1.5">
              <InfoTile
                icon={<CalendarSolidIcon className="size-6 text-[#fb7185]" />}
                value={String(displayTrainer.instructorExperience || "-")}
                unit="yr"
                label="been an instructor"
              />
              <InfoTile
                icon={<DocumentNormalIcon className="size-6 text-[#fb7185]" />}
                value={displayTrainer.certifications || "-"}
                label="certifications/qualifications"
                valueBadge
              />
            </div>

            <TagPanel
              icon={<StretchIcon className="size-6 text-[#f7869a]" />}
              caption="physical fitness classes"
              tags={[displayTrainer.classesTaught || "Not provided"]}
            />

            <ContactCard
              icon={<ContactBookIcon className="size-6 text-[#f7869a]" />}
              title="Contact Info"
              lines={[
                displayTrainer.phoneNumber || "No phone number",
                displayTrainer.email || "No email",
              ]}
            />
            <ContactCard
              icon={<LocationPinIcon className="size-6 text-[#f7869a]" />}
              title="Location"
              lines={[
                [displayTrainer.location, displayTrainer.state]
                  .filter(Boolean)
                  .join(", ") || "No location provided",
              ]}
            />

            <section className="flex flex-col gap-3">
              <div className="border-b border-[#e0e0e0] pb-px">
                <h3 className="px-3.5 py-3 text-lg font-medium leading-7 tracking-[0.09px] text-[#4a4a4a]">
                  Recent Activity
                </h3>
              </div>
              {displayTrainer.recentActivity?.length ? (
                displayTrainer.recentActivity.map((activity) => (
                  <ActivityRow
                    key={`${activity.type}-${activity.occurredAt}`}
                    activity={activity}
                  />
                ))
              ) : (
                <p className="rounded-[14px] border border-[#f2f2f2] bg-[#fafafa] p-4 text-sm font-medium text-[#7a7a7a]">
                  No recent activity yet.
                </p>
              )}
            </section>
          </div>
        </div>

        <footer className="shrink-0 bg-white px-6 pb-4 pt-2">
          <button
            type="button"
            className="flex h-12 w-full items-center justify-center rounded-lg border border-[#d32f2f] bg-[#fee2e2] px-6 py-3 text-base font-medium leading-6 tracking-[0.08px] text-[#121212] shadow-[0_0_0_0_rgba(247,134,154,0.3)] transition-colors hover:bg-[#fbd4d4] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
          >
            Suspend User
          </button>
        </footer>
      </motion.section>
    </motion.div>
  );
}

function TrainerSection({
  onOpenTrainerDetails,
}: {
  onOpenTrainerDetails: (trainer: AdminTrainer) => void;
}) {
  const {
    data: apiTrainers = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useAdminTrainers();

  return (
    <section
      id="trainers"
      aria-labelledby="trainers-title"
      className="min-h-0 flex-1"
    >
      <h1 id="trainers-title" className="sr-only">
        Trainers
      </h1>
      <Card className="flex h-full min-h-0 flex-col overflow-hidden rounded-lg border-[#c4cdd5] bg-white shadow-none">
        <div className="min-h-0 flex-1 overflow-auto">
          <table className="w-full min-w-[980px] border-collapse text-left font-['Public_Sans',Arial,sans-serif]">
            <thead>
              <tr className="h-[52px] bg-white text-sm font-semibold leading-[22px] tracking-[0.22px] text-[#1c252e]">
                <MemberHeader className="w-[30%]">Trainer</MemberHeader>
                <MemberHeader className="w-[19%]">Specialties</MemberHeader>
                <MemberHeader className="w-[12%]">Class</MemberHeader>
                <MemberHeader className="w-[18%]">Status</MemberHeader>
                <MemberHeader className="w-[13%]">Rating</MemberHeader>
                <MemberHeader className="w-[8%] text-right">Actions</MemberHeader>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td
                    colSpan={6}
                    className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center text-sm font-medium text-[#7a7a7a]"
                  >
                    Loading trainers...
                  </td>
                </tr>
              ) : null}
              {isError ? (
                <tr>
                  <td
                    colSpan={6}
                    className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center"
                  >
                    <div className="flex flex-col items-center gap-3">
                      <p className="text-sm font-medium text-[#dc2626]">
                        {error instanceof Error
                          ? error.message
                          : "Unable to load trainers."}
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
              ) : null}
              {!isLoading && !isError && apiTrainers.length === 0 ? (
                <tr>
                  <td
                    colSpan={6}
                    className="border-b border-dashed border-[#c4cdd5] px-3 py-10 text-center text-sm font-medium text-[#7a7a7a]"
                  >
                    No trainers found.
                  </td>
                </tr>
              ) : null}
              {!isLoading && !isError ? apiTrainers.map((trainer, index) => (
                <tr key={`${trainer.name}-${index}`} className="h-[52px]">
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                    <div className="flex min-w-0 items-center gap-3">
                      <Image
                        src={trainer.profileImageUrl || "/figma-assets/trainer-avatar.png"}
                        alt=""
                        width={32}
                        height={32}
                        className="size-8 rounded-full object-cover"
                      />
                      <div className="min-w-0">
                        <p className="truncate text-sm font-normal leading-[22px] tracking-[0.22px] text-[#1c252e]">
                          {trainer.name}
                        </p>
                        <p className="truncate text-xs font-normal leading-[18px] tracking-[0.18px] text-[#454f5b]">
                          {trainer.user}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-sm leading-[22px] tracking-[0.22px] text-[#1c252e]">
                    {trainer.specialty}
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-sm leading-[22px] tracking-[0.22px] text-[#1c252e]">
                    {trainer.classes}
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                    <StatusBadge status={trainer.status} />
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-sm leading-[22px] tracking-[0.22px] text-[#1c252e]">
                    {trainer.rating}
                  </td>
                  <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2 text-right">
                    <button
                      type="button"
                      onClick={() => onOpenTrainerDetails(trainer)}
                      className="inline-flex size-8 items-center justify-center rounded-md text-[#454f5b] hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
                      aria-label={`Open actions for ${trainer.name}`}
                    >
                      <KebabIcon className="size-5" />
                    </button>
                  </td>
                </tr>
              )) : null}
            </tbody>
          </table>
        </div>
        <TablePagination />
      </Card>
    </section>
  );
}

function VerificationSection({
  onNavigate,
  onOpenMemberDetails,
  onOpenTrainerDetails,
}: {
  onNavigate: (section: DashboardSection) => void;
  onOpenMemberDetails: (member: AdminMember) => void;
  onOpenTrainerDetails: (trainer: AdminTrainer) => void;
}) {
  const [filter, setFilter] = useState<"members" | "trainers">("members");
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [rejectionRequest, setRejectionRequest] =
    useState<AdminVerification | null>(null);
  const requestType = filter === "members" ? "MEMBER" : "TRAINER";
  const {
    data: verifications = [],
    error,
    isFetching,
    isLoading,
    refetch,
  } = useGetAdminVerificationsQuery(requestType);

  const isEmpty = !isLoading && !error && verifications.length === 0;

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-6 overflow-hidden">
      <Card className="flex items-center rounded-2xl border-[#f2f2f2] bg-white p-4 shadow-[0_1px_3px_rgba(0,0,0,0.1),0_1px_2px_-1px_rgba(0,0,0,0.1)] lg:min-h-24 lg:p-[17px]">
        <div className="flex w-full flex-col gap-4 lg:flex-row lg:items-center">
          <div className="flex items-center gap-4">
            <span className="flex size-11 shrink-0 items-center justify-center rounded-full bg-[linear-gradient(91deg,#f7869a_2%,#fbc3cc_100%)] text-white">
              <CheckIcon className="size-6" />
            </span>
            <div className="min-w-0 flex-1">
              <h2 className="text-xl font-medium leading-8 tracking-[0.12px] text-[#1e293b] lg:text-2xl">
                Verifications
              </h2>
            </div>
          </div>
          <p className="truncate text-base font-normal leading-7 tracking-[0.09px] text-[#4a4a4a] lg:flex-1 lg:text-lg">
            Nice work! You&apos;re currently averaging a 12-hour turnaround
            time this week.
          </p>
          <div className="relative">
            <button
              type="button"
              onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              className="flex h-12 w-full shrink-0 items-center justify-center gap-2 rounded-lg border border-[#f2f2f2] bg-[linear-gradient(141deg,#e06f83_11%,#f093a3_32%,#e06f83_53%)] px-6 py-3 text-base font-medium leading-6 tracking-[0.08px] text-white shadow-[0_0_0_0_rgba(247,134,154,0.3)] transition-shadow hover:shadow-[0_0_0_2px_rgba(247,134,154,0.3)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 lg:w-auto"
            >
              <FilterIcon className="size-6" />
              Filter: {filter === "members" ? "Members" : "Trainers"}
            </button>
            {isDropdownOpen && (
              <div className="absolute right-0 top-full z-20 mt-2 w-48 rounded-lg border border-[#e0e0e0] bg-white p-1 shadow-lg ring-1 ring-black/5">
                <button
                  onClick={() => {
                    setFilter("members");
                    setIsDropdownOpen(false);
                  }}
                  className={cn(
                    "flex w-full items-center px-3 py-2 text-sm rounded-md transition-colors font-medium",
                    filter === "members" ? "bg-[#fdf2f4] text-[#f7869a]" : "text-[#4a4a4a] hover:bg-[#f7f7f7]"
                  )}
                >
                  Members
                </button>
                <button
                  onClick={() => {
                    setFilter("trainers");
                    setIsDropdownOpen(false);
                  }}
                  className={cn(
                    "flex w-full items-center px-3 py-2 text-sm rounded-md transition-colors font-medium",
                    filter === "trainers" ? "bg-[#fdf2f4] text-[#f7869a]" : "text-[#4a4a4a] hover:bg-[#f7f7f7]"
                  )}
                >
                  Trainers
                </button>
              </div>
            )}
          </div>
        </div>
      </Card>
      <div className="min-h-0 flex-1 overflow-y-auto">
        <section
          aria-label="Pending verification requests"
          className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
        >
          {isLoading
            ? Array.from({ length: 8 }).map((_, index) => (
              <VerificationCardSkeleton key={index} />
            ))
            : null}
          {!isLoading && error ? (
            <div className="col-span-full flex min-h-[240px] flex-col items-center justify-center gap-3 rounded-xl border border-dashed border-[#c4cdd5] bg-white p-6 text-center">
              <p className="text-base font-semibold text-[#121212]">
                Could not load verification requests.
              </p>
              <p className="text-sm text-[#7a7a7a]">
                {getErrorMessage(error)}
              </p>
              <button
                type="button"
                onClick={() => refetch()}
                className="rounded-lg bg-[#121212] px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-black/80 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
              >
                Try again
              </button>
            </div>
          ) : null}
          {!isLoading && !error
            ? verifications.map((request) => (
              <VerificationCard
                key={request.userId}
                request={request}
                isFetching={isFetching}
                onNavigate={onNavigate}
                onOpenMemberDetails={onOpenMemberDetails}
                onOpenTrainerDetails={onOpenTrainerDetails}
                onReject={setRejectionRequest}
              />
            ))
            : null}
          {isEmpty ? (
            <div className="col-span-full flex min-h-[240px] items-center justify-center rounded-xl border border-dashed border-[#c4cdd5] bg-white p-6 text-center text-sm font-medium text-[#7a7a7a]">
              No pending {filter === "members" ? "member" : "trainer"} verification
              requests right now.
            </div>
          ) : null}
        </section>
      </div>

      {rejectionRequest && (
        <RejectionModal
          request={rejectionRequest}
          onClose={() => setRejectionRequest(null)}
          onConfirm={(reason) => {
            toast.error(
              `Rejected: ${getVerificationName(rejectionRequest)}. Reason: ${reason}`,
            );
            setRejectionRequest(null);
          }}
        />
      )}
    </div>
  );
}

function VerificationCard({
  request,
  isFetching,
  onNavigate,
  onOpenMemberDetails,
  onOpenTrainerDetails,
  onReject,
}: {
  request: AdminVerification;
  isFetching: boolean;
  onNavigate: (section: DashboardSection) => void;
  onOpenMemberDetails: (member: AdminMember) => void;
  onOpenTrainerDetails: (trainer: AdminTrainer) => void;
  onReject: (request: AdminVerification) => void;
}) {
  const [approveVerification, { isLoading: isApproving }] =
    useApproveAdminVerificationMutation();
  const isMember = request.requestType === "MEMBER";
  const name = getVerificationName(request);
  const submitted = formatVerificationDate(request.submittedAt);
  const avatarSrc =
    request.profileImageUrl
      ? request.profileImageUrl
      : isMember
        ? "/figma-assets/member-avatar.png"
        : "/figma-assets/trainer-avatar.png";

  const handleProfileClick = () => {
    if (isMember) {
      onNavigate("members");
      onOpenMemberDetails(mapVerificationToMember(request));
    } else {
      onNavigate("trainers");
      onOpenTrainerDetails(mapVerificationToTrainer(request));
    }
  };

  return (
    <Card className="w-full rounded-2xl border-[#f2f2f2] bg-white p-5 shadow-[0_4px_10px_rgba(0,0,0,0.03)] transition-shadow hover:shadow-md">
      <div className="flex items-start">
        <button
          onClick={handleProfileClick}
          className="flex min-w-0 flex-1 items-center gap-3 text-left transition-opacity hover:opacity-80"
        >
          <Image
            src={avatarSrc}
            alt=""
            width={48}
            height={48}
            className="size-12 rounded-full border-2 border-[#f8fafc] object-cover"
          />
          <div className="min-w-0">
            <h3 className="truncate text-base font-semibold leading-6 tracking-[0.08px] text-[#121212]">
              {name}
            </h3>
            <p className="text-xs font-normal leading-4 tracking-[0.06px] text-[#4a4a4a]">
              {request.userCode || request.userId}
            </p>
          </div>
        </button>
        <span className={cn(
          "flex h-6 shrink-0 items-center justify-center rounded px-2 py-0.5 font-['Public_Sans',Arial,sans-serif] text-sm font-semibold leading-[22px] tracking-[0.22px]",
          request.verificationStatus === "APPROVED"
            ? "bg-[#dcfce7] text-[#16a34a]"
            : request.verificationStatus === "REJECTED"
              ? "bg-[#fee2e2] text-[#dc2626]"
              : "bg-[#fef3c7] text-[#d97706]"
        )}>
          {formatVerificationStatus(request.verificationStatus)}
        </span>
      </div>

      <div className="mt-[13px] flex flex-col gap-3 rounded-xl border-[0.5px] border-[#f2f2f2] bg-[#f7f7f7] p-3">
        <VerificationDetail label="Request Type" value={formatRequestType(request.requestType)} />
        <VerificationDetail label="Submitted" value={submitted} />
        <VerificationDetail label="ID Type" value={request.idCardType ?? "-"} />
        <VerificationDetail label="ID Number" value={request.idCardNumber ?? "-"} />
        <div className="flex flex-col gap-2 border-t border-[#e0e0e0] py-2">
          <div className="flex items-center gap-2">
            <ShieldIcon className="size-6 text-[#121212]" />
            <p className="text-sm font-normal leading-5 tracking-[0.07px] text-[#121212]">
              {request.documentsProvided ? "Documents Provided" : "No Documents Provided"}
            </p>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <DocumentPreview
              href={request.idCardFrontImageUrl}
              label="ID Front"
            />
            <DocumentPreview
              href={request.idCardBackImageUrl}
              label="ID Back"
            />
          </div>
        </div>
      </div>

      <div className="mt-[7px] grid grid-cols-2 gap-2">
        <button
          type="button"
          disabled={isApproving || isFetching}
          onClick={async (e) => {
            e.stopPropagation();
            try {
              await approveVerification(request.userId).unwrap();
              toast.success(`Approved! Notification sent to ${name}.`);
            } catch (error) {
              toast.error(getErrorMessage(error));
            }
          }}
          className="flex h-12 items-center justify-center gap-2 rounded-lg bg-[#dcfce7] px-6 py-3 text-sm font-semibold leading-6 tracking-[0.08px] text-[#16a34a] transition-colors hover:bg-[#c9f7d9] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#16a34a]/20 disabled:cursor-not-allowed disabled:opacity-60"
        >
          <CheckIcon className="size-5" />
          {isApproving ? "Approving" : "Approve"}
        </button>
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            onReject(request);
          }}
          className="flex h-12 items-center justify-center gap-2 rounded-lg bg-[#fee2e2] px-6 py-3 text-sm font-semibold leading-6 tracking-[0.08px] text-[#dc2626] transition-colors hover:bg-[#fbd4d4] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#dc2626]/20"
          aria-label={`Reject ${name}`}
        >
          <CheckIcon className="size-5" />
          Reject
        </button>
      </div>
    </Card>
  );
}

function VerificationCardSkeleton() {
  return (
    <Card className="w-full rounded-2xl border-[#f2f2f2] bg-white p-5 shadow-[0_4px_10px_rgba(0,0,0,0.03)]">
      <div className="flex items-start gap-3">
        <div className="size-12 rounded-full bg-[#f2f2f2]" />
        <div className="flex flex-1 flex-col gap-2">
          <div className="h-4 w-2/3 rounded bg-[#f2f2f2]" />
          <div className="h-3 w-1/2 rounded bg-[#f2f2f2]" />
        </div>
        <div className="h-6 w-16 rounded bg-[#fef3c7]" />
      </div>
      <div className="mt-[13px] flex flex-col gap-3 rounded-xl border-[0.5px] border-[#f2f2f2] bg-[#f7f7f7] p-3">
        <div className="h-4 rounded bg-[#ececec]" />
        <div className="h-4 rounded bg-[#ececec]" />
        <div className="h-16 rounded bg-[#ececec]" />
      </div>
      <div className="mt-[7px] grid grid-cols-2 gap-2">
        <div className="h-12 rounded-lg bg-[#dcfce7]" />
        <div className="h-12 rounded-lg bg-[#fee2e2]" />
      </div>
    </Card>
  );
}

function DocumentPreview({
  href,
  label,
}: {
  href?: string | null;
  label: string;
}) {
  if (!href) {
    return (
      <span className="flex h-[96px] cursor-not-allowed items-center justify-center rounded-lg bg-[#fdf2f4] p-3.5 text-[10px] font-medium leading-[15px] text-[#64748b] opacity-50">
        {label}
      </span>
    );
  }

  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      className="group relative block h-[96px] overflow-hidden rounded-lg bg-[#fdf2f4] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
      onClick={(event) => event.stopPropagation()}
      aria-label={`Open ${label}`}
    >
      <Image
        src={href}
        alt={label}
        fill
        sizes="(max-width: 768px) 45vw, 160px"
        className="object-cover transition-transform group-hover:scale-105"
      />
      <span className="absolute inset-x-0 bottom-0 bg-black/55 px-2 py-1 text-center text-[10px] font-semibold leading-[15px] text-white">
        {label}
      </span>
    </a>
  );
}

function getVerificationName(request: AdminVerification) {
  const fullName = [request.firstName, request.lastName].filter(Boolean).join(" ");

  return request.displayName || fullName || request.username || request.email;
}

function formatRequestType(type: AdminVerification["requestType"]) {
  return type === "MEMBER" ? "Member" : "Trainer";
}

function formatVerificationStatus(status: AdminVerification["verificationStatus"]) {
  return status.charAt(0).toUpperCase() + status.slice(1).toLowerCase();
}

function verificationStatusToDisplayStatus(status: AdminVerification["verificationStatus"]) {
  if (status === "APPROVED") return "Active";
  if (status === "REJECTED") return "Suspended";
  if (status === "PENDING") return "Pending";
  return formatVerificationStatus(status);
}

function formatVerificationDate(dateValue?: string | null) {
  if (!dateValue) return "-";

  const date = new Date(dateValue);

  if (Number.isNaN(date.getTime())) return "-";

  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(date);
}

function mapVerificationToMember(request: AdminVerification): AdminMember {
  return {
    id: request.userId,
    email: request.email,
    name: getVerificationName(request),
    username: request.username,
    profileImageUrl: request.profileImageUrl,
    idCardType: request.idCardType,
    idCardNumber: request.idCardNumber,
    idCardFrontImageUrl: request.idCardFrontImageUrl,
    idCardBackImageUrl: request.idCardBackImageUrl,
    verificationStatus: request.verificationStatus,
    joined: formatVerificationDate(request.submittedAt),
    createdAt: request.submittedAt ?? undefined,
    status: verificationStatusToDisplayStatus(request.verificationStatus),
    recentActivity: [],
  };
}

function mapVerificationToTrainer(request: AdminVerification): AdminTrainer {
  return {
    id: request.userId,
    email: request.email,
    name: getVerificationName(request),
    username: request.username,
    user: request.username || request.email,
    profileImageUrl: request.profileImageUrl,
    idCardType: request.idCardType,
    idCardNumber: request.idCardNumber,
    idCardFrontImageUrl: request.idCardFrontImageUrl,
    idCardBackImageUrl: request.idCardBackImageUrl,
    verificationStatus: request.verificationStatus,
    joined: formatVerificationDate(request.submittedAt),
    createdAt: request.submittedAt ?? undefined,
    status: verificationStatusToDisplayStatus(request.verificationStatus),
    specialty: "-",
    classes: "-",
    rating: "-",
    recentActivity: [],
  };
}

function getErrorMessage(error: unknown) {
  if (error instanceof ApiError || error instanceof Error) return error.message;

  if (error && typeof error === "object") {
    const data = "data" in error ? (error as { data?: unknown }).data : undefined;

    if (data && typeof data === "object" && "message" in data) {
      const message = (data as { message?: unknown }).message;

      if (typeof message === "string") return message;
    }

    if ("message" in error) {
      const message = (error as { message?: unknown }).message;

      if (typeof message === "string") return message;
    }
  }

  return "Something went wrong. Please try again.";
}

function RejectionModal({
  request,
  onClose,
  onConfirm,
}: {
  request: AdminVerification;
  onClose: () => void;
  onConfirm: (reason: string) => void;
}) {
  const [reason, setReason] = useState("");

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[60] flex items-center justify-center bg-black/45 p-4"
      role="presentation"
      onMouseDown={onClose}
    >
      <motion.section
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.9, opacity: 0 }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="rejection-modal-title"
        className="w-full max-w-md overflow-hidden rounded-2xl bg-white shadow-[0_25px_50px_-12px_rgba(0,0,0,0.25)]"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="flex h-[64px] items-center justify-between border-b border-[#f3f4f6] px-6">
          <h2
            id="rejection-modal-title"
            className="text-lg font-semibold leading-7 text-[#101828]"
          >
            Reject Verification
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex size-8 items-center justify-center rounded-full text-[#4a4a4a] transition-colors hover:bg-[#f7f7f7]"
          >
            <CloseIcon className="size-5" />
          </button>
        </header>

        <div className="p-6">
          <div className="mb-4">
            <p className="text-sm font-medium text-[#4a4a4a]">
              Rejecting request for:
            </p>
            <p className="text-base font-semibold text-[#121212]">
              {getVerificationName(request)} ({request.userCode || request.userId})
            </p>
          </div>

          <div className="flex flex-col gap-2">
            <label
              htmlFor="rejection-reason"
              className="text-sm font-medium text-[#121212]"
            >
              Reason for rejection
            </label>
            <textarea
              id="rejection-reason"
              rows={4}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="Please provide a reason for rejecting this request..."
              className="w-full rounded-xl border border-[#e0e0e0] p-3 text-sm focus:border-[#f7869a] focus:outline-none focus:ring-4 focus:ring-[#f7869a]/10"
            />
          </div>
        </div>

        <footer className="flex items-center justify-end gap-3 bg-[#f9fafb] px-6 py-4">
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg border border-[#e0e0e0] bg-white px-4 py-2 text-sm font-semibold text-[#4a4a4a] hover:bg-[#f7f7f7]"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={() => onConfirm(reason)}
            disabled={!reason.trim()}
            className="rounded-lg bg-[#dc2626] px-4 py-2 text-sm font-semibold text-white transition-opacity hover:bg-[#b91c1c] disabled:opacity-50"
          >
            Confirm Rejection
          </button>
        </footer>
      </motion.section>
    </motion.div>
  );
}

function VerificationDetail({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4 text-base leading-6 tracking-[0.08px]">
      <p className="font-normal text-[#4a4a4a]">{label}</p>
      <p className="font-medium text-[#121212]">{value}</p>
    </div>
  );
}

function TransactionsSection() {
  const [filter, setFilter] = useState<"All" | "Completed" | "Processing" | "Pending">("All");
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);

  const filteredTransactions = transactions.filter((transaction) => {
    if (filter === "All") return true;
    return transaction.status === filter;
  });

  return (
    <section
      id="transactions"
      aria-labelledby="transactions-title"
      className="min-h-0 flex-1"
    >
      <Card className="flex h-full min-h-0 flex-col gap-[14px] overflow-hidden rounded-[14px] border-[#e3e6f0] bg-white px-3 py-3.5 shadow-none">
        <div className="flex shrink-0 flex-col gap-4 lg:flex-row lg:items-center">
          <div className="min-w-0 flex-1">
            <h1
              id="transactions-title"
              className="text-xl font-medium leading-8 tracking-[0.12px] text-[#1e293b] lg:text-2xl"
            >
              Transactions
            </h1>
            <p className="text-base font-normal leading-7 tracking-[0.09px] text-[#4a4a4a] lg:text-lg">
              Financial overview and history.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2.5">
            <button
              type="button"
              onClick={() => setIsExportModalOpen(true)}
              className="flex h-12 flex-1 shrink-0 items-center justify-center gap-2 rounded-lg bg-black px-6 py-3 text-base font-medium leading-6 tracking-[0.08px] text-white transition-shadow hover:shadow-[0_0_0_2px_rgba(247,134,154,0.3)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 lg:flex-none"
            >
              <DocumentDownloadIcon className="size-6" />
              Export CSV
            </button>

            <div className="relative flex-1 lg:flex-none">
              <button
                type="button"
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                className="flex h-12 w-full shrink-0 items-center justify-center gap-2 rounded-lg border border-[#f2f2f2] bg-[linear-gradient(141deg,#e06f83_11%,#f093a3_32%,#e06f83_53%)] px-6 py-3 text-base font-medium leading-6 tracking-[0.08px] text-white transition-shadow hover:shadow-[0_0_0_2px_rgba(247,134,154,0.3)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 lg:w-auto"
              >
                <TuneIcon className="size-6" />
                Filter: {filter}
              </button>
              {isDropdownOpen && (
                <div className="absolute right-0 top-full z-20 mt-2 w-48 rounded-lg border border-[#e0e0e0] bg-white p-1 shadow-lg ring-1 ring-black/5">
                  {(["All", "Completed", "Processing", "Pending"] as const).map((option) => (
                    <button
                      key={option}
                      onClick={() => {
                        setFilter(option);
                        setIsDropdownOpen(false);
                      }}
                      className={cn(
                        "flex w-full items-center px-3 py-2 text-sm rounded-md transition-colors font-medium",
                        filter === option ? "bg-[#fdf2f4] text-[#f7869a]" : "text-[#4a4a4a] hover:bg-[#f7f7f7]"
                      )}
                    >
                      {option}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-lg border border-[#c4cdd5]">
          <div className="min-h-0 flex-1 overflow-auto">
            <table className="w-full min-w-[1080px] border-collapse text-left">
              <thead className="sticky top-0 z-10">
                <tr className="h-[55px] bg-[#f7f7f7] text-sm font-semibold leading-5 tracking-[0.07px] text-[#4a4a4a]">
                  {["Transaction ID", "Date", "Pay By", "Amount", "Fee", "Trainer get", "Actions"].map((heading) => (
                    <th
                      key={heading}
                      className="border-b border-[#e0e0e0] px-0 py-2 first:[&>div]:border-l-0"
                    >
                      <div className="flex h-6 items-center border-l border-[#c4cdd5] px-3">
                        <span className="truncate">{heading}</span>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="font-['Public_Sans',Arial,sans-serif]">
                {filteredTransactions.map((transaction, index) => (
                  <tr key={`${transaction.id}-${transaction.date}-${index}`} className="h-[52px] bg-white">
                    <TransactionCell>{transaction.id}</TransactionCell>
                    <TransactionCell className="font-sans tracking-[0.07px]">{transaction.date}</TransactionCell>
                    <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                      <div className="flex min-w-0 flex-col justify-center">
                        <p className="truncate text-sm font-normal leading-[22px] tracking-[0.22px] text-[#1c252e]">
                          {transaction.payBy}
                        </p>
                        <p className="truncate text-xs font-normal leading-[18px] tracking-[0.18px] text-[#454f5b]">
                          {transaction.payBySub}
                        </p>
                      </div>
                    </td>
                    <TransactionCell>{transaction.amount}</TransactionCell>
                    <TransactionCell>{transaction.fee}</TransactionCell>
                    <TransactionCell>{transaction.trainerGet}</TransactionCell>
                    <td className="border-b border-dashed border-[#c4cdd5] px-3 py-2">
                      <TransactionStatusBadge status={transaction.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <TablePagination />
        </div>
      </Card>
      {isExportModalOpen && (
        <ExportCSVModal
          data={filteredTransactions}
          onClose={() => setIsExportModalOpen(false)}
        />
      )}
    </section>
  );
}

function ExportCSVModal({
  data,
  onClose,
}: {
  data: typeof transactions;
  onClose: () => void;
}) {
  const handleExport = () => {
    const headers = ["Transaction ID", "Date", "Pay By", "Amount", "Fee", "Trainer Get", "Status"];
    const csvContent = [
      headers.join(","),
      ...data.map((row) =>
        [
          row.id,
          row.date,
          `"${row.payBy} (${row.payBySub})"`,
          row.amount.replace("$", "").trim(),
          row.fee,
          row.trainerGet.replace("$", "").trim(),
          row.status,
        ].join(",")
      ),
    ].join("\n");

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `transactions_${new Date().toISOString().split("T")[0]}.csv`);
    link.style.visibility = "hidden";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4"
      role="presentation"
      onMouseDown={onClose}
    >
      <section
        role="dialog"
        aria-modal="true"
        aria-labelledby="export-modal-title"
        className="flex max-h-[90vh] w-full max-w-[800px] flex-col overflow-hidden rounded-2xl bg-white shadow-[0_25px_25px_rgba(0,0,0,0.25)]"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <header className="flex h-[77px] shrink-0 items-center justify-between border-b border-[#f3f4f6] px-6">
          <h2
            id="export-modal-title"
            className="text-xl font-medium leading-7 tracking-[0.1px] text-[#101828]"
          >
            Export Preview
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex size-8 items-center justify-center rounded-full text-[#101828] transition-colors hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
            aria-label="Close export modal"
          >
            <CloseIcon className="size-6" />
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-auto p-6">
          <div className="rounded-lg border border-[#c4cdd5]">
            <table className="w-full border-collapse text-left text-sm">
              <thead className="bg-[#f7f7f7]">
                <tr>
                  {["ID", "Date", "Pay By", "Amount", "Status"].map((h) => (
                    <th key={h} className="border-b border-[#e0e0e0] px-4 py-3 font-semibold text-[#4a4a4a]">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.map((row, i) => (
                  <tr key={i} className="border-b border-dashed border-[#c4cdd5]">
                    <td className="px-4 py-3 text-[#1c252e]">{row.id}</td>
                    <td className="px-4 py-3 text-[#1c252e]">{row.date}</td>
                    <td className="px-4 py-3 text-[#1c252e]">{row.payBy}</td>
                    <td className="px-4 py-3 text-[#1c252e]">{row.amount}</td>
                    <td className="px-4 py-3">
                      <TransactionStatusBadge status={row.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <footer className="flex shrink-0 items-center justify-end gap-3 border-t border-[#f3f4f6] bg-white px-6 py-4">
          <button
            type="button"
            onClick={onClose}
            className="h-11 rounded-lg border border-[#e0e0e0] px-6 text-sm font-medium text-[#4a4a4a] hover:bg-[#f7f7f7]"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handleExport}
            className="flex h-11 items-center justify-center gap-2 rounded-lg bg-black px-6 text-sm font-medium text-white hover:bg-[#121212] transition-shadow hover:shadow-[0_0_0_2px_rgba(247,134,154,0.3)]"
          >
            <DocumentDownloadIcon className="size-5" />
            Download CSV
          </button>
        </footer>
      </section>
    </div>
  );
}

function TransactionCell({
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
      <span className="block truncate">{children}</span>
    </td>
  );
}

function TransactionStatusBadge({ status }: { status: string }) {
  const styles =
    status === "Completed"
      ? "bg-[#dcfce7] text-[#00a76f]"
      : status === "Processing"
        ? "bg-[#fef3c7] text-[#f59e0b]"
        : "bg-[#dcfce7] text-[#00a76f]";

  return (
    <span
      className={cn(
        "inline-flex h-6 items-center justify-center rounded px-2 font-['Public_Sans',Arial,sans-serif] text-sm font-semibold leading-[22px] tracking-[0.22px]",
        styles,
      )}
    >
      {status}
    </span>
  );
}

const TICKET_FILTER_OPTIONS: Array<{ label: string; value: TicketStatus | "ALL" }> = [
  { label: "All",        value: "ALL" },
  { label: "Open",       value: "OPEN" },
  { label: "In Review",  value: "IN_REVIEW" },
  { label: "Resolved",   value: "RESOLVED" },
  { label: "Closed",     value: "CLOSED" },
];

function SupportSection() {
  const [filter, setFilter] = useState<TicketStatus | "ALL">("ALL");
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const status = filter === "ALL" ? undefined : filter;
  const { data: tickets = [], isLoading, isError, refetch } = useHelpTickets(status);

  return (
    <section id="support" aria-labelledby="support-title" className="min-h-0 flex-1 overflow-hidden">
      <Card className="flex h-full min-h-0 flex-col gap-3 overflow-hidden rounded-xl border-[#d6e6f2] bg-white p-3.5 shadow-none">

        {/* Header */}
        <div className="flex shrink-0 flex-col gap-4 lg:flex-row lg:items-center lg:px-2.5">
          <div className="min-w-0 flex-1">
            <h1 id="support-title" className="text-xl font-semibold leading-7 tracking-[0.1px] text-[#0f172a] lg:text-2xl">
              Help & Support
            </h1>
            <p className="text-sm font-normal text-[#7a7a7a]">Manage customer support tickets</p>
          </div>
          <div className="flex flex-wrap gap-1.5" role="group" aria-label="Filter by status">
            {TICKET_FILTER_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                type="button"
                onClick={() => { setFilter(opt.value); setExpandedId(null); }}
                className={cn(
                  "flex h-9 items-center justify-center rounded-lg px-4 text-sm font-medium transition-colors",
                  filter === opt.value
                    ? "bg-[linear-gradient(141deg,#e06f83_11%,#f093a3_32%,#e06f83_53%)] text-white shadow-[0_0_0_0_rgba(247,134,154,0.3)]"
                    : "border border-[#e0e0e0] bg-white text-[#4a4a4a] hover:bg-[#fdf2f4] hover:text-[#f7869a]",
                )}
                aria-pressed={filter === opt.value}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* List */}
        <div className="min-h-0 flex-1 overflow-auto rounded-xl border border-[#fdf2f4] p-2">
          {isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="flex flex-col items-center gap-2 text-sm font-medium text-[#7a7a7a]">
                <div className="size-7 animate-spin rounded-full border-2 border-[#f7869a] border-t-transparent" />
                Loading tickets…
              </div>
            </div>
          ) : isError ? (
            <div className="flex flex-col items-center gap-3 py-10">
              <p className="text-sm font-medium text-[#dc2626]">Failed to load support tickets.</p>
              <button type="button" onClick={() => refetch()} className="rounded-lg bg-[#fdf2f4] px-4 py-2 text-sm font-medium text-[#121212] hover:bg-[#f9e8ec]">Retry</button>
            </div>
          ) : tickets.length === 0 ? (
            <div className="flex min-h-[200px] items-center justify-center rounded-xl border border-dashed border-[#c4cdd5] text-sm font-medium text-[#7a7a7a]">
              No {filter === "ALL" ? "" : filter.replace("_", " ").toLowerCase() + " "}tickets found.
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {tickets.map((ticket) => (
                <SupportTicketCard
                  key={ticket.id}
                  ticket={ticket}
                  isExpanded={expandedId === ticket.id}
                  onToggle={() => setExpandedId(expandedId === ticket.id ? null : ticket.id)}
                />
              ))}
            </div>
          )}
        </div>
      </Card>
    </section>
  );
}

function SupportTicketCard({
  ticket,
  isExpanded,
  onToggle,
}: {
  ticket: import("@/lib/types/support.types").HelpTicket;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const { data: details } = useHelpTicket(ticket.id, isExpanded);
  const display = details ?? ticket;

  const markInReview = useMarkTicketInReview();
  const resolveTicket = useResolveTicket();
  const [resolvingAs, setResolvingAs] = useState<"RESOLVED" | "CLOSED" | null>(null);
  const [adminNote, setAdminNote] = useState("");

  const handleMarkInReview = () => {
    markInReview.mutate(ticket.id, {
      onSuccess: () => toast.success("Ticket marked as In Review."),
      onError: (err) => toast.error(err instanceof Error ? err.message : "Action failed."),
    });
  };

  const handleResolve = () => {
    if (!resolvingAs) return;
    resolveTicket.mutate({ id: ticket.id, payload: { status: resolvingAs, adminNote: adminNote.trim() || undefined } }, {
      onSuccess: () => {
        toast.success(`Ticket ${resolvingAs === "RESOLVED" ? "resolved" : "closed"}.`);
        setResolvingAs(null);
        setAdminNote("");
      },
      onError: (err) => toast.error(err instanceof Error ? err.message : "Action failed."),
    });
  };

  return (
    <article className="rounded-xl border border-[#e2e8f0] bg-white p-3">
      {/* Summary row */}
      <button
        type="button"
        className="flex w-full items-center gap-3 text-left"
        onClick={onToggle}
        aria-expanded={isExpanded}
      >
        <div className="flex min-w-0 flex-1 flex-col gap-1.5">
          <div className="flex items-center gap-2">
            <SupportStatusBadge status={ticket.status} />
            <span className="text-xs font-normal text-[#4a4a68]">{ticket.id.slice(0, 8).toUpperCase()}</span>
          </div>
          <h2 className="text-base font-semibold leading-6 text-[#0f172a]">{ticket.subject}</h2>
          <div className="flex items-center gap-1.5">
            <span className="size-2 rounded-full bg-[#d9d9d9]" aria-hidden="true" />
            <time className="text-xs font-medium text-[#4a4a4a]">
              {new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric" }).format(new Date(ticket.createdAt))}
            </time>
          </div>
        </div>
        <span className="flex size-7 shrink-0 items-center justify-center rounded-md text-[#33358e] hover:bg-[#f7f7f7]">
          {isExpanded ? <ChevronUpIcon className="size-5" /> : <ChevronDownIcon className="size-5" />}
        </span>
      </button>

      {/* Expanded content */}
      {isExpanded && (
        <div className="mt-3 flex flex-col gap-4 border-t border-[#e9eef4] pt-4">
          {/* Message */}
          <div className="rounded-lg border border-[#f2f2f2] bg-[#f7f7f7] px-4 py-3">
            <p className="text-sm font-normal leading-5 text-[#344056]">{display.message}</p>
          </div>

          {/* Sender info */}
          {display.sender && (
            <div className="flex items-center gap-3 rounded-lg border border-[#e0e0e0] bg-white px-3 py-2.5">
              <span className="flex size-8 items-center justify-center rounded-full bg-[#fdf2f4] text-sm font-semibold text-[#f7869a]">
                {(display.sender.name ?? display.sender.email)[0]?.toUpperCase()}
              </span>
              <div>
                <p className="text-sm font-semibold text-[#121212]">{display.sender.name ?? "Unknown"}</p>
                <p className="text-xs font-normal text-[#7a7a7a]">{display.sender.email}</p>
              </div>
            </div>
          )}

          {/* Existing admin note */}
          {display.adminNote && (
            <div className="flex items-start gap-2 rounded-lg border border-[#e0e0e0] bg-[#fdf2f4] px-3 py-2.5">
              <InfoCircleIcon className="mt-0.5 size-4 shrink-0 text-[#f7869a]" />
              <p className="text-sm font-normal text-[#4a4a4a]">{display.adminNote}</p>
            </div>
          )}

          {/* Actions */}
          {ticket.status === "OPEN" && (
            <button
              type="button"
              onClick={handleMarkInReview}
              disabled={markInReview.isPending}
              className="flex h-10 items-center justify-center gap-2 self-start rounded-lg bg-[#fef3c7] px-5 text-sm font-semibold text-[#d97706] transition-colors hover:bg-[#fde68a] disabled:opacity-60"
            >
              {markInReview.isPending ? "Updating…" : "Mark as In Review"}
            </button>
          )}

          {ticket.status === "IN_REVIEW" && (
            <>
              {resolvingAs ? (
                <div className="flex flex-col gap-2">
                  <label className="text-sm font-medium text-[#121212]">
                    Admin note <span className="font-normal text-[#7a7a7a]">(optional)</span>
                  </label>
                  <textarea
                    rows={3}
                    value={adminNote}
                    onChange={(e) => setAdminNote(e.target.value)}
                    placeholder="Add a note for the user…"
                    className="w-full rounded-xl border border-[#e0e0e0] p-3 text-sm focus:border-[#f7869a] focus:outline-none focus:ring-4 focus:ring-[#f7869a]/10"
                  />
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={handleResolve}
                      disabled={resolveTicket.isPending}
                      className={cn(
                        "flex h-10 items-center justify-center rounded-lg px-5 text-sm font-semibold transition-colors disabled:opacity-60",
                        resolvingAs === "RESOLVED"
                          ? "bg-[#dcfce7] text-[#16a34a] hover:bg-[#c9f7d9]"
                          : "bg-[#f1f5f9] text-[#64748b] hover:bg-[#e2e8f0]",
                      )}
                    >
                      {resolveTicket.isPending ? "Saving…" : `Confirm ${resolvingAs === "RESOLVED" ? "Resolve" : "Close"}`}
                    </button>
                    <button type="button" onClick={() => { setResolvingAs(null); setAdminNote(""); }} className="flex h-10 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-5 text-sm font-medium text-[#4a4a4a] hover:bg-[#f7f7f7]">
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <div className="flex gap-2">
                  <button type="button" onClick={() => setResolvingAs("RESOLVED")} className="flex h-10 items-center justify-center gap-1.5 rounded-lg bg-[#dcfce7] px-5 text-sm font-semibold text-[#16a34a] hover:bg-[#c9f7d9]">
                    <CheckIcon className="size-4" /> Resolve
                  </button>
                  <button type="button" onClick={() => setResolvingAs("CLOSED")} className="flex h-10 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-5 text-sm font-medium text-[#64748b] hover:bg-[#f1f5f9]">
                    Close
                  </button>
                </div>
              )}
            </>
          )}

          {(ticket.status === "RESOLVED" || ticket.status === "CLOSED") && (
            <div className="flex h-[44px] items-center gap-3 rounded-lg bg-[#dcfce7] px-3">
              <InfoCircleIcon className="size-5 shrink-0 text-[#16a34a]" />
              <p className="text-sm font-medium text-[#16a34a]">
                This ticket has been {ticket.status === "RESOLVED" ? "resolved" : "closed"}.
              </p>
            </div>
          )}
        </div>
      )}
    </article>
  );
}

function SupportStatusBadge({ status }: { status: string }) {
  const styles =
    status === "OPEN"
      ? "bg-[#ace3ff] text-[#006599]"
      : status === "IN_REVIEW"
        ? "bg-[#fef3c7] text-[#f59e0b]"
        : status === "RESOLVED"
          ? "bg-[#dcfce7] text-[#16a34a]"
          : "bg-[#f1f5f9] text-[#64748b]";

  const label =
    status === "OPEN" ? "Open"
      : status === "IN_REVIEW" ? "In Review"
        : status === "RESOLVED" ? "Resolved"
          : status === "CLOSED" ? "Closed"
            : status;

  return (
    <span className={cn("inline-flex h-7 items-center rounded-lg px-2.5 text-xs font-semibold shadow-[0_1px_1px_rgba(0,0,0,0.05)]", styles)}>
      {label}
    </span>
  );
}

function SettingsSection() {
  const [settingsTab, setSettingsTab] = useState<"profile" | "password" | "faq" | "privacy" | "terms" | "about">("profile");

  return (
    <section
      id="settings-panel"
      aria-labelledby="settings-title"
      className="flex min-h-0 flex-1 flex-col overflow-hidden lg:grid lg:grid-cols-[102px_minmax(0,1fr)]"
    >
      <aside
        className="shrink-0 overflow-x-auto border-b border-[#f2f2f2] bg-white px-4 py-4 lg:border-b-0 lg:border-r lg:px-[31px]"
        aria-label="Settings menu"
      >
        <h1
          id="settings-title"
          className="hidden px-2 text-xs font-medium leading-4 text-[#121212] lg:block"
        >
          Setting
        </h1>
        <div className="flex gap-2 lg:mt-2 lg:flex-col">
          <SettingsIconButton
            label="Profile information"
            active={settingsTab === "profile"}
            onClick={() => setSettingsTab("profile")}
          >
            <ProfileCircleIcon className="size-6" />
          </SettingsIconButton>
          <SettingsIconButton
            label="Change password"
            active={settingsTab === "password"}
            onClick={() => setSettingsTab("password")}
          >
            <PasswordCheckIcon className="size-6" />
          </SettingsIconButton>
          <SettingsIconButton
            label="FAQ"
            active={settingsTab === "faq"}
            onClick={() => setSettingsTab("faq")}
          >
            <QuestionIcon className="size-6" />
          </SettingsIconButton>
          <SettingsIconButton
            label="Privacy Policy"
            active={settingsTab === "privacy"}
            onClick={() => setSettingsTab("privacy")}
          >
            <ShieldIcon className="size-6" />
          </SettingsIconButton>
          <SettingsIconButton
            label="Terms & Conditions"
            active={settingsTab === "terms"}
            onClick={() => setSettingsTab("terms")}
          >
            <DocumentNormalIcon className="size-6" />
          </SettingsIconButton>
          <SettingsIconButton
            label="About Us"
            active={settingsTab === "about"}
            onClick={() => setSettingsTab("about")}
          >
            <AboutUsIcon className="size-6" />
          </SettingsIconButton>
        </div>
      </aside>

      <div className="min-h-0 flex-1 overflow-auto py-6 lg:pl-6 lg:pr-0">
        {settingsTab === "profile" ? <ProfileSettingsPanel /> : null}
        {settingsTab === "password" ? <PasswordSettingsPanel /> : null}
        {settingsTab === "faq" ? <FAQSettingsPanel /> : null}
        {settingsTab === "privacy" ? <StaticContentSettingsPanel contentKey="privacy-policy" pageTitle="Privacy Policy" /> : null}
        {settingsTab === "terms" ? <StaticContentSettingsPanel contentKey="terms-of-service" pageTitle="Terms & Conditions" /> : null}
        {settingsTab === "about" ? <StaticContentSettingsPanel contentKey="about-us" pageTitle="About Us" /> : null}
      </div>
    </section>
  );
}

function SettingsIconButton({
  active,
  children,
  label,
  onClick,
}: {
  active: boolean;
  children: React.ReactNode;
  label: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      className={cn(
        "flex size-12 shrink-0 items-center justify-center rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30",
        active
          ? "bg-[#fdf2f4] text-[#e06f83]"
          : "text-[#4a4a4a] hover:bg-[#f7f7f7] hover:text-[#e06f83]",
      )}
      aria-label={label}
      title={label}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

function ProfileSettingsPanel() {
  const { data: profile, isLoading, isError, refetch } = useAdminProfile();
  const profileKey = [
    profile?.id,
    profile?.email,
    profile?.fullName,
    profile?.phoneNumber,
    profile?.profileImageUrl,
    profile?.imageUrl,
  ].join(":");

  return (
    <ProfileSettingsForm
      key={profileKey}
      profile={profile}
      isLoading={isLoading}
      isError={isError}
      onRetry={() => refetch()}
    />
  );
}

function ProfileSettingsForm({
  profile,
  isLoading,
  isError,
  onRetry,
}: {
  profile?: AdminProfile;
  isLoading: boolean;
  isError: boolean;
  onRetry: () => void;
}) {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const updateProfile = useUpdateAdminProfile();
  const uploadImage = useUploadAdminProfileImage();

  const [fullName, setFullName] = useState(profile?.fullName ?? "");
  const [email, setEmail] = useState(profile?.email ?? "");
  const [phoneNumber, setPhoneNumber] = useState(profile?.phoneNumber ?? "");
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);

  const previewUrl = useMemo(
    () => (selectedImage ? URL.createObjectURL(selectedImage) : null),
    [selectedImage],
  );

  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  const profileImageUrl =
    previewUrl ?? profile?.profileImageUrl ?? profile?.imageUrl ?? "/figma-assets/heba-avatar.png";
  const canUploadImage = selectedImage != null && !uploadImage.isPending;

  const handleImageChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0] ?? null;
    setUploadError(null);

    if (!file) {
      setSelectedImage(null);
      return;
    }

    if (!file.type.startsWith("image/")) {
      setSelectedImage(null);
      setUploadError("Please choose an image file.");
      event.target.value = "";
      return;
    }

    setSelectedImage(file);
  };

  const handleSaveProfile = () => {
    updateProfile.mutate(
      {
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
      },
      {
        onSuccess: () => toast.success("Profile information saved."),
        onError: (err) =>
          toast.error(err instanceof Error ? err.message : "Profile update failed."),
      },
    );
  };

  const handleUploadImage = () => {
    if (!selectedImage) return;
    setUploadError(null);

    uploadImage.mutate(selectedImage, {
      onSuccess: () => {
        toast.success("Profile image updated.");
        setSelectedImage(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
      },
      onError: (err) => {
        const message =
          err instanceof Error ? err.message : "Profile image upload failed.";
        setUploadError(message);
        toast.error(message);
      },
    });
  };

  return (
    <SettingsPanel
      icon={<ProfileCircleIcon className="size-6 text-[#e06f83]" />}
      title="Profile Information"
      actionLabel="Save Profile Change"
      onAction={handleSaveProfile}
      isActionLoading={updateProfile.isPending}
    >
      <div className="flex flex-col gap-4 rounded-lg bg-white p-3">
        {isError ? (
          <div className="flex flex-col gap-3 rounded-lg border border-[#fecaca] bg-[#fef2f2] px-4 py-3 text-sm font-medium text-[#b91c1c] sm:flex-row sm:items-center sm:justify-between">
            <span>Unable to load admin profile.</span>
            <button
              type="button"
              onClick={onRetry}
              className="self-start rounded-lg bg-white px-3 py-2 text-[#991b1b] hover:bg-[#fee2e2] sm:self-auto"
            >
              Retry
            </button>
          </div>
        ) : null}

        <div className="flex flex-col gap-4 rounded-lg border border-[#f2f2f2] bg-[#fff8f9] p-4 sm:flex-row sm:items-center">
          <div
            aria-label="Admin profile image"
            role="img"
            className="size-24 shrink-0 rounded-full border border-[#f5c9d1] bg-white bg-cover bg-center shadow-[0_8px_18px_rgba(224,111,131,0.14)]"
            style={{ backgroundImage: `url("${profileImageUrl}")` }}
          />
          <div className="flex min-w-0 flex-1 flex-col gap-2">
            <p className="text-base font-semibold text-[#121212]">
              {selectedImage ? selectedImage.name : "Profile photo"}
            </p>
            <p className="text-sm text-[#7a7a7a]">
              Choose an image file, preview it here, then upload it to update your admin avatar.
            </p>
            {uploadError ? (
              <p className="text-sm font-medium text-[#dc2626]">{uploadError}</p>
            ) : null}
            <div className="flex flex-wrap gap-2 pt-1">
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleImageChange}
                className="sr-only"
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="flex h-10 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-4 text-sm font-medium text-[#121212] hover:bg-[#f7f7f7]"
              >
                Choose Image
              </button>
              <button
                type="button"
                onClick={handleUploadImage}
                disabled={!canUploadImage}
                className="flex h-10 items-center justify-center rounded-lg bg-[#f7869a] px-4 text-sm font-semibold text-white hover:bg-[#f2738b] disabled:opacity-60"
              >
                {uploadImage.isPending ? "Uploading..." : "Upload Image"}
              </button>
            </div>
          </div>
        </div>

        <SettingsField
          label="Full Name"
          placeholder="Example"
          value={fullName}
          onChange={(event) => setFullName(event.target.value)}
          disabled={isLoading}
        />
        <div className="mt-3.5 grid gap-3.5 md:grid-cols-2">
          <SettingsField
            label="Email Address"
            placeholder="Example@email.com"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            disabled={isLoading}
          />
          <SettingsField
            label="Phone Number"
            placeholder="Example123"
            type="tel"
            value={phoneNumber}
            onChange={(event) => setPhoneNumber(event.target.value)}
            disabled={isLoading}
          />
        </div>
      </div>
    </SettingsPanel>
  );
}

function PasswordSettingsPanel() {
  return (
    <SettingsPanel
      icon={<PasswordCheckIcon className="size-6 text-[#e06f83]" />}
      title="Change Your Password"
      actionLabel="Update Password"
    >
      <div className="rounded-lg bg-white p-3">
        <div className="flex flex-col gap-3.5">
          <SettingsField label="Current Password" placeholder="Enter current password" type="password" />
          <SettingsField label="New Password" placeholder="Create a new secure password" type="password" />
          <SettingsField label="Confirm Password" placeholder="Re-enter new password to confirm" type="password" />
        </div>
      </div>
    </SettingsPanel>
  );
}

function FAQSettingsPanel() {
  const { data: rawFaqs = [], isLoading, isError, refetch } = useFaqs();
  const createFaq = useCreateFaq();
  const updateFaq = useUpdateFaq();
  const deleteFaq = useDeleteFaq();
  const reorderFaqs = useReorderFaqs();

  // sort by order
  const faqs = [...rawFaqs].sort((a, b) => a.order - b.order);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [editQ, setEditQ] = useState("");
  const [editA, setEditA] = useState("");
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [newQ, setNewQ] = useState("");
  const [newA, setNewA] = useState("");

  const startEdit = (id: string, question: string, answer: string) => {
    setEditingId(id);
    setEditQ(question);
    setEditA(answer);
  };

  const saveEdit = (id: string) => {
    if (!editQ.trim()) { toast.error("Question cannot be empty."); return; }
    updateFaq.mutate({ id, payload: { question: editQ.trim(), answer: editA.trim() } }, {
      onSuccess: () => { toast.success("FAQ updated."); setEditingId(null); },
      onError: (err) => toast.error(err instanceof Error ? err.message : "Update failed."),
    });
  };

  const toggleActive = (id: string, current: boolean) => {
    updateFaq.mutate({ id, payload: { isActive: !current } }, {
      onError: (err) => toast.error(err instanceof Error ? err.message : "Update failed."),
    });
  };

  const handleDelete = (id: string) => {
    deleteFaq.mutate(id, {
      onSuccess: () => { toast.success("FAQ deleted."); setConfirmDeleteId(null); },
      onError: (err) => toast.error(err instanceof Error ? err.message : "Delete failed."),
    });
  };

  const move = (idx: number, dir: -1 | 1) => {
    const next = idx + dir;
    if (next < 0 || next >= faqs.length) return;
    const items = faqs.map((f, i) => {
      if (i === idx) return { id: f.id, order: faqs[next].order };
      if (i === next) return { id: f.id, order: faqs[idx].order };
      return { id: f.id, order: f.order };
    });
    reorderFaqs.mutate(items, {
      onError: (err) => toast.error(err instanceof Error ? err.message : "Reorder failed."),
    });
  };

  const handleCreate = () => {
    if (!newQ.trim()) { toast.error("Question cannot be empty."); return; }
    const nextOrder = faqs.length > 0 ? Math.max(...faqs.map((f) => f.order)) + 1 : 0;
    createFaq.mutate({ question: newQ.trim(), answer: newA.trim(), order: nextOrder, isActive: true }, {
      onSuccess: () => {
        toast.success("FAQ created.");
        setIsAddingNew(false);
        setNewQ("");
        setNewA("");
      },
      onError: (err) => toast.error(err instanceof Error ? err.message : "Create failed."),
    });
  };

  return (
    <SettingsPanel
      icon={<QuestionIcon className="size-6 text-[#e06f83]" />}
      title="Frequently Asked Questions"
      actionLabel="Add New FAQ"
      onAction={() => { setIsAddingNew(true); setEditingId(null); }}
    >
      <div className="flex flex-col gap-3 rounded-lg bg-white p-3">
        {isLoading && (
          <div className="flex items-center justify-center py-8">
            <div className="size-6 animate-spin rounded-full border-2 border-[#f7869a] border-t-transparent" />
          </div>
        )}
        {isError && (
          <div className="flex flex-col items-center gap-3 py-6">
            <p className="text-sm font-medium text-[#dc2626]">Failed to load FAQs.</p>
            <button type="button" onClick={() => refetch()} className="rounded-lg bg-[#fdf2f4] px-4 py-2 text-sm font-medium text-[#121212] hover:bg-[#f9e8ec]">Retry</button>
          </div>
        )}

        {!isLoading && !isError && faqs.length === 0 && !isAddingNew && (
          <p className="py-6 text-center text-sm font-medium text-[#7a7a7a]">No FAQs yet. Click "Add New FAQ" to get started.</p>
        )}

        {faqs.map((faq, idx) => (
          <div key={faq.id} className="flex flex-col gap-3 rounded-xl border border-[#f2f2f2] p-3">
            {editingId === faq.id ? (
              /* ── Edit mode ── */
              <div className="flex flex-col gap-3">
                <SettingsTextArea label="Question" placeholder="Enter question" value={editQ} onChange={(e) => setEditQ(e.target.value)} />
                <SettingsTextArea label="Answer" placeholder="Enter answer" value={editA} onChange={(e) => setEditA(e.target.value)} rows={4} />
                <div className="flex items-center gap-2">
                  <button type="button" onClick={() => saveEdit(faq.id)} disabled={updateFaq.isPending} className="flex h-10 items-center justify-center rounded-lg bg-[linear-gradient(151deg,#e06f83_11%,#f093a3_32%,#e06f83_53%)] px-5 text-sm font-medium text-white disabled:opacity-60">
                    {updateFaq.isPending ? "Saving…" : "Save"}
                  </button>
                  <button type="button" onClick={() => setEditingId(null)} className="flex h-10 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-5 text-sm font-medium text-[#4a4a4a] hover:bg-[#f7f7f7]">Cancel</button>
                </div>
              </div>
            ) : confirmDeleteId === faq.id ? (
              /* ── Delete confirm ── */
              <div className="flex flex-col gap-2">
                <p className="text-sm font-medium text-[#dc2626]">Delete this FAQ?</p>
                <p className="line-clamp-1 text-xs text-[#7a7a7a]">{faq.question}</p>
                <div className="flex gap-2">
                  <button type="button" onClick={() => handleDelete(faq.id)} disabled={deleteFaq.isPending} className="flex h-9 items-center justify-center rounded-lg bg-[#fee2e2] px-4 text-sm font-semibold text-[#dc2626] hover:bg-[#fbd4d4] disabled:opacity-60">
                    {deleteFaq.isPending ? "Deleting…" : "Yes, Delete"}
                  </button>
                  <button type="button" onClick={() => setConfirmDeleteId(null)} className="flex h-9 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-4 text-sm font-medium text-[#4a4a4a] hover:bg-[#f7f7f7]">Cancel</button>
                </div>
              </div>
            ) : (
              /* ── Display mode ── */
              <div className="flex flex-col gap-2">
                <div className="flex items-start justify-between gap-3">
                  <p className="flex-1 text-sm font-semibold leading-5 text-[#121212]">{faq.question}</p>
                  <div className="flex shrink-0 items-center gap-1">
                    {/* Active toggle */}
                    <button type="button" onClick={() => toggleActive(faq.id, faq.isActive)} className={cn("flex h-6 items-center rounded-full px-2 text-xs font-semibold transition-colors", faq.isActive ? "bg-[#dcfce7] text-[#16a34a] hover:bg-[#c9f7d9]" : "bg-[#f2f2f2] text-[#7a7a7a] hover:bg-[#e8e8e8]")} title={faq.isActive ? "Click to deactivate" : "Click to activate"}>
                      {faq.isActive ? "Active" : "Inactive"}
                    </button>
                    {/* Up */}
                    <button type="button" onClick={() => move(idx, -1)} disabled={idx === 0} className="flex size-7 items-center justify-center rounded-md text-[#7a7a7a] hover:bg-[#f7f7f7] disabled:opacity-30" aria-label="Move up">
                      <ChevronUpIcon className="size-4" />
                    </button>
                    {/* Down */}
                    <button type="button" onClick={() => move(idx, 1)} disabled={idx === faqs.length - 1} className="flex size-7 items-center justify-center rounded-md text-[#7a7a7a] hover:bg-[#f7f7f7] disabled:opacity-30" aria-label="Move down">
                      <ChevronDownIcon className="size-4" />
                    </button>
                    {/* Edit */}
                    <button type="button" onClick={() => startEdit(faq.id, faq.question, faq.answer)} className="flex size-7 items-center justify-center rounded-md text-[#7a7a7a] hover:bg-[#fdf2f4] hover:text-[#f7869a]" aria-label="Edit FAQ">
                      <EditPencilSmIcon className="size-4" />
                    </button>
                    {/* Delete */}
                    <button type="button" onClick={() => setConfirmDeleteId(faq.id)} className="flex size-7 items-center justify-center rounded-md text-[#7a7a7a] hover:bg-[#fee2e2] hover:text-[#dc2626]" aria-label="Delete FAQ">
                      <TrashIcon className="size-4" />
                    </button>
                  </div>
                </div>
                {faq.answer && (
                  <p className="text-sm font-normal leading-5 text-[#4a4a4a]">{faq.answer}</p>
                )}
              </div>
            )}
          </div>
        ))}

        {/* Add new FAQ form */}
        {isAddingNew && (
          <div className="flex flex-col gap-3 rounded-xl border border-dashed border-[#f7869a] bg-[#fdf2f4] p-3">
            <p className="text-sm font-semibold text-[#e06f83]">New FAQ</p>
            <SettingsTextArea label="Question" placeholder="Enter question" value={newQ} onChange={(e) => setNewQ(e.target.value)} />
            <SettingsTextArea label="Answer" placeholder="Enter answer" value={newA} onChange={(e) => setNewA(e.target.value)} rows={4} />
            <div className="flex items-center gap-2">
              <button type="button" onClick={handleCreate} disabled={createFaq.isPending} className="flex h-10 items-center justify-center gap-2 rounded-lg bg-[linear-gradient(151deg,#e06f83_11%,#f093a3_32%,#e06f83_53%)] px-5 text-sm font-medium text-white disabled:opacity-60">
                <PlusIcon className="size-4" />
                {createFaq.isPending ? "Adding…" : "Add FAQ"}
              </button>
              <button type="button" onClick={() => { setIsAddingNew(false); setNewQ(""); setNewA(""); }} className="flex h-10 items-center justify-center rounded-lg border border-[#e0e0e0] bg-white px-5 text-sm font-medium text-[#4a4a4a] hover:bg-[#f7f7f7]">Cancel</button>
            </div>
          </div>
        )}
      </div>
    </SettingsPanel>
  );
}

function StaticContentSettingsPanel({
  contentKey,
  pageTitle,
}: {
  contentKey: StaticContentKey;
  pageTitle: string;
}) {
  const { data, isLoading } = useStaticContent(contentKey);
  const saveContent = useSaveStaticContent();
  const [localTitle, setLocalTitle] = useState("");
  const [localContent, setLocalContent] = useState("");
  const [synced, setSynced] = useState(false);

  // Sync from API once data arrives
  useEffect(() => {
    if (data && !synced) {
      setLocalTitle(data.title || pageTitle);
      setLocalContent(data.content || "");
      setSynced(true);
    }
  }, [data, pageTitle, synced]);

  const handleSave = () => {
    saveContent.mutate(
      { key: contentKey, payload: { title: localTitle, content: localContent } },
      {
        onSuccess: () => toast.success(`${pageTitle} saved successfully.`),
        onError: (err) =>
          toast.error(err instanceof Error ? err.message : "Save failed."),
      },
    );
  };

  const icon =
    contentKey === "privacy-policy" ? (
      <ShieldIcon className="size-6 text-[#e06f83]" />
    ) : contentKey === "terms-of-service" ? (
      <DocumentNormalIcon className="size-6 text-[#e06f83]" />
    ) : (
      <AboutUsIcon className="size-6 text-[#e06f83]" />
    );

  return (
    <SettingsPanel
      icon={icon}
      title={pageTitle}
      actionLabel={`Save ${pageTitle}`}
      onAction={handleSave}
      isActionLoading={saveContent.isPending}
    >
      <div className="flex flex-col gap-3.5 rounded-lg bg-white p-3">
        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <div className="size-6 animate-spin rounded-full border-2 border-[#f7869a] border-t-transparent" />
          </div>
        ) : (
          <>
            <SettingsField
              label="Page Title"
              placeholder={pageTitle}
              value={localTitle}
              onChange={(e) => setLocalTitle(e.target.value)}
            />
            <SettingsTextArea
              label="Content"
              placeholder={`Enter the ${pageTitle.toLowerCase()} text here…`}
              rows={14}
              value={localContent}
              onChange={(e) => setLocalContent(e.target.value)}
            />
            {data?.updatedAt && (
              <p className="text-xs font-normal text-[#7a7a7a]">
                Last saved:{" "}
                {new Intl.DateTimeFormat("en-US", {
                  month: "short",
                  day: "numeric",
                  year: "numeric",
                  hour: "numeric",
                  minute: "2-digit",
                }).format(new Date(data.updatedAt))}
              </p>
            )}
          </>
        )}
      </div>
    </SettingsPanel>
  );
}

function SettingsTextArea({
  label,
  placeholder,
  rows = 3,
  value,
  onChange,
}: {
  label: string;
  placeholder: string;
  rows?: number;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
}) {
  return (
    <label className="flex flex-col gap-2">
      <span className="text-base font-medium leading-6 tracking-[0.08px] text-[#121212]">
        {label}
      </span>
      <textarea
        placeholder={placeholder}
        rows={rows}
        value={value}
        onChange={onChange}
        className="rounded-lg border border-[#cbd5ed] bg-white px-4 py-3 text-base font-normal leading-6 tracking-[0.08px] text-[#121212] outline-none placeholder:text-[#7a7a7a] focus:border-[#f7869a] focus:ring-4 focus:ring-[#f7869a]/15"
      />
    </label>
  );
}

function SettingsPanel({
  actionLabel,
  children,
  icon,
  title,
  onAction,
  isActionLoading,
}: {
  actionLabel: string;
  children: React.ReactNode;
  icon: React.ReactNode;
  title: string;
  onAction?: () => void;
  isActionLoading?: boolean;
}) {
  return (
    <Card className="flex w-full flex-col gap-[18px] rounded-[14px] border-[#e0e0e0] bg-[#fdf2f4] px-3 py-3.5 shadow-none">
      <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
        <div className="flex min-w-0 flex-1 items-center gap-2.5">
          <span className="shrink-0">{icon}</span>
          <h2 className="min-w-0 flex-1 text-xl font-semibold leading-7 tracking-[0.1px] text-black">
            {title}
          </h2>
        </div>
        <button
          type="button"
          onClick={onAction}
          disabled={isActionLoading}
          className="flex h-12 w-full shrink-0 items-center justify-center rounded-lg border border-[#f2f2f2] bg-[linear-gradient(151deg,#e06f83_11%,#f093a3_32%,#e06f83_53%)] px-6 py-3 text-base font-medium leading-6 tracking-[0.08px] text-white transition-shadow hover:shadow-[0_0_0_2px_rgba(247,134,154,0.3)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30 disabled:opacity-60 sm:w-auto"
        >
          {isActionLoading ? "Saving…" : actionLabel}
        </button>
      </div>
      {children}
    </Card>
  );
}

function SettingsField({
  disabled,
  label,
  placeholder,
  type = "text",
  value,
  onChange,
}: {
  disabled?: boolean;
  label: string;
  placeholder: string;
  type?: React.HTMLInputTypeAttribute;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
}) {
  return (
    <label className="flex flex-col gap-2">
      <span className="text-base font-medium leading-6 tracking-[0.08px] text-[#121212]">
        {label}
      </span>
      <input
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        disabled={disabled}
        className="h-12 rounded-lg border border-[#cbd5ed] bg-white px-4 py-3 text-base font-normal leading-6 tracking-[0.08px] text-[#121212] outline-none placeholder:text-[#7a7a7a] focus:border-[#f7869a] focus:ring-4 focus:ring-[#f7869a]/15 disabled:bg-[#f7f7f7] disabled:text-[#7a7a7a]"
      />
    </label>
  );
}

function ComingSoonSection({ section }: { section: DashboardSection }) {
  const title =
    section === "trainers"
      ? "Trainer"
      : section === "verification"
        ? "Verification"
        : section === "transactions"
          ? "Transactions"
          : section === "support"
            ? "Support"
            : "Settings";

  return (
    <section
      id={`${section}-panel`}
      aria-labelledby={`${section}-title`}
      className="flex min-h-[520px] items-center justify-center rounded-lg border border-dashed border-[#c4cdd5] bg-white"
    >
      <h1 id={`${section}-title`} className="text-xl font-medium text-[#454f5b]">
        {title} section coming next
      </h1>
    </section>
  );
}

function TablePagination() {
  return (
    <div className="flex h-16 items-center justify-end gap-4 bg-white px-3 py-2 font-['Public_Sans',Arial,sans-serif] text-sm leading-[22px] tracking-[0.22px] text-[#1c252e]">
      <div className="flex items-center gap-2">
        <span>Rows per page:</span>
        <button
          type="button"
          className="flex items-center gap-1 rounded-md px-1 focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
          aria-label="Rows per page, 10"
        >
          10 <ChevronDownSmallIcon className="size-4" />
        </button>
      </div>
      <div className="flex items-center gap-2">
        <span>1-10</span>
        <span>of</span>
        <span>20</span>
      </div>
      <button
        type="button"
        className="flex size-6 items-center justify-center rounded-md text-[#454f5b] hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
        aria-label="Previous page"
      >
        <ChevronLeftIcon className="size-5" />
      </button>
      <button
        type="button"
        className="flex size-6 items-center justify-center rounded-md text-[#454f5b] hover:bg-[#f7f7f7] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#f7869a]/30"
        aria-label="Next page"
      >
        <ChevronRightIcon className="size-5" />
      </button>
    </div>
  );
}

function MemberHeader({
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

function StatusBadge({ status }: { status: string }) {
  const styles =
    status === "Active"
      ? "bg-[#dcfce7] text-[#16a34a]"
      : status === "Pending"
        ? "bg-[#fef3c7] text-[#d97706]"
        : status === "Suspended"
          ? "bg-[#fee2e2] text-[#dc2626]"
          : status === "Inactive"
            ? "bg-[#f1f5f9] text-[#64748b]"
            : "bg-[#f2f2f2] text-[#7a7a7a]";

  return (
    <span
      className={cn(
        "inline-flex h-6 items-center justify-center rounded px-2 text-sm font-semibold leading-[22px] tracking-[0.22px]",
        styles,
      )}
    >
      {status}
    </span>
  );
}

type IconComponent = (props: { className?: string; active?: boolean }) => React.ReactElement;

function OverviewIcon({ className, active }: { className?: string; active?: boolean }) {
  if (active) {
    return (
      <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
        <path d="M11 19.9V4.1C11 2.6 10.36 2 8.77 2H4.73C3.14 2 2.5 2.6 2.5 4.1V19.9C2.5 21.4 3.14 22 4.73 22H8.77C10.36 22 11 21.4 11 19.9Z" fill="white" />
        <path d="M21.5 10.9V4.1C21.5 2.6 20.86 2 19.27 2H15.23C13.64 2 13 2.6 13 4.1V10.9C13 12.4 13.64 13 15.23 13H19.27C20.86 13 21.5 12.4 21.5 10.9Z" fill="white" />
        <path d="M21.5 19.9V17.1C21.5 15.6 20.86 15 19.27 15H15.23C13.64 15 13 15.6 13 17.1V19.9C13 21.4 13.64 22 15.23 22H19.27C20.86 22 21.5 21.4 21.5 19.9Z" fill="white" />
      </svg>
    );
  }
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M4.73047 2.5H8.76953C9.52094 2.5 9.91957 2.64547 10.1387 2.85156C10.3501 3.05042 10.4999 3.40644 10.5 4.09961V19.9004C10.4999 20.5936 10.3501 20.9496 10.1387 21.1484C9.91957 21.3545 9.52094 21.5 8.76953 21.5H4.73047C3.97906 21.5 3.58043 21.3545 3.36133 21.1484C3.14995 20.9496 3.00006 20.5936 3 19.9004V4.09961C3.00006 3.40644 3.14995 3.05042 3.36133 2.85156C3.58043 2.64547 3.97906 2.5 4.73047 2.5Z" fill="white" stroke="currentColor" strokeWidth="1.5" />
      <path d="M15.2305 2.5H19.2695C20.0209 2.5 20.4196 2.64547 20.6387 2.85156C20.8501 3.05042 20.9999 3.40644 21 4.09961V10.9004C20.9999 11.5936 20.8501 11.9496 20.6387 12.1484C20.4196 12.3545 20.0209 12.5 19.2695 12.5H15.2305C14.4791 12.5 14.0804 12.3545 13.8613 12.1484C13.6499 11.9496 13.5001 11.5936 13.5 10.9004V4.09961C13.5001 3.40644 13.6499 3.05042 13.8613 2.85156C14.0804 2.64547 14.4791 2.5 15.2305 2.5Z" fill="white" stroke="currentColor" strokeWidth="1.5" />
      <path d="M15.2305 15.5H19.2695C20.0209 15.5 20.4196 15.6455 20.6387 15.8516C20.8501 16.0504 20.9999 16.4064 21 17.0996V19.9004C20.9999 20.5936 20.8501 20.9496 20.6387 21.1484C20.4196 21.3545 20.0209 21.5 19.2695 21.5H15.2305C14.4791 21.5 14.0804 21.3545 13.8613 21.1484C13.6499 20.9496 13.5001 20.5936 13.5 19.9004V17.0996L13.5068 16.8555C13.5384 16.32 13.6763 16.0256 13.8613 15.8516C14.0804 15.6455 14.4791 15.5 15.2305 15.5Z" fill="white" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function MembersIcon({ className, active }: { className?: string; active?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path
        d="M9.16055 10.87C9.06055 10.86 8.94055 10.86 8.83055 10.87C6.45055 10.79 4.56055 8.84 4.56055 6.44C4.56055 3.99 6.54055 2 9.00055 2C11.4505 2 13.4405 3.99 13.4405 6.44C13.4305 8.84 11.5405 10.79 9.16055 10.87Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M16.4093 4C18.3493 4 19.9093 5.57 19.9093 7.5C19.9093 9.39 18.4093 10.93 16.5393 11C16.4593 10.99 16.3693 10.99 16.2793 11"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M4.1607 14.56C1.7407 16.18 1.7407 18.82 4.1607 20.43C6.9107 22.27 11.4207 22.27 14.1707 20.43C16.5907 18.81 16.5907 16.17 14.1707 14.56C11.4307 12.73 6.9207 12.73 4.1607 14.56Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M18.3398 20C19.0598 19.85 19.7398 19.56 20.2998 19.13C21.8598 17.96 21.8598 16.03 20.2998 14.86C19.7498 14.44 19.0798 14.16 18.3698 14"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function TrainerIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M6 14 14 6M4 12l8 8M12 4l8 8" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
      <path d="m3 15 6 6M15 3l6 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  );
}

function ShieldIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M12 3 5 6v5.5c0 4.4 2.8 7.7 7 9.5 4.2-1.8 7-5.1 7-9.5V6l-7-3Z" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round" />
      <path d="m9 12 2 2 4-4" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function CardIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="3" y="5" width="18" height="14" rx="2.5" stroke="currentColor" strokeWidth="1.7" />
      <path d="M3 10h18M7 15h3" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function RevenueNavIcon({ className, active }: { className?: string; active?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle
        cx="12" cy="12" r="9"
        stroke={active ? "white" : "currentColor"}
        strokeWidth="1.7"
      />
      <path
        d="M12 7v1m0 8v1m3-6.5a3 3 0 0 0-3-1.5 2.5 2.5 0 0 0 0 5 2.5 2.5 0 0 1 0 5A3 3 0 0 1 9 18"
        stroke={active ? "white" : "currentColor"}
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

function ProfileCircleIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="9" fill="currentColor" opacity="0.16" />
      <path d="M12 12.4a3.2 3.2 0 1 0 0-6.4 3.2 3.2 0 0 0 0 6.4Z" fill="currentColor" opacity="0.9" />
      <path d="M6.8 18.2c.9-2.3 2.7-3.5 5.2-3.5s4.3 1.2 5.2 3.5" fill="currentColor" opacity="0.9" />
    </svg>
  );
}

function PasswordCheckIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="4" y="9" width="16" height="11" rx="3" fill="currentColor" opacity="0.16" />
      <path d="M8 9V7.6C8 5.1 9.5 3.5 12 3.5s4 1.6 4 4.1V9" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <path d="m9.4 14.7 1.8 1.8 3.6-4" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function SupportIcon({ className, active }: { className?: string; active?: boolean }) {
  const viewBox = "8 8 22 24";
  if (active) {
    return (
      <svg
        viewBox={viewBox}
        fill="none"
        className={className}
        aria-hidden="true"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M25 26.85H24.24C23.44 26.85 22.68 27.16 22.12 27.72L20.41 29.41C19.63 30.18 18.36 30.18 17.58 29.41L15.87 27.72C15.31 27.16 14.54 26.85 13.75 26.85H13C11.34 26.85 10 25.52 10 23.88V12.97C10 11.33 11.34 10 13 10H25C26.66 10 28 11.33 28 12.97V23.88C28 25.51 26.66 26.85 25 26.85Z"
          stroke="white"
          strokeWidth="1.5"
          strokeMiterlimit="10"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M14 17.15C14 16.22 14.76 15.46 15.69 15.46C16.62 15.46 17.38 16.22 17.38 17.15C17.38 19.03 14.71 19.23 14.12 21.02C14 21.39 14.31 21.76 14.7 21.76H17.38"
          stroke="white"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M23.0398 21.7501V16.0401C23.0398 15.7801 22.8698 15.5501 22.6198 15.4801C22.3698 15.4101 22.0998 15.5101 21.9598 15.7301C21.2398 16.8901 20.4598 18.2101 19.7798 19.3701C19.6698 19.5601 19.6698 19.8101 19.7798 20.0001C19.8898 20.1901 20.0998 20.31 20.3298 20.31H23.9998"
          stroke="white"
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    );
  }
  return (
    <svg
      viewBox={viewBox}
      fill="none"
      className={className}
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M25 26.85H24.24C23.44 26.85 22.68 27.16 22.12 27.72L20.41 29.41C19.63 30.18 18.36 30.18 17.58 29.41L15.87 27.72C15.31 27.16 14.54 26.85 13.75 26.85H13C11.34 26.85 10 25.52 10 23.88V12.97C10 11.33 11.34 10 13 10H25C26.66 10 28 11.33 28 12.97V23.88C28 25.51 26.66 26.85 25 26.85Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeMiterlimit="10"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M14 17.15C14 16.22 14.76 15.46 15.69 15.46C16.62 15.46 17.38 16.22 17.38 17.15C17.38 19.03 14.71 19.23 14.12 21.02C14 21.39 14.31 21.76 14.7 21.76H17.38"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M23.0398 21.7501V16.0401C23.0398 15.7801 22.8698 15.5501 22.6198 15.4801C22.3698 15.4101 22.0998 15.5101 21.9598 15.7301C21.2398 16.8901 20.4598 18.2101 19.7798 19.3701C19.6698 19.5601 19.6698 19.8101 19.7798 20.0001C19.8898 20.1901 20.0998 20.31 20.3298 20.31H23.9998"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function SettingsIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      className={className}
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 15C13.6569 15 15 13.6569 15 12C15 10.3431 13.6569 9 12 9C10.3431 9 9 10.3431 9 12C9 13.6569 10.3431 15 12 15Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeMiterlimit="10"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M2 12.8804V11.1204C2 10.0804 2.85 9.22043 3.9 9.22043C5.71 9.22043 6.45 7.94042 5.54 6.37042C5.02 5.47042 5.33 4.30042 6.24 3.78042L7.97 2.79042C8.76 2.32042 9.78 2.60042 10.25 3.39042L10.36 3.58042C11.26 5.15042 12.74 5.15042 13.65 3.58042L13.76 3.39042C14.23 2.60042 15.25 2.32042 16.04 2.79042L17.77 3.78042C18.68 4.30042 18.99 5.47042 18.47 6.37042C17.56 7.94042 18.3 9.22043 20.11 9.22043C21.15 9.22043 22.01 10.0704 22.01 11.1204V12.8804C22.01 13.9204 21.16 14.7804 20.11 14.7804C18.3 14.7804 17.56 16.0604 18.47 17.6304C18.99 18.5404 18.68 19.7004 17.77 20.2204L16.04 21.2104C15.25 21.6804 14.23 21.4004 13.76 20.6104L13.65 20.4204C12.75 18.8504 11.27 18.8504 10.36 20.4204L10.25 20.6104C9.78 21.4004 8.76 21.6804 7.97 21.2104L6.24 20.2204C5.33 19.7004 5.02 18.5304 5.54 17.6304C6.45 16.0604 5.71 14.7804 3.9 14.7804C2.85 14.7804 2 13.9204 2 12.8804Z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeMiterlimit="10"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function LogoutIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M10 5H7a4 4 0 0 0 0 14h3M15 8l4 4-4 4M19 12H8" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function SearchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="11" cy="11" r="7" stroke="currentColor" strokeWidth="1.7" />
      <path d="m16.5 16.5 4 4" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function BellIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M18 9.5a6 6 0 1 0-12 0c0 6-2 6.5-2 8h16c0-1.5-2-2-2-8Z" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M10 20a2.3 2.3 0 0 0 4 0" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function CloseIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m6 6 12 12M18 6 6 18" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
    </svg>
  );
}

function ArrowUpRightIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M7 17 17 7M9 7h8v8" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ClockIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.8" />
      <path d="M12 7v5l3 2" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function StretchIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M9 4.5a1.7 1.7 0 1 0 0 3.4 1.7 1.7 0 0 0 0-3.4Z" fill="currentColor" />
      <path d="M9.5 9.5v4.2l-2.4 3.8M10.2 11.4l2.5 2.3 2.5-1.6M8.7 13.5l3.5 5.4" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function PrescriptionIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M7 4h5.2a4.1 4.1 0 0 1 0 8.2H7V4ZM7 12.2V20M11 15.5 17 20M15.5 15.5 11.5 20" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function SmileIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="8" fill="currentColor" opacity="0.9" />
      <path d="M8.5 13.5c1.2 1.4 5.8 1.4 7 0M9.5 10h.01M14.5 10h.01" stroke="white" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function DietIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M7 8.5A4.5 4.5 0 0 1 11.5 4h1A4.5 4.5 0 0 1 17 8.5V18a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V8.5Z" fill="currentColor" />
      <path d="M9.5 10.5h5M10 14h4" stroke="white" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function CalendarSolidIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="4" y="6" width="16" height="14" rx="3" fill="currentColor" />
      <path d="M8 4v4M16 4v4M7.5 11h9" stroke="white" strokeWidth="1.6" strokeLinecap="round" />
      <path d="M8.5 14h.01M12 14h.01M15.5 14h.01" stroke="white" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

function DocumentNormalIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M7 3.5h6.2L18 8.3V19a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5.5a2 2 0 0 1 2-2Z" fill="currentColor" opacity="0.9" />
      <path d="M13 4v4.5h4.5M8.5 13h7M8.5 16h5" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function WeightIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="5" y="7" width="14" height="12" rx="4" fill="currentColor" />
      <path d="M9.5 10.5h5M12 10.5v2" stroke="white" strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

function ContactBookIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <rect x="6" y="4" width="13" height="16" rx="3" fill="currentColor" opacity="0.55" />
      <path d="M4 8h4M4 12h4M4 16h4M12.5 10.2a1.7 1.7 0 1 0 0 3.4 1.7 1.7 0 0 0 0-3.4ZM9.5 17c.7-1.5 1.7-2.2 3-2.2s2.3.7 3 2.2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function LocationPinIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M12 21s7-5.1 7-11a7 7 0 1 0-14 0c0 5.9 7 11 7 11Z" fill="currentColor" opacity="0.65" />
      <circle cx="12" cy="10" r="2.3" fill="white" />
    </svg>
  );
}

function CheckIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m6 12.5 4 4L18 8" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function FilterIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M5 7h8M17 7h2M11 17h8M5 17h2" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      <circle cx="15" cy="7" r="2" stroke="currentColor" strokeWidth="1.7" />
      <circle cx="9" cy="17" r="2" stroke="currentColor" strokeWidth="1.7" />
    </svg>
  );
}

function DocumentDownloadIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M9 11v6l2-2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="m9 17-2-2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M22 10v5c0 5-2 7-7 7H9c-5 0-7-2-7-7V9c0-5 2-7 7-7h5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M22 10h-4c-3 0-4-1-4-4V2l8 8Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function TuneIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M3 7h6M15 7h6M12 7a3 3 0 1 0-6 0 3 3 0 0 0 6 0Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M3 17h6M15 17h6M18 17a3 3 0 1 0-6 0 3 3 0 0 0 6 0Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ChevronDownIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m6 9 6 6 6-6" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ChevronUpIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m6 15 6-6 6 6" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ClipboardTextIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M9 5.5h6M9.6 3h4.8c1 0 1.6.6 1.6 1.6v1.8c0 1-.6 1.6-1.6 1.6H9.6C8.6 8 8 7.4 8 6.4V4.6C8 3.6 8.6 3 9.6 3Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M16 5h1.5C19.4 5 20 6.1 20 7.8V18c0 2.5-1.5 3-3 3H7c-1.5 0-3-.5-3-3V7.8C4 6.1 4.6 5 6.5 5H8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M8 13h8M8 17h5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

function SendIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M21.4 2.6 10.9 13.1M21.4 2.6l-6.7 18.1-3.8-7.6-7.6-3.8L21.4 2.6Z" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function InfoCircleIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="9" fill="white" opacity="0.85" />
      <path d="M12 10.5v5M12 8.2h.01" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function KebabIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="5" r="1.6" fill="currentColor" />
      <circle cx="12" cy="12" r="1.6" fill="currentColor" />
      <circle cx="12" cy="19" r="1.6" fill="currentColor" />
    </svg>
  );
}

function ChevronDownSmallIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 16 16" fill="none" className={className} aria-hidden="true">
      <path d="m4 6 4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ChevronLeftIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m15 6-6 6 6 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function ChevronRightIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="m9 6 6 6-6 6" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function MailIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M17 20.5H7C4 20.5 2 19 2 15.5V8.5C2 5 4 3.5 7 3.5H17C20 3.5 22 5 22 8.5V15.5C22 19 20 20.5 17 20.5Z" stroke="currentColor" strokeWidth="1.5" strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M17 9L13.87 11.5C12.84 12.32 11.15 12.32 10.12 11.5L7 9" stroke="currentColor" strokeWidth="1.5" strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function LockThinIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M6 10V8C6 4.69 7 2 12 2C17 2 18 4.69 18 8V10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M17 22H7C3 22 2 21 2 17V15C2 11 3 10 7 10H17C21 10 22 11 22 15V17C22 21 21 22 17 22Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M15.9965 16H16.0054" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M11.9955 16H12.0045" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M7.9945 16H8.0035" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function EyeSlashIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M14.53 9.47L9.47 14.53C8.82 13.88 8.42 12.99 8.42 12C8.42 10.02 10.02 8.42 12 8.42C12.99 8.42 13.88 8.82 14.53 9.47Z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M17.82 5.77C16.07 4.45 14.07 3.73 12 3.73C8.47 3.73 5.18 5.81 2.89 9.41C1.99 10.82 1.99 13.19 2.89 14.6C3.68 15.84 4.6 16.91 5.6 17.77" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M8.42 19.53C9.56 20.01 10.77 20.27 12 20.27C15.53 20.27 18.82 18.19 21.11 14.59C22.01 13.18 22.01 10.81 21.11 9.4C20.78 8.88 20.42 8.39 20.05 7.93" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M15.51 12.7C15.25 14.11 14.1 15.26 12.69 15.52" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M9.47 14.53L2 22" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M22 2L14.53 9.47" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function MenuIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M3 7h18M3 12h18M3 17h18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function PlusIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function TrashIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M3 6h18M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6M10 11v6M14 11v6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function QuestionIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
      <path d="M9.5 9a2.5 2.5 0 0 1 5 0c0 1.5-1.5 2-2.5 2.5V13" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <circle cx="12" cy="16.5" r="0.75" fill="currentColor" />
    </svg>
  );
}

function AboutUsIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <circle cx="12" cy="8" r="3.5" stroke="currentColor" strokeWidth="1.5" />
      <path d="M5 19c0-3.314 3.134-6 7-6s7 2.686 7 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

function EditPencilSmIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} aria-hidden="true">
      <path d="M15.232 5.232l3.536 3.536M4 20h4l10.5-10.5a2.5 2.5 0 0 0-3.536-3.536L4 16v4z" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
