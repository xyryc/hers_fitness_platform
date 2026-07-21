import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { contentApi } from '@/lib/api/content.api';
import type { StaticContentKey } from '@/lib/types/content.types';

export const CONTENT_KEYS = {
  allStatic:   ['admin', 'static-content']                       as const,
  static:      (key: StaticContentKey) =>
                 ['admin', 'static-content', key]                as const,
  faqs:        ['admin', 'faqs']                                 as const,
};

// ── Static content ──────────────────────────────────────────────────────────

export function useAllStaticContent() {
  return useQuery({
    queryKey: CONTENT_KEYS.allStatic,
    queryFn:  contentApi.getAllStaticContent,
    staleTime: 120_000,
  });
}

export function useStaticContent(key: StaticContentKey) {
  return useQuery({
    queryKey: CONTENT_KEYS.static(key),
    queryFn:  () => contentApi.getStaticContent(key),
    staleTime: 120_000,
  });
}

export function useSaveStaticContent() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      key,
      payload,
    }: {
      key: StaticContentKey;
      payload: { title: string; content: string };
    }) => contentApi.saveStaticContent(key, payload),
    onSuccess: (_data, { key }) => {
      queryClient.invalidateQueries({ queryKey: CONTENT_KEYS.static(key) });
      queryClient.invalidateQueries({ queryKey: CONTENT_KEYS.allStatic });
    },
  });
}

// ── FAQs ─────────────────────────────────────────────────────────────────────

export function useFaqs() {
  return useQuery({
    queryKey: CONTENT_KEYS.faqs,
    queryFn:  contentApi.getFaqs,
    staleTime: 60_000,
  });
}

export function useCreateFaq() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: contentApi.createFaq,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CONTENT_KEYS.faqs });
    },
  });
}

export function useUpdateFaq() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      payload,
    }: {
      id: string;
      payload: Partial<{ question: string; answer: string; order: number; isActive: boolean }>;
    }) => contentApi.updateFaq(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CONTENT_KEYS.faqs });
    },
  });
}

export function useDeleteFaq() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => contentApi.deleteFaq(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CONTENT_KEYS.faqs });
    },
  });
}

export function useReorderFaqs() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (items: Array<{ id: string; order: number }>) =>
      contentApi.reorderFaqs(items),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CONTENT_KEYS.faqs });
    },
  });
}
