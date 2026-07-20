import { Injectable, Logger } from '@nestjs/common';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { AppConfig } from 'src/config/app.config';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class FirebasePushService {
    private readonly logger = new Logger(FirebasePushService.name);
    private readonly enabled: boolean;

    constructor(private readonly appConfig: AppConfig) {
        this.enabled = this.initializeFirebase();
    }

    async sendToTokens(
        tokens: string[],
        title: string,
        body: string,
        data?: Record<string, string>,
    ): Promise<{ invalidTokens: string[] }> {
        if (!this.enabled || tokens.length === 0) {
            return { invalidTokens: [] };
        }

        const invalidTokens: string[] = [];
        const batches = this.chunk(tokens, 500);

        for (const batch of batches) {
            const response = await getMessaging().sendEachForMulticast({
                tokens: batch,
                notification: {
                    title,
                    body,
                },
                data,
            });

            response.responses.forEach((result, index) => {
                if (!result.success && this.isInvalidTokenError(result.error?.code)) {
                    invalidTokens.push(batch[index]);
                }
            });
        }

        return { invalidTokens };
    }

    private initializeFirebase(): boolean {
        if (getApps().length > 0) {
            return true;
        }

        const firebase = this.appConfig.firebase;
        const serviceAccount = this.getServiceAccount(firebase);
        if (!serviceAccount) {
            this.logger.warn('Firebase push is disabled because service account configuration is missing.');
            return false;
        }

        initializeApp({
            credential: cert(serviceAccount),
        });

        return true;
    }

    private getServiceAccount(firebase: {
        projectId: string;
        clientEmail: string;
        privateKey: string;
        serviceAccountPath: string;
        serviceAccountJson: string;
    }): Record<string, string> | null {
        if (firebase.serviceAccountJson) {
            return JSON.parse(firebase.serviceAccountJson);
        }

        if (firebase.serviceAccountPath) {
            const filePath = path.isAbsolute(firebase.serviceAccountPath)
                ? firebase.serviceAccountPath
                : path.resolve(process.cwd(), firebase.serviceAccountPath);

            return JSON.parse(fs.readFileSync(filePath, 'utf8'));
        }

        if (!firebase.projectId || !firebase.clientEmail || !firebase.privateKey) {
            return null;
        }

        return {
            projectId: firebase.projectId,
            clientEmail: firebase.clientEmail,
            privateKey: firebase.privateKey.replace(/\\n/g, '\n'),
        };
    }

    private isInvalidTokenError(code?: string): boolean {
        return code === 'messaging/registration-token-not-registered'
            || code === 'messaging/invalid-registration-token'
            || code === 'messaging/invalid-argument';
    }

    private chunk<T>(items: T[], size: number): T[][] {
        const chunks: T[][] = [];
        for (let index = 0; index < items.length; index += size) {
            chunks.push(items.slice(index, index + size));
        }

        return chunks;
    }
}
