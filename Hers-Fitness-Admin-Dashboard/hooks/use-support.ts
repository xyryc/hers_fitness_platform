import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { supportApi } from '@/lib/api/support.api';
import type { TicketStatus } from '@/lib/types/support.types';

export const SUPPORT_KEYS = {
  tickets: (status?: TicketStatus) =>
    status != null
      ? (['admin', 'help-tickets', status] as const)
      : (['admin', 'help-tickets'] as const),
  ticket: (id: string) => ['admin', 'help-ticket', id] as const,
};

export function useHelpTickets(status?: TicketStatus) {
  return useQuery({
    queryKey: SUPPORT_KEYS.tickets(status),
    queryFn:  () => supportApi.getTickets(status),
    staleTime: 30_000,
  });
}

export function useHelpTicket(id: string, enabled = true) {
  return useQuery({
    queryKey: SUPPORT_KEYS.ticket(id),
    queryFn:  () => supportApi.getTicket(id),
    enabled,
    staleTime: 30_000,
  });
}

export function useMarkTicketInReview() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => supportApi.markInReview(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'help-tickets'] });
    },
  });
}

export function useResolveTicket() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      payload,
    }: {
      id: string;
      payload: { status: 'RESOLVED' | 'CLOSED'; adminNote?: string };
    }) => supportApi.resolve(id, payload),
    onSuccess: (_data, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'help-tickets'] });
      queryClient.invalidateQueries({ queryKey: SUPPORT_KEYS.ticket(id) });
    },
  });
}
