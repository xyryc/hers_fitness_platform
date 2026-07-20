import { CanActivate, ExecutionContext, Injectable } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { ALLOW_PENDING_ACCOUNT_KEY } from "src/common/decorators/allow-pending-account.decorator";
import { ForbiddenAppException } from "src/common/exceptions/forbidden-error";
import { Roles } from "src/common/enums/roles.enum";
import { UserService } from "src/core/user/user.service";

@Injectable()
export class ApprovedAccountGuard implements CanActivate {
    constructor(
        private readonly userService: UserService,
        private readonly reflector: Reflector,
    ) { }

    async canActivate(context: ExecutionContext): Promise<boolean> {
        const allowPendingAccount = this.reflector.getAllAndOverride<boolean>(ALLOW_PENDING_ACCOUNT_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);
        if (allowPendingAccount) {
            return true;
        }

        const request = context.switchToHttp().getRequest();
        const currentUserId = request.user?.currentUserId;

        if (!currentUserId) {
            throw new ForbiddenAppException('You must be logged in to access this resource.', 'LOGIN_REQUIRED');
        }

        const user = await this.userService.findById(currentUserId);
        if (!user) {
            throw new ForbiddenAppException('User not found.', 'USER_NOT_FOUND');
        }

        const roleNames = user.roles?.map((role) => role.name) ?? [];
        if (roleNames.includes(Roles.Admin)) {
            return true;
        }

        const requiresApproval = roleNames.includes(Roles.Member) || roleNames.includes(Roles.Trainer);
        if (!requiresApproval) {
            return true;
        }

        if (user.verificationStatus === 'APPROVED') {
            return true;
        }

        if (user.verificationStatus === 'REJECTED') {
            throw new ForbiddenAppException(
                'Your account verification was rejected. Please contact the admin to continue.',
                'ACCOUNT_VERIFICATION_REJECTED',
            );
        }

        throw new ForbiddenAppException(
            'Your account is pending admin approval. You can browse the app, but this feature is locked until approval.',
            'ACCOUNT_APPROVAL_REQUIRED',
        );
    }
}
