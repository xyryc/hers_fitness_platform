import {
    IsBoolean,
    IsDate,
    IsEnum,
    IsNotEmpty,
    IsOptional,
    IsString,
} from 'class-validator';
import { Type } from 'class-transformer';
import { UserTokenType } from 'src/common/enums/user-token-type.enum';

export class CreateUserTokenDto {
    @IsString()
    @IsNotEmpty({ message: 'Token is required' })
    token: string;

    @IsEnum(UserTokenType, {
        message: `Token type must be one of: ${Object.values(UserTokenType).join(', ')}`,
    })
    type: UserTokenType;

    @IsOptional()
    @Type(() => Date)
    @IsDate()
    expiresAt?: Date;

    @IsOptional()
    @IsBoolean()
    isUsed?: boolean = false;

    @IsOptional()
    @IsString()
    ipAddress?: string | null;

    @IsOptional()
    @IsString()
    userAgent?: string | null;
}
