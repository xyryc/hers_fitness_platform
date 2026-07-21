import { useQuery } from "@tanstack/react-query";

import { fetchAdminMember, fetchAdminMembers } from "@/lib/members-api";

export function useAdminMembers() {
  return useQuery({
    queryKey: ["users", { role: "member" }],
    queryFn: fetchAdminMembers,
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
    refetchOnReconnect: true,
  });
}

export function useAdminMember(userId: string | null) {
  return useQuery({
    queryKey: ["users", { role: "member" }, userId],
    queryFn: () => fetchAdminMember(userId as string),
    enabled: Boolean(userId),
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
    refetchOnReconnect: true,
  });
}
