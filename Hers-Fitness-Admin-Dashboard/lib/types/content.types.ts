export type StaticContentKey = 'privacy-policy' | 'terms-of-service' | 'about-us';

export interface StaticContentItem {
  key:       string;
  title:     string;
  content:   string;
  createdAt: string;
  updatedAt: string;
}

export interface FaqItem {
  id:       string;
  question: string;
  answer:   string;
  order:    number;
  isActive: boolean;
}
