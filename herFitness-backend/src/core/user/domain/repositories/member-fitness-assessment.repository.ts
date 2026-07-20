import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { MemberFitnessAssessmentEntity } from '../entities/member-fitness-assessment.entity';
import { UpsertMemberFitnessAssessmentDto } from '../../dto/upsert-member-fitness-assessment.dto';

@Injectable()
export class MemberFitnessAssessmentRepository {
    constructor(private readonly prisma: PrismaService) { }

    private getSelectPattern() {
        return {
            id: true,
            userId: true,
            fitnessGoal: true,
            weight: true,
            weightUnit: true,
            age: true,
            hasPreviousFitnessExperience: true,
            physicalLimitations: true,
            dietPreference: true,
            takingSupplements: true,
            supplements: true,
            calorieGoal: true,
            calorieUnit: true,
            sleepQuality: true,
            createdAt: true,
            updatedAt: true,
        };
    }

    async findByUserId(userId: string): Promise<MemberFitnessAssessmentEntity | null> {
        const assessment = await (this.prisma as any).memberFitnessAssessment.findUnique({
            where: { userId },
            select: this.getSelectPattern(),
        });

        return assessment ? this.mapToEntity(assessment) : null;
    }

    async upsert(userId: string, model: UpsertMemberFitnessAssessmentDto): Promise<MemberFitnessAssessmentEntity> {
        const assessment = await (this.prisma as any).memberFitnessAssessment.upsert({
            where: { userId },
            create: {
                userId,
                fitnessGoal: model.fitnessGoal as any,
                weight: model.weight,
                weightUnit: model.weightUnit as any,
                age: model.age,
                hasPreviousFitnessExperience: model.hasPreviousFitnessExperience,
                physicalLimitations: model.physicalLimitations?.trim() || null,
                dietPreference: model.dietPreference as any,
                takingSupplements: model.takingSupplements,
                supplements: model.takingSupplements ? (model.supplements as any) : [],
                calorieGoal: model.calorieGoal,
                calorieUnit: model.calorieUnit as any,
                sleepQuality: model.sleepQuality as any,
            },
            update: {
                fitnessGoal: model.fitnessGoal as any,
                weight: model.weight,
                weightUnit: model.weightUnit as any,
                age: model.age,
                hasPreviousFitnessExperience: model.hasPreviousFitnessExperience,
                physicalLimitations: model.physicalLimitations?.trim() || null,
                dietPreference: model.dietPreference as any,
                takingSupplements: model.takingSupplements,
                supplements: model.takingSupplements ? (model.supplements as any) : [],
                calorieGoal: model.calorieGoal,
                calorieUnit: model.calorieUnit as any,
                sleepQuality: model.sleepQuality as any,
            },
            select: this.getSelectPattern(),
        });

        return this.mapToEntity(assessment);
    }

    private mapToEntity(assessment: any): MemberFitnessAssessmentEntity {
        return {
            id: assessment.id,
            userId: assessment.userId,
            fitnessGoal: assessment.fitnessGoal,
            weight: assessment.weight,
            weightUnit: assessment.weightUnit,
            age: assessment.age,
            hasPreviousFitnessExperience: assessment.hasPreviousFitnessExperience,
            physicalLimitations: assessment.physicalLimitations,
            dietPreference: assessment.dietPreference,
            takingSupplements: assessment.takingSupplements,
            supplements: assessment.supplements,
            calorieGoal: assessment.calorieGoal,
            calorieUnit: assessment.calorieUnit,
            sleepQuality: assessment.sleepQuality,
            createdAt: assessment.createdAt,
            updatedAt: assessment.updatedAt,
        };
    }
}
