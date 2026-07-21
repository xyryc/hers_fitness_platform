import { TrainerClassDeliveryMode } from 'src/core/auth/dto/register-trainer.dto';

export interface CreateTrainerProfileDto {
    bio: string;
    classesTaught: string;
    instructorExperience: string;
    certifications: string;
    classDeliveryMode: TrainerClassDeliveryMode;
}
