import { Expose } from 'class-transformer';

export class MemberFitnessAssessmentResponseDto {
    @Expose()
    id: string;

    @Expose()
    userId: string;

    @Expose()
    fitnessGoal: string;

    @Expose()
    weight: number;

    @Expose()
    weightUnit: string;

    @Expose()
    age: number;

    @Expose()
    hasPreviousFitnessExperience: boolean;

    @Expose()
    physicalLimitations: string | null;

    @Expose()
    dietPreference: string;

    @Expose()
    takingSupplements: boolean;

    @Expose()
    supplements: string[];

    @Expose()
    calorieGoal: number;

    @Expose()
    calorieUnit: string;

    @Expose()
    sleepQuality: string;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    constructor(partial: Partial<MemberFitnessAssessmentResponseDto>) {
        Object.assign(this, partial);
    }
}
