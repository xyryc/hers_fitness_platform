import { Body, Controller, HttpCode, Post, UploadedFiles, UseInterceptors } from "@nestjs/common";
import { AuthService } from "../../auth/auth.service";
import CustomResponse from "src/common/dto/custom-response.dto";
import { FileFieldsInterceptor } from "@nestjs/platform-express";
import { RegisterTrainerDto } from "../../auth/dto/register-trainer.dto";
import { ApiBody, ApiConsumes, ApiOperation, ApiTags } from "@nestjs/swagger";

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
export class TrainerAuthController {
    constructor(private readonly authService: AuthService) { }

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
}
