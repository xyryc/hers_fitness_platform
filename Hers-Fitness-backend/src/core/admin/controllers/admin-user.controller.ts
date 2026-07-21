import { Controller, Get, HttpCode, Param, Patch, Query, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserService } from '../../user/user.service';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { UserResponseDto } from '../../user/dto/user-response.dto';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { AdminVerificationRequestDto } from '../dto/admin-verification-request.dto';
import { AdminUserListItemDto } from '../dto/admin-user-list-item.dto';
import { AdminTrainerListItemDto } from '../dto/admin-trainer-list-item.dto';

@ApiBearerAuth('access-token')
@Controller('users')
@UseGuards(AuthGuard, RolesGuard)
@AllowedRoles(Roles.Admin)
export class AdminUserController {
    constructor(private readonly userService: UserService) { }

    @ApiTags('7. Admin Portal')
    @Get('/admin/verifications')
    @ApiOperation({ summary: 'Admin: list pending member and trainer verifications' })
    async getPendingVerifications(
        @Query('type') type?: string,
    ): Promise<CustomResponse<AdminVerificationRequestDto[]>> {
        const verifications = await this.userService.findPendingVerificationRequests(type);
        return new CustomResponse<AdminVerificationRequestDto[]>('Pending verifications fetched successfully', verifications, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/members')
    @ApiOperation({ summary: 'Admin: list all members' })
    async getAllMembers(): Promise<CustomResponse<AdminUserListItemDto[]>> {
        const members = await this.userService.findAllMembers();
        return new CustomResponse<AdminUserListItemDto[]>('Members fetched successfully', members, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/members/:userId')
    @ApiOperation({ summary: 'Admin: get member details' })
    async getMemberDetails(@Param('userId') userId: string): Promise<CustomResponse<UserResponseDto>> {
        const member = await this.userService.findAdminMemberById(userId);
        return new CustomResponse<UserResponseDto>('Member fetched successfully', member, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/trainers')
    @ApiOperation({ summary: 'Admin: list all trainers' })
    async getAllTrainers(): Promise<CustomResponse<AdminTrainerListItemDto[]>> {
        const trainers = await this.userService.findAllTrainers();
        return new CustomResponse<AdminTrainerListItemDto[]>('Trainers fetched successfully', trainers, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get('/admin/trainers/:userId')
    @ApiOperation({ summary: 'Admin: get trainer details' })
    async getTrainerDetails(@Param('userId') userId: string): Promise<CustomResponse<UserResponseDto>> {
        const trainer = await this.userService.findAdminTrainerById(userId);
        return new CustomResponse<UserResponseDto>('Trainer fetched successfully', trainer, 200);
    }

    @ApiTags('7. Admin Portal')
    @Patch('/admin/:userId/approve')
    @HttpCode(200)
    @ApiOperation({ summary: 'Admin: approve a member or trainer account' })
    async approveUser(
        @Param('userId') userId: string,
        @Request() req,
    ): Promise<CustomResponse<UserResponseDto>> {
        const user = await this.userService.approveUserVerification(userId, req.user.currentUserId);
        return new CustomResponse<UserResponseDto>('User approved successfully', user, 200);
    }

    @ApiTags('7. Admin Portal')
    @Get(':email')
    @AllowedRoles(Roles.Admin, Roles.Trainer)
    async getUserByEmail(@Param('email') email: string): Promise<CustomResponse<UserResponseDto | null>> {
        const user = await this.userService.findByEmail(email);

        if (!user) {
            throw new NotFoundAppException('User not found', 'USER_NOT_FOUND');
        }

        return new CustomResponse<UserResponseDto | null>('User fetched successfully', user, 200);
    }
}
