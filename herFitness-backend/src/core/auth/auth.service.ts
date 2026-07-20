import { Injectable } from "@nestjs/common";
import { UserService } from "../user/user.service";
import { LoginDto } from "./dto/login.dto";
import { UnauthorizedAppException } from "src/common/exceptions/unauthorized-error";
import { UserEntity } from "../user/domain/entities/user.entity";
import { JwtService } from "@nestjs/jwt";
import { UserResponseDto } from "../user/dto/user-response.dto";
import { LoginResponseDto } from "./dto/login.response.dto";
import { RegisterMemberDto } from "./dto/register-member.dto";
import { RegisterTrainerDto } from "./dto/register-trainer.dto";
import { AppConfig } from "src/config/app.config";
import { ForgotPasswordDto } from "./dto/forgot-password.dto";
import { ResetPasswordDto } from "./dto/reset-password.dto";
import { VerifyPasswordResetOtpDto } from "./dto/verify-password-reset-otp.dto";
import { NotificationService } from "../notification/notification.service";

@Injectable()
export class AuthService {
    constructor(
        private readonly userService: UserService,
        private readonly jwtService: JwtService,
        private readonly config: AppConfig,
        private readonly notificationService: NotificationService,
    ) { }

    /**
     * Authenticate user and return access and refresh tokens
     * @param model 
     * @param ip 
     * @param userAgent 
     * @returns returns user and tokens on success or throws exception on failure
     */
    async authenticate(model: LoginDto, ip: string, userAgent: string): Promise<LoginResponseDto> {

        const user = await this.validateUser(model);

        if (!user) {
            throw new UnauthorizedAppException('Invalid username or password', 'INVALID_USERNAME_OR_PASSWORD');
        }

        if (!user.isEmailVerified) {
            throw new UnauthorizedAppException('Please verify your email address before logging in.', 'EMAIL_NOT_VERIFIED');
        }

        const refreshToken = await this.generateRefreshToken(user);

        const session = await this.userService.saveUserSession(
            user.id,
            refreshToken,
            ip,
            userAgent,
            new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
        );

        const accessToken = await this.generateAccessToken(user, session.id);

        await this.registerLoginDeviceToken(user.id, model);

        return new LoginResponseDto({
            user: new UserResponseDto(user),
            accessToken: accessToken,
            refreshToken: refreshToken,
        });
    }

    /**
     * Refresh access token using refresh token
     * @param refreshToken 
     * @param ip 
     * @param userAgent 
     * @returns 
     */
    async refreshToken(refreshToken: string, ip: string, userAgent: string): Promise<Partial<LoginResponseDto>> {
        try {
            const payload = await this.jwtService.verifyAsync(refreshToken, {
                secret: this.config.jwt.refreshSecret,
            });

            const user = await this.userService.findById(payload.id);
            if (!user || !user.isActive) {
                throw new UnauthorizedAppException('User is not active or not found', 'USER_NOT_FOUND');
            }

            const session = await this.userService.getUserSessionByToken(user.id, refreshToken);
            if (!session) {
                throw new UnauthorizedAppException('Invalid or expired refresh token', 'INVALID_REFRESH_TOKEN');
            }

            const newAccessToken = await this.generateAccessToken(user as any, session.id);

            return {
                accessToken: newAccessToken,
                refreshToken: refreshToken, // Optionally rotate refresh token here
            };
        } catch (error) {
            throw new UnauthorizedAppException('Invalid or expired refresh token', 'INVALID_REFRESH_TOKEN');
        }
    }


    async registerMember(
        model: RegisterMemberDto,
        files: {
            image?: Express.Multer.File[];
            idCardFrontImage?: Express.Multer.File[];
            idCardBackImage?: Express.Multer.File[];
        },
    ): Promise<UserResponseDto> {
        return await this.userService.registerMember(model, files);
    }

    async registerTrainer(
        model: RegisterTrainerDto,
        files: {
            image?: Express.Multer.File[];
            idCardFrontImage?: Express.Multer.File[];
            idCardBackImage?: Express.Multer.File[];
        },
    ): Promise<UserResponseDto> {
        return await this.userService.registerTrainer(model, files);
    }

    /**
     * Verifies a user's email address using a verification code.
     * @param email 
     * @param code 
     * @returns 
     */
    async verifyEmail(email: string, code: string): Promise<boolean> {
        return await this.userService.verifyEmail(email, code);
    }

    /**
     * Resends a verification code to a user's email.
     * @param email 
     * @returns 
     */
    async resendVerificationCode(email: string): Promise<boolean> {
        return await this.userService.resendVerificationCode(email);
    }

    async forgotPassword(model: ForgotPasswordDto): Promise<boolean> {
        return await this.userService.forgotPassword(model.email);
    }

    async verifyPasswordResetOtp(model: VerifyPasswordResetOtpDto): Promise<{ resetKey: string }> {
        const resetKey = await this.userService.verifyPasswordResetOtp(model.email, model.otp);
        return { resetKey };
    }

    async resetPassword(model: ResetPasswordDto): Promise<boolean> {
        return await this.userService.resetPasswordByKey(model.resetKey, model.newPassword);
    }

    /**
     * Logout user and remove access token
     * @param userId 
     * @param sessionId 
     * @returns 
     */
    async logout(userId: string, sessionId: string) {
        await this.userService.deleteUserSessionById(userId, sessionId);
    }

    private async validateUser(model: LoginDto): Promise<UserEntity | null> {
        const user = await this.userService.findByEmailOrUsernameForLogin(model.username, true);

        if (!user) {
            throw new UnauthorizedAppException('Invalid username or password', 'INVALID_USERNAME_OR_PASSWORD');
        }

        const isPasswordMatched = await this.userService.comparePassword(model.password, user.password || '');
        if (!isPasswordMatched) {
            throw new UnauthorizedAppException('Invalid username or password', 'INVALID_USERNAME_OR_PASSWORD');
        }

        const canBypassInactiveLogin = user.verificationStatus === 'PENDING' || user.verificationStatus === 'REJECTED';
        if (!user.isActive && !canBypassInactiveLogin) {
            throw new UnauthorizedAppException('Your account is not active', 'USER_IS_NOT_ACTIVE');
        }

        return user;
    }

    private async registerLoginDeviceToken(userId: string, model: LoginDto): Promise<void> {
        if (!model.fcmToken || !model.devicePlatform) {
            return;
        }

        await this.notificationService.registerDeviceToken(userId, {
            token: model.fcmToken,
            platform: model.devicePlatform,
            deviceId: model.deviceId,
        });
    }

    private async generateAccessToken(user: UserEntity, sessionId: string): Promise<string> {
        const payload = {
            id: user.id,
            sub: user.id,
            sid: sessionId,
            email: user.email,
            username: user.username,
            firstName: user.firstName,
            lastName: user.lastName,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            phoneNumber: user.phoneNumber,
            roles: user.roles?.map((role) => {
                return {
                    id: role.id,
                    name: role.name,
                    description: role.description,
                };
            }),
        };
        return this.jwtService.signAsync(payload, {
            expiresIn: this.config.jwt.expiresIn as any,
            secret: this.config.jwt.secret,
        });
    }

    private async generateRefreshToken(user: UserEntity): Promise<string> {
        const payload = {
            id: user.id,
            sub: user.id,
        };
        return this.jwtService.signAsync(payload, {
            secret: this.config.jwt.refreshSecret,
            expiresIn: this.config.jwt.refreshExpiresIn as any,
        });
    }
}
