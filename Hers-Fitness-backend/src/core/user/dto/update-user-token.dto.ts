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

export class UpdateUserTokenDto {
    @IsString()
    @IsNotEmpty({ message: 'Token is required' })
    token: string;

    @IsOptional()
    @IsEnum(UserTokenType, {
        message: `Token type must be one of: ${Object.values(UserTokenType).join(', ')}`,
    })
    type?: UserTokenType | null;

    @IsOptional()
    @Type(() => Date)
    @IsDate()
    expiresAt?: Date | null;

    @IsOptional()
    @IsBoolean()
    isUsed?: boolean | null = false;

    @IsOptional()
    @IsString()
    ipAddress?: string | null;

    @IsOptional()
    @IsString()
    userAgent?: string | null;
}
