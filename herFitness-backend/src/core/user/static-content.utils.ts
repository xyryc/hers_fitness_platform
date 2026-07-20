export const STATIC_CONTENT_KEYS = ['privacy-policy', 'terms-of-service', 'about-us'] as const;
export type StaticContentKey = (typeof STATIC_CONTENT_KEYS)[number];

const LEGACY_KEY_MAP: Record<string, StaticContentKey> = {
    privacy_policy: 'privacy-policy',
    terms_of_service: 'terms-of-service',
    about_us: 'about-us',
};

export function normalizeStaticContentKey(key: string): StaticContentKey | null {
    const normalized = key.trim().toLowerCase();

    if ((STATIC_CONTENT_KEYS as readonly string[]).includes(normalized)) {
        return normalized as StaticContentKey;
    }

    return LEGACY_KEY_MAP[normalized] ?? null;
}

export function getStaticContentLookupKeys(key: string): string[] {
    const canonical = normalizeStaticContentKey(key);
    if (!canonical) return [key];

    return [canonical, canonical.replace(/-/g, '_')];
}
