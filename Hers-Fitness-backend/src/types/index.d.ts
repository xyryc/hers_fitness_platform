import { BrowserClientDetails } from './browser-client';
import { Request } from 'express';

declare module 'express' {
  export interface Request {
    clientId?: string;
    clientDetails: BrowserClientDetails;
  }
}
