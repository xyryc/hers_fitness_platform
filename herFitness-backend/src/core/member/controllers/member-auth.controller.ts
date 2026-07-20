import { Body, Controller, HttpCode, Post, UploadedFiles, UseInterceptors } from "@nestjs/common";
import { AuthService } from "../../auth/auth.service";
import CustomResponse from "src/common/dto/custom-response.dto";
import { RegisterMemberDto } from "../../auth/dto/register-member.dto";
import { FileFieldsInterceptor } from "@nestjs/platform-express";
import { ApiBody, ApiConsumes, ApiOperation, ApiTags } from "@nestjs/swagger";

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

@ApiTags('0. Auth & Onboarding')
@Controller('auth')
export class MemberAuthController {
    constructor(private readonly authService: AuthService) { }

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
}
