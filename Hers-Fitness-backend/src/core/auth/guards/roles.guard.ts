import { CanActivate, ExecutionContext, Injectable } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import { ROLES_KEY } from "src/common/decorators/roles.decorator";
import { Roles } from "src/common/enums/roles.enum";
import { UnauthorizedAppException } from "src/common/exceptions/unauthorized-error";
import { UserService } from "src/core/user/user.service";

@Injectable()
export class RolesGuard implements CanActivate {

    constructor(
        private readonly userService: UserService,
        private readonly reflector: Reflector
    ) { }

    async canActivate(context: ExecutionContext): Promise<boolean> {
        const request = context.switchToHttp().getRequest();
        const currentUserId = request.user.currentUserId;

        const userRoles = await this.userService.findRolesByUserId(currentUserId);
        if (!userRoles) {
            throw new UnauthorizedAppException('Invalid user', 'INVALID_USER');
        }

        const roles = this.reflector.get<string[]>(ROLES_KEY, context.getHandler());
        if (!roles) {
            return true;
        }

        const hasMatchingRole = userRoles.some((role) => roles.includes(role.name as Roles));
        if (!hasMatchingRole) {
            throw new UnauthorizedAppException('You are not authorized to access this resource', 'UNAUTHORIZED');
        }

        return true;
    }
}
