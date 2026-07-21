import { Expose } from "class-transformer";
import { UserResponseDto } from "src/core/user/dto/user-response.dto";

export class LoginResponseDto {
    @Expose()
    user: UserResponseDto;

    @Expose()
    accessToken: string;

    @Expose()
    refreshToken: string;

    constructor(partial: Partial<LoginResponseDto>) {
        Object.assign(this, partial);
    }
}