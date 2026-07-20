import { BadRequestException, Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import { AppConfig } from 'src/config/app.config';
import CloudinaryUploadResponseDto from './cloudinary-upload-response.dto';

@Injectable()
export class CloudinaryStorageService {
    constructor(private readonly appConfig: AppConfig) {
        cloudinary.config({
            cloud_name: this.appConfig.cloudinary.cloudName,
            api_key: this.appConfig.cloudinary.apiKey,
            api_secret: this.appConfig.cloudinary.apiSecret,
        });
    }

    async uploadImage(
        file: Express.Multer.File,
        folder: string,
    ): Promise<CloudinaryUploadResponseDto> {
        if (!this.appConfig.cloudinary.cloudName || !this.appConfig.cloudinary.apiKey || !this.appConfig.cloudinary.apiSecret) {
            throw new BadRequestException('Cloudinary is not configured properly.');
        }

        const base64 = file.buffer.toString('base64');
        const dataUri = `data:${file.mimetype};base64,${base64}`;

        let result;
        try {
            result = await cloudinary.uploader.upload(dataUri, {
                folder,
                resource_type: 'image',
            });
        } catch (error: any) {
            const message =
                error?.message ||
                error?.error?.message ||
                'Cloudinary image upload failed.';

            throw new BadRequestException(message);
        }

        return {
            publicId: result.public_id,
            secureUrl: result.secure_url,
            originalFileName: file.originalname,
            fileType: file.mimetype,
            fileSize: file.size,
        };
    }

    async deleteImage(publicId: string): Promise<void> {
        try {
            await cloudinary.uploader.destroy(publicId, {
                resource_type: 'image',
            });
        } catch (error: any) {
            const message =
                error?.message ||
                error?.error?.message ||
                'Cloudinary image delete failed.';

            throw new BadRequestException(message);
        }
    }
}
