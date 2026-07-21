export interface BrowserClientDetails {
  ip: string;
  userAgent?: string;
  referer?: string;
  origin?: string;
  host?: string;
  acceptLanguage?: string;
  acceptEncoding?: string;
  connection?: string;
  timestamp: string;
  method: string;
  url: string;
  protocol?: string;
  secure?: boolean;
  xForwardedFor?: string;
  xRealIp?: string;
  cfRay?: string;
  cfIpCountry?: string;
  geolocation?: GeoLocation | null;
  userAgentParsed?: UserAgentInfo | null;
}

export interface GeoLocation {
  country?: string;
  countryCode?: string;
  region?: string;
  city?: string;
  latitude?: number;
  longitude?: number;
  timezone?: string;
  isp?: string;
}

export interface UserAgentInfo {
  browserName: string;
  browserVersion: string;
  osName: string;
  osVersion: string;
  deviceType: string;
  language?: string | null;
}
