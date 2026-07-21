export interface MemberFitnessAssessmentEntity {
    id: string;
    userId: string;
    fitnessGoal: string;
    weight: number;
    weightUnit: string;
    age: number;
    hasPreviousFitnessExperience: boolean;
    physicalLimitations: string | null;
    dietPreference: string;
    takingSupplements: boolean;
    supplements: string[];
    calorieGoal: number;
    calorieUnit: string;
    sleepQuality: string;
    createdAt: Date;
    updatedAt: Date | null;
}
