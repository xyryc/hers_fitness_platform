import { Injectable } from '@nestjs/common';
import Stripe from 'stripe';
import { AppConfig } from 'src/config/app.config';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { PrismaService } from 'src/database/prisma.service';

@Injectable()
export class StripePaymentService {
    private readonly stripe: Stripe.Stripe | null;

    constructor(
        private readonly appConfig: AppConfig,
        private readonly prisma: PrismaService,
    ) {
        const secretKey = this.appConfig.stripe.secretKey;
        this.stripe = secretKey
            ? new Stripe(secretKey)
            : null;
    }

    get publishableKey(): string {
        return this.appConfig.stripe.publishableKey;
    }

    async createPaymentIntent(params: {
        amount: number;
        currency: string;
        paymentIntentId?: string | null;
        destinationAccountId?: string | null;
        applicationFeeAmount?: number | null;
        metadata: Record<string, string>;
    }): Promise<any> {
        const stripe = this.ensureStripe();

        if (params.paymentIntentId) {
            const existingIntent = await stripe.paymentIntents.retrieve(params.paymentIntentId);
            const existingDestination = (existingIntent as any).transfer_data?.destination ?? null;
            const destinationMatches = !params.destinationAccountId || existingDestination === params.destinationAccountId;
            if (
                destinationMatches
                && (existingIntent.status === 'requires_payment_method' || existingIntent.status === 'requires_confirmation')
            ) {
                return stripe.paymentIntents.update(params.paymentIntentId, {
                    amount: params.amount,
                    currency: params.currency.toLowerCase(),
                    ...(params.destinationAccountId && params.applicationFeeAmount
                        ? { application_fee_amount: params.applicationFeeAmount }
                        : {}),
                    metadata: params.metadata,
                } as any);
            }

            if (destinationMatches) return existingIntent;
        }

        return stripe.paymentIntents.create({
            amount: params.amount,
            currency: params.currency.toLowerCase(),
            automatic_payment_methods: {
                enabled: true,
            },
            ...(params.destinationAccountId
                ? {
                    transfer_data: {
                        destination: params.destinationAccountId,
                    },
                }
                : {}),
            ...(params.destinationAccountId && params.applicationFeeAmount
                ? { application_fee_amount: params.applicationFeeAmount }
                : {}),
            metadata: params.metadata,
        } as any);
    }

    async retrievePaymentIntent(paymentIntentId: string): Promise<any> {
        return this.ensureStripe().paymentIntents.retrieve(paymentIntentId);
    }

    async createRefund(params: {
        paymentIntentId: string;
        amountCents?: number;
        reason?: string;
        reverseTransfer?: boolean;
        refundApplicationFee?: boolean;
    }): Promise<any> {
        const stripe = this.ensureStripe();
        return stripe.refunds.create({
            payment_intent: params.paymentIntentId,
            ...(params.amountCents !== undefined ? { amount: params.amountCents } : {}),
            ...(params.reverseTransfer !== undefined ? { reverse_transfer: params.reverseTransfer } : {}),
            ...(params.refundApplicationFee !== undefined ? { refund_application_fee: params.refundApplicationFee } : {}),
            reason: (params.reason as any) ?? 'requested_by_customer',
        } as any);
    }

    constructWebhookEvent(rawBody: Buffer | string, signature: string | string[] | undefined): any {
        const webhookSecret = this.appConfig.stripe.webhookSecret;
        if (!webhookSecret) {
            throw new BadRequestAppException('Stripe webhook secret is not configured on the server.', ['STRIPE_WEBHOOK_NOT_CONFIGURED']);
        }
        if (!signature) {
            throw new BadRequestAppException('Stripe webhook signature is missing.', ['STRIPE_SIGNATURE_MISSING']);
        }

        return this.ensureStripe().webhooks.constructEvent(rawBody, signature, webhookSecret);
    }

    async createTrainerOnboardingLink(params: {
        trainerUserId: string;
        returnUrl?: string;
        refreshUrl?: string;
    }): Promise<{ url: string; expiresAt: Date; status: any }> {
        const stripe = this.ensureStripe();
        const user = await (this.prisma as any).user.findUnique({
            where: { id: params.trainerUserId },
            include: { trainerProfile: true },
        });

        if (!user?.trainerProfile) {
            throw new NotFoundAppException('Trainer profile not found.', 'TRAINER_PROFILE_NOT_FOUND');
        }

        const accountId = user.trainerProfile.stripeConnectAccountId
            ?? (await stripe.accounts.create({
                type: 'express',
                email: user.email ?? undefined,
                capabilities: {
                    card_payments: { requested: true },
                    transfers: { requested: true },
                },
                metadata: {
                    trainerUserId: params.trainerUserId,
                },
            } as any)).id;

        if (!user.trainerProfile.stripeConnectAccountId) {
            await (this.prisma as any).trainerProfile.update({
                where: { userId: params.trainerUserId },
                data: { stripeConnectAccountId: accountId },
            });
        }

        const status = await this.syncTrainerConnectAccount(accountId);
        const baseUrl = this.appConfig.app.url.replace(/\/$/, '');
        const accountLink = await stripe.accountLinks.create({
            account: accountId,
            refresh_url: params.refreshUrl ?? `${baseUrl}/trainer/payout/refresh`,
            return_url: params.returnUrl ?? `${baseUrl}/trainer/payout/return`,
            type: 'account_onboarding',
        });

        return {
            url: accountLink.url,
            expiresAt: new Date(accountLink.expires_at * 1000),
            status,
        };
    }

    async getTrainerPayoutStatus(trainerUserId: string, sync = false): Promise<any> {
        const profile = await (this.prisma as any).trainerProfile.findUnique({
            where: { userId: trainerUserId },
        });

        if (!profile) {
            throw new NotFoundAppException('Trainer profile not found.', 'TRAINER_PROFILE_NOT_FOUND');
        }

        if (sync && profile.stripeConnectAccountId) {
            return this.syncTrainerConnectAccount(profile.stripeConnectAccountId);
        }

        return this.mapTrainerPayoutStatus(profile);
    }

    async syncTrainerConnectAccount(accountId: string): Promise<any> {
        const account = await this.ensureStripe().accounts.retrieve(accountId);
        return this.updateTrainerConnectAccountStatus(account);
    }

    async updateTrainerConnectAccountStatus(account: any): Promise<any> {
        const trainerUserId = account.metadata?.trainerUserId;
        const where = trainerUserId
            ? { userId: trainerUserId }
            : { stripeConnectAccountId: account.id };

        const updated = await (this.prisma as any).trainerProfile.update({
            where,
            data: {
                stripeConnectAccountId: account.id,
                stripeConnectOnboardingComplete: Boolean(account.details_submitted && account.charges_enabled && account.payouts_enabled),
                stripeChargesEnabled: Boolean(account.charges_enabled),
                stripePayoutsEnabled: Boolean(account.payouts_enabled),
                stripeDetailsSubmitted: Boolean(account.details_submitted),
                stripeConnectUpdatedAt: new Date(),
            },
        });

        return this.mapTrainerPayoutStatus(updated);
    }

    mapTrainerPayoutStatus(profile: any): any {
        const payoutReady = Boolean(
            profile?.stripeConnectAccountId
            && profile?.stripeConnectOnboardingComplete
            && profile?.stripeChargesEnabled
            && profile?.stripePayoutsEnabled,
        );

        return {
            stripeConnectAccountId: profile?.stripeConnectAccountId ?? null,
            onboardingComplete: Boolean(profile?.stripeConnectOnboardingComplete),
            chargesEnabled: Boolean(profile?.stripeChargesEnabled),
            payoutsEnabled: Boolean(profile?.stripePayoutsEnabled),
            detailsSubmitted: Boolean(profile?.stripeDetailsSubmitted),
            payoutReady,
            updatedAt: profile?.stripeConnectUpdatedAt ?? null,
        };
    }

    private ensureStripe(): Stripe.Stripe {
        if (!this.stripe) {
            throw new BadRequestAppException('Stripe is not configured on the server.', ['STRIPE_NOT_CONFIGURED']);
        }

        return this.stripe;
    }
}
