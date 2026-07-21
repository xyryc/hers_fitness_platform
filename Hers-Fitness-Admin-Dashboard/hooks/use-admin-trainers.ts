import { useQuery } from "@tanstack/react-query";

import { fetchAdminTrainer, fetchAdminTrainers } from "@/lib/trainers-api";

export function useAdminTrainers() {
  return useQuery({
    queryKey: ["users", { role: "trainer" }],
    queryFn: fetchAdminTrainers,
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
    refetchOnReconnect: true,
  });
}

export function useAdminTrainer(userId: string | null) {
  return useQuery({
    queryKey: ["users", { role: "trainer" }, userId],
    queryFn: () => fetchAdminTrainer(userId as string),
    enabled: Boolean(userId),
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
    refetchOnReconnect: true,
  });
}
