import { Injectable } from '@nestjs/common';
import { Prisma } from 'prisma/generated/prisma/client';
import { CreateTrainerProfileDto } from '../../dto/create-trainer-profile.dto';

@Injectable()
export class TrainerProfileRepository {
    async create(
        tx: Prisma.TransactionClient,
        userId: string,
        data: CreateTrainerProfileDto,
    ) {
        return (tx as any).trainerProfile.create({
            data: {
                userId,
                bio: data.bio,
                classesTaught: data.classesTaught,
                instructorExperience: data.instructorExperience,
                certifications: data.certifications,
                classDeliveryMode: data.classDeliveryMode,
            },
        });
    }
}
