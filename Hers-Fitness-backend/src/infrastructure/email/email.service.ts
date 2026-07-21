import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { AppConfig } from 'src/config/app.config';

@Injectable()
export class EmailService {
    private transporter: nodemailer.Transporter;

    constructor(private readonly config: AppConfig) {
        this.transporter = nodemailer.createTransport({
            host: this.config.smtp.host,
            port: this.config.smtp.port,
            secure: this.config.smtp.port === 465, // true for 465, false for other ports
            auth: {
                user: this.config.smtp.username,
                pass: this.config.smtp.password,
            },
        });
    }

    async sendEmail(to: string, subject: string, html: string): Promise<void> {
        const mailOptions = {
            from: `"${this.config.email.fromName}" <${this.config.email.fromEmail}>`,
            to,
            subject,
            html,
        };

        try {
            await this.transporter.sendMail(mailOptions);
        } catch (error) {
            console.error('Failed to send email:', error);
            // We don't throw here to avoid breaking the registration flow if email fails, 
            // but in a production app, you might want more robust error handling.
        }
    }

    async sendVerificationCode(to: string, code: string): Promise<void> {
        const subject = 'Your Verification Code';
        const html = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <h2 style="color: #333; text-align: center;">Welcome to ${this.config.app.name}!</h2>
                <p style="font-size: 16px; color: #555;">Thank you for registering. Please use the following code to verify your email address:</p>
                <div style="background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #000; margin: 20px 0; border-radius: 5px;">
                    ${code}
                </div>
                <p style="font-size: 14px; color: #888; text-align: center;">This code will expire in 15 minutes.</p>
                <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
                <p style="font-size: 12px; color: #aaa; text-align: center;">If you didn't request this email, please ignore it.</p>
            </div>
        `;
        await this.sendEmail(to, subject, html);
    }

    async sendPasswordResetCode(to: string, code: string): Promise<void> {
        const subject = 'Your Password Reset Code';
        const html = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                <h2 style="color: #333; text-align: center;">Reset your password</h2>
                <p style="font-size: 16px; color: #555;">Use the following 6-digit code to reset your password:</p>
                <div style="background-color: #f4f4f4; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #000; margin: 20px 0; border-radius: 5px;">
                    ${code}
                </div>
                <p style="font-size: 14px; color: #888; text-align: center;">This code will expire in 15 minutes.</p>
                <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
                <p style="font-size: 12px; color: #aaa; text-align: center;">If you didn't request this email, please ignore it.</p>
            </div>
        `;
        await this.sendEmail(to, subject, html);
    }
}
