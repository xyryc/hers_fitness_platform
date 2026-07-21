import { adminApiFetch } from '@/lib/auth-api';
import type {
  FaqItem,
  StaticContentItem,
  StaticContentKey,
} from '@/lib/types/content.types';

const BASE = '/api/admin';

export const contentApi = {
  // ── Static content ──────────────────────────────────────────────────────

  getAllStaticContent: () =>
    adminApiFetch<{ data: StaticContentItem[] }>(`${BASE}/static-content`).then(
      (r) => r.data,
    ),

  getStaticContent: (key: StaticContentKey) =>
    adminApiFetch<{ data: StaticContentItem }>(
      `${BASE}/static-content/${key}`,
    ).then((r) => r.data),

  saveStaticContent: (
    key: StaticContentKey,
    payload: { title: string; content: string },
  ) =>
    adminApiFetch<{ data: StaticContentItem }>(
      `${BASE}/static-content/${key}`,
      {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      },
    ).then((r) => r.data),

  // ── FAQs ─────────────────────────────────────────────────────────────────

  getFaqs: () =>
    adminApiFetch<{ data: FaqItem[] }>(`${BASE}/faqs`).then((r) => r.data),

  createFaq: (payload: {
    question: string;
    answer: string;
    order?: number;
    isActive?: boolean;
  }) =>
    adminApiFetch<{ data: FaqItem }>(`${BASE}/faqs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }).then((r) => r.data),

  updateFaq: (
    id: string,
    payload: Partial<{
      question: string;
      answer: string;
      order: number;
      isActive: boolean;
    }>,
  ) =>
    adminApiFetch<{ data: FaqItem }>(`${BASE}/faqs/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }).then((r) => r.data),

  deleteFaq: (id: string) =>
    adminApiFetch<{ data: null }>(`${BASE}/faqs/${id}`, {
      method: 'DELETE',
    }),

  reorderFaqs: (items: Array<{ id: string; order: number }>) =>
    adminApiFetch<{ data: null }>(`${BASE}/faqs/reorder`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items }),
    }),
};
