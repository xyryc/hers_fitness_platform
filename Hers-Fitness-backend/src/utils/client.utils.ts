import { Request } from 'express';
import { UserAgentInfo } from '../types/browser-client';
import { UAParser } from 'ua-parser-js';

export const getClientIP = (req: Request): string | null => {
  const forwarded = req.headers['x-forwarded-for'] as string;
  const real = req.headers['x-real-ip'] as string;
  const cfConnecting = req.headers['cf-connecting-ip'] as string;

  if (forwarded) {
    return forwarded.split(',')[0].trim();
  }
  if (real) {
    return real;
  }
  if (cfConnecting) {
    return cfConnecting;
  }

  return req.ip || req.socket?.remoteAddress || null;
};

export function parseUserAgent(req: Request): UserAgentInfo {
  const userAgent = req.headers['user-agent'] || '';
  const parser = new UAParser(userAgent);
  const result = parser.getResult();

  const browserName = result.browser.name || 'Unknown';
  const browserVersion = result.browser.version || 'Unknown';
  const osName = result.os.name || 'Unknown';
  const osVersion = result.os.version || 'Unknown';
  const deviceType = result.device.type || 'desktop'; // Default to 'desktop' if device type is not available

  // Language can be extracted from headers or `navigator.language` on the client side.
  const language = req.headers['accept-language']?.split(',')[0] || null;

  return {
    browserName,
    browserVersion,
    osName,
    osVersion,
    deviceType,
    language,
  };
}
