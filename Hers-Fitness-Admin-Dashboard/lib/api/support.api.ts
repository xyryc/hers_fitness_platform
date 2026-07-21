import { adminApiFetch } from '@/lib/auth-api';
import type { HelpTicket, TicketStatus } from '@/lib/types/support.types';

const BASE = '/api';

type HelpTicketResponse = Omit<HelpTicket, 'subject' | 'message'> & {
  subject?: string | null;
  message?: string | null;
  title?: string | null;
  body?: string | null;
};

function normalizeTicket(ticket: HelpTicketResponse): HelpTicket {
  return {
    ...ticket,
    subject: ticket.subject ?? ticket.title ?? 'Untitled support ticket',
    message: ticket.message ?? ticket.body ?? '',
  };
}

export const supportApi = {
  getTickets: (status?: TicketStatus) => {
    const url =
      status != null
        ? `${BASE}/help-tickets?status=${status}`
        : `${BASE}/help-tickets`;
    return adminApiFetch<{ data: HelpTicketResponse[] }>(url).then((r) =>
      r.data.map(normalizeTicket),
    );
  },

  getTicket: (id: string) =>
    adminApiFetch<{ data: HelpTicketResponse }>(`${BASE}/help-tickets/${id}`).then(
      (r) => normalizeTicket(r.data),
    ),

  markInReview: (id: string) =>
    adminApiFetch<{ data: HelpTicketResponse }>(
      `${BASE}/help-tickets/${id}/review`,
      { method: 'PATCH' },
    ).then((r) => normalizeTicket(r.data)),

  resolve: (
    id: string,
    payload: { status: 'RESOLVED' | 'CLOSED'; adminNote?: string },
  ) =>
    adminApiFetch<{ data: HelpTicketResponse }>(
      `${BASE}/help-tickets/${id}/resolve`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      },
    ).then((r) => normalizeTicket(r.data)),
};
