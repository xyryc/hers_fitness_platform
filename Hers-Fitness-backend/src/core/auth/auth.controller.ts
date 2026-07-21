import { Body, Controller, HttpCode, Post, Req, Res, UploadedFiles, UseGuards, UseInterceptors } from "@nestjs/common";
import { AuthService } from "./auth.service";
import { LoginDto } from "./dto/login.dto";
import { ClientInfo, type ClientInfoDetails } from "src/common/decorators/client-info.decorator";
import CustomResponse from "src/common/dto/custom-response.dto";
import type { Response } from 'express';
import { AuthGuard } from "./guards/auth.guard";
import { LoginResponseDto } from "./dto/login.response.dto";
import { UserResponseDto } from "../user/dto/user-response.dto";
import { RegisterMemberDto } from "./dto/register-member.dto";
import { FileFieldsInterceptor } from "@nestjs/platform-express";
import { RegisterTrainerDto } from "./dto/register-trainer.dto";
import { ForgotPasswordDto } from "./dto/forgot-password.dto";
import { ResetPasswordDto } from "./dto/reset-password.dto";
import { ApiBody, ApiConsumes, ApiOperation, ApiTags } from "@nestjs/swagger";
import { VerifyPasswordResetOtpDto } from "./dto/verify-password-reset-otp.dto";

const memberRegisterBodySchema = {
    schema: {
        type: 'object',
        required: [
            'name',
            'email',
            'phoneNumber',
            'state',
            'location',
            'idCardType',
            'idCardNumber',
            'password',
            'confirmPassword',
            'image',
            'idCardFrontImage',
            'idCardBackImage',
        ],
        properties: {
            name: { type: 'string', example: 'Heba Rahman' },
            email: { type: 'string', format: 'email', example: 'heba@example.com' },
            phoneNumber: { type: 'string', example: '+8801712345678' },
            state: { type: 'string', example: 'Dhaka' },
            location: { type: 'string', example: 'Gulshan, Dhaka' },
            timezone: { type: 'string', example: 'Asia/Dhaka' },
            idCardType: { type: 'string', example: 'NID' },
            idCardNumber: { type: 'string', example: '1234567890' },
            password: { type: 'string', example: 'Password@123' },
            confirmPassword: { type: 'string', example: 'Password@123' },
            image: { type: 'string', format: 'binary' },
            idCardFrontImage: { type: 'string', format: 'binary' },
            idCardBackImage: { type: 'string', format: 'binary' },
        },
    },
};

const trainerRegisterBodySchema = {
    schema: {
        type: 'object',
        required: [
            'name',
            'email',
            'phoneNumber',
            'state',
            'location',
            'idCardType',
            'idCardNumber',
            'bio',
            'classesTaught',
            'instructorExperience',
            'certifications',
            'classDeliveryMode',
            'password',
            'confirmPassword',
            'image',
            'idCardFrontImage',
            'idCardBackImage',
        ],
        properties: {
            name: { type: 'string', example: 'Heba Trainer' },
            email: { type: 'string', format: 'email', example: 'trainer@example.com' },
            phoneNumber: { type: 'string', example: '+8801712345678' },
            state: { type: 'string', example: 'Dhaka' },
            location: { type: 'string', example: 'Banani, Dhaka' },
            timezone: { type: 'string', example: 'Asia/Dhaka' },
            idCardType: { type: 'string', example: 'NID' },
            idCardNumber: { type: 'string', example: '1234567890' },
            bio: { type: 'string', example: 'Certified strength and mobility coach.' },
            classesTaught: { type: 'string', example: 'Strength training, yoga, HIIT' },
            instructorExperience: { type: 'string', example: '5 years' },
            certifications: { type: 'string', example: 'ACE CPT, CPR certified' },
            classDeliveryMode: {
                type: 'string',
                enum: ['ONLINE', 'OFFLINE', 'BOTH'],
                example: 'BOTH',
            },
            password: { type: 'string', example: 'Password@123' },
            confirmPassword: { type: 'string', example: 'Password@123' },
            image: { type: 'string', format: 'binary' },
            idCardFrontImage: { type: 'string', format: 'binary' },
            idCardBackImage: { type: 'string', format: 'binary' },
        },
    },
};

@ApiTags('0. Auth & Onboarding')
@Controller('auth')
export class AuthController {

    constructor(private readonly authService: AuthService) { }

    @Post('/login')
    @ApiOperation({ summary: 'Login with email/username and password' })
    async login(@Body() model: LoginDto, @ClientInfo() clientInfo: ClientInfoDetails, @Res({ passthrough: true }) res: Response) {
        const response = await this.authService.authenticate(model, clientInfo.ip, clientInfo.userAgent);
        res.status(200);
        return new CustomResponse<LoginResponseDto>('Login successful', response, 200);
    }

    @Post('/refresh-token')
    @ApiOperation({ summary: 'Refresh access token' })
    @ApiBody({
        schema: {
            type: 'object',
            required: ['refreshToken'],
            properties: {
                refreshToken: { type: 'string' },
            },
        },
    })
    async refreshToken(@Body('refreshToken') refreshToken: string, @ClientInfo() clientInfo: ClientInfoDetails) {
        const response = await this.authService.refreshToken(refreshToken, clientInfo.ip, clientInfo.userAgent);
        return new CustomResponse('Token refreshed successfully', response, 200);
    }

    @Post('/register')
    @HttpCode(201)
    @ApiOperation({ summary: 'Register a member account' })
    @ApiConsumes('multipart/form-data')
    @ApiBody(memberRegisterBodySchema)
    @UseInterceptors(
        FileFieldsInterceptor([
            { name: 'image', maxCount: 1 },
            { name: 'idCardFrontImage', maxCount: 1 },
            { name: 'idCardBackImage', maxCount: 1 },
        ]),
    )
    async register(
        @Body() model: RegisterMemberDto,
        @UploadedFiles()
        files: {
            image?: Express.Multer.File[];
            idCardFrontImage?: Express.Multer.File[];
            idCardBackImage?: Express.Multer.File[];
        },
    ) {
        await this.authService.registerMember(model, files);
        return new CustomResponse<null>('Registration successful. Please check your email for a 6-digit verification code to verify your account.', null, 201);
    }

    @Post('/register/trainer')
    @HttpCode(201)
    @ApiOperation({ summary: 'Register a trainer account' })
    @ApiConsumes('multipart/form-data')
    @ApiBody(trainerRegisterBodySchema)
    @UseInterceptors(
        FileFieldsInterceptor([
            { name: 'image', maxCount: 1 },
            { name: 'idCardFrontImage', maxCount: 1 },
            { name: 'idCardBackImage', maxCount: 1 },
        ]),
    )
    async registerTrainer(
        @Body() model: RegisterTrainerDto,
        @UploadedFiles()
        files: {
            image?: Express.Multer.File[];
            idCardFrontImage?: Express.Multer.File[];
            idCardBackImage?: Express.Multer.File[];
        },
    ) {
        await this.authService.registerTrainer(model, files);
        return new CustomResponse<null>('Trainer registration successful. Please check your email for a 6-digit verification code to verify your account.', null, 201);
    }

    @Post('/verify-email')
    @ApiOperation({ summary: 'Verify email with the registration code' })
    @ApiBody({
        schema: {
            type: 'object',
            required: ['email', 'code'],
            properties: {
                email: { type: 'string', format: 'email', example: 'heba@example.com' },
                code: { type: 'string', example: '123456' },
            },
        },
    })
    async verifyEmail(@Body('email') email: string, @Body('code') code: string) {
        await this.authService.verifyEmail(email, code);
        return new CustomResponse('Email verified successfully');
    }

    @Post('/resend-verification')
    @ApiOperation({ summary: 'Resend email verification code' })
    @ApiBody({
        schema: {
            type: 'object',
            required: ['email'],
            properties: {
                email: { type: 'string', format: 'email', example: 'heba@example.com' },
            },
        },
    })
    async resendVerification(@Body('email') email: string) {
        await this.authService.resendVerificationCode(email);
        return new CustomResponse('Verification code sent successfully');
    }

    @Post('/forgot-password')
    @ApiOperation({ summary: 'Request a 6 digit password reset OTP by email' })
    async forgotPassword(@Body() model: ForgotPasswordDto) {
        await this.authService.forgotPassword(model);
        return new CustomResponse('If an eligible account exists for this email, a 6 digit password reset OTP has been sent.');
    }

    @Post('/verify-password-reset-otp')
    @ApiOperation({ summary: 'Verify password reset OTP and return a temporary reset key' })
    async verifyPasswordResetOtp(@Body() model: VerifyPasswordResetOtpDto) {
        const response = await this.authService.verifyPasswordResetOtp(model);
        return new CustomResponse('Password reset OTP verified successfully', response);
    }

    @Post('/reset-password')
    @ApiOperation({ summary: 'Reset password with reset key, new password, and confirm password' })
    async resetPassword(@Body() model: ResetPasswordDto) {
        await this.authService.resetPassword(model);
        return new CustomResponse('Password reset successfully');
    }

    @UseGuards(AuthGuard)
    @Post('/logout')
    @HttpCode(200)
    @ApiOperation({ summary: 'Logout current session' })
    async logout(@Req() req, @Res({ passthrough: true }) res: Response) {
        await this.authService.logout(req.user.currentUserId, req.user.sessionId);
        return new CustomResponse('User logged out successfully');
    }
}
