import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowPendingAccount } from 'src/common/decorators/allow-pending-account.decorator';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { RegisterDeviceTokenDto } from '../../notification/dto/register-device-token.dto';
import { RemoveDeviceTokenDto } from '../../notification/dto/remove-device-token.dto';
import { NotificationResponseDto, NotificationUnreadCountResponseDto } from '../../notification/dto/notification-response.dto';
import { NotificationPreferenceResponseDto } from '../../notification/dto/notification-preference.dto';
import { UpdateNotificationPreferenceDto } from '../../notification/dto/update-notification-preference.dto';
import { TestPushNotificationDto } from '../../notification/dto/test-push-notification.dto';
import { NotificationService, NotificationType } from '../../notification/notification.service';

@ApiBearerAuth('access-token')
@ApiTags('8. Notifications')
@Controller('notifications')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class TrainerNotificationController {
    constructor(private readonly notificationService: NotificationService) { }

    @Get('preferences')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: get notification preferences' })
    async getNotificationPreferences(
        @Request() req,
    ): Promise<CustomResponse<NotificationPreferenceResponseDto>> {
        const prefs = await this.notificationService.getNotificationPreferences(req.user.currentUserId);
        return new CustomResponse<NotificationPreferenceResponseDto>('Notification preferences fetched successfully', prefs, 200);
    }

    @Patch('preferences')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: update notification preferences' })
    async updateNotificationPreferences(
        @Request() req,
        @Body() model: UpdateNotificationPreferenceDto,
    ): Promise<CustomResponse<NotificationPreferenceResponseDto>> {
        const prefs = await this.notificationService.updateNotificationPreferences(req.user.currentUserId, model);
        return new CustomResponse<NotificationPreferenceResponseDto>('Notification preferences updated successfully', prefs, 200);
    }

    @Get()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: list notifications' })
    async findNotifications(
        @Request() req,
        @Query('limit') limit?: string,
        @Query('offset') offset?: string,
    ): Promise<CustomResponse<NotificationResponseDto[]>> {
        const notifications = await this.notificationService.findNotifications(
            req.user.currentUserId,
            limit ? Number(limit) : undefined,
            offset ? Number(offset) : undefined,
        );
        return new CustomResponse<NotificationResponseDto[]>('Notifications fetched successfully', notifications, 200);
    }

    @Get('unread-count')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: get unread notification count' })
    async getUnreadCount(@Request() req): Promise<CustomResponse<NotificationUnreadCountResponseDto>> {
        const unreadCount = await this.notificationService.getUnreadCount(req.user.currentUserId);
        return new CustomResponse<NotificationUnreadCountResponseDto>('Unread notification count fetched successfully', unreadCount, 200);
    }

    @Post('device-tokens')
    @HttpCode(200)
    @AllowPendingAccount()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: register or refresh FCM device token' })
    async registerDeviceToken(
        @Request() req,
        @Body() model: RegisterDeviceTokenDto,
    ): Promise<CustomResponse<{ token: string }>> {
        const deviceToken = await this.notificationService.registerDeviceToken(req.user.currentUserId, model);
        return new CustomResponse<{ token: string }>('Device token saved successfully', deviceToken, 200);
    }

    @Delete('device-tokens')
    @HttpCode(200)
    @AllowPendingAccount()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: deactivate FCM device token' })
    async removeDeviceToken(
        @Request() req,
        @Body() model: RemoveDeviceTokenDto,
    ): Promise<CustomResponse<{ token: string }>> {
        const deviceToken = await this.notificationService.removeDeviceToken(req.user.currentUserId, model.token);
        return new CustomResponse<{ token: string }>('Device token removed successfully', deviceToken, 200);
    }

    @Post('test-push')
    @HttpCode(200)
    @AllowPendingAccount()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: send a test push notification' })
    async sendTestPush(
        @Request() req,
        @Body() model: TestPushNotificationDto,
    ): Promise<CustomResponse<NotificationResponseDto>> {
        const notification = await this.notificationService.notifyUser({
            userId: req.user.currentUserId,
            type: NotificationType.TEST_PUSH,
            title: model.title?.trim() || 'Test notification',
            body: model.body?.trim() || 'Firebase push notification is working.',
            data: {
                source: 'test-push',
                ...(model.data ?? {}),
            },
        });

        return new CustomResponse<NotificationResponseDto>('Test push notification sent successfully', notification, 200);
    }

    @Patch('read-all')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: mark all notifications as read' })
    async markAllRead(@Request() req): Promise<CustomResponse<{ success: true }>> {
        const result = await this.notificationService.markAllRead(req.user.currentUserId);
        return new CustomResponse<{ success: true }>('Notifications marked as read', result, 200);
    }

    @Delete('all')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: delete all notifications' })
    async deleteAllNotifications(@Request() req): Promise<CustomResponse<{ success: true }>> {
        const result = await this.notificationService.deleteAllNotifications(req.user.currentUserId);
        return new CustomResponse<{ success: true }>('Notifications deleted successfully', result, 200);
    }

    @Patch(':notificationId/read')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: mark a notification as read' })
    async markRead(
        @Request() req,
        @Param('notificationId') notificationId: string,
    ): Promise<CustomResponse<{ notificationId: string }>> {
        const result = await this.notificationService.markRead(req.user.currentUserId, notificationId);
        return new CustomResponse<{ notificationId: string }>('Notification marked as read', result, 200);
    }

    @Delete(':notificationId')
    @HttpCode(200)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: delete a notification' })
    async deleteNotification(
        @Request() req,
        @Param('notificationId') notificationId: string,
    ): Promise<CustomResponse<{ notificationId: string }>> {
        const result = await this.notificationService.deleteNotification(req.user.currentUserId, notificationId);
        return new CustomResponse<{ notificationId: string }>('Notification deleted successfully', result, 200);
    }
}
