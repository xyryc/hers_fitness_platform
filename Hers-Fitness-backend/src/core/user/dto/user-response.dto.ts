import { Expose, Exclude } from 'class-transformer';
import { RoleResponseDto } from './role-response.dto';
import { MemberFitnessAssessmentResponseDto } from './member-fitness-assessment-response.dto';

export class UserRecentActivityResponseDto {
    @Expose()
    type: string;

    @Expose()
    title: string;

    @Expose()
    description: string | null;

    @Expose()
    occurredAt: Date;

    @Expose()
    metadata: Record<string, any>;

    constructor(partial: Partial<UserRecentActivityResponseDto>) {
        Object.assign(this, partial);
    }
}

export class UserResponseDto {
    @Expose()
    id: string;

    @Expose()
    email: string | null;

    @Expose()
    username: string | null;

    @Exclude()
    password?: string | null;

    @Expose()
    firstName: string | null;

    @Expose()
    lastName: string | null;

    @Expose()
    displayName: string | null;

    @Expose()
    phoneNumber: string | null;

    @Expose()
    profileImageUrl: string | null;

    /**
     * Alias for profileImageUrl — used by the member app (imageUrl key).
     */
    @Expose()
    imageUrl: string | null;

    @Expose()
    coverPhotoUrl: string | null;

    @Expose()
    state: string | null;

    @Expose()
    location: string | null;

    @Expose()
    idCardType: string | null;

    @Expose()
    idCardNumber: string | null;

    @Expose()
    idCardFrontImageUrl: string | null;

    @Expose()
    idCardBackImageUrl: string | null;

    @Expose()
    verificationStatus: string | null;

    @Expose()
    classesTaught: string | null;

    /** Parsed array form of classesTaught — used by the trainer app */
    @Expose()
    fitnessClasses: string[];

    @Expose()
    instructorExperience: string | null;

    /** Alias for instructorExperience — used by the trainer app */
    @Expose()
    instructorDuration: string | null;

    @Expose()
    certifications: string | null;

    @Expose()
    classDeliveryMode: string | null;

    /**
     * Human-readable session format used by the trainer app.
     * Mapped from classDeliveryMode: ONLINE→"Online", OFFLINE→"In person", BOTH→"Both"
     */
    @Expose()
    sessionFormat: string | null;

    @Expose()
    baseLocationLat: number | null;

    @Expose()
    baseLocationLng: number | null;

    @Expose()
    liveLocationLat: number | null;

    @Expose()
    liveLocationLng: number | null;

    @Expose()
    isOnline: boolean;

    @Expose()
    lastSeen: Date | null;

    @Expose()
    stripeConnectAccountId: string | null;

    @Expose()
    stripeConnectOnboardingComplete: boolean;

    @Expose()
    stripeChargesEnabled: boolean;

    @Expose()
    stripePayoutsEnabled: boolean;

    @Expose()
    stripeDetailsSubmitted: boolean;

    @Expose()
    stripeConnectUpdatedAt: Date | null;

    @Expose()
    payoutReady: boolean;

    @Expose()
    currentLat: number | null;

    @Expose()
    currentLng: number | null;

    @Expose()
    locationUpdatedAt: Date | null;

    @Expose()
    hasCompletedMemberFitnessAssessment: boolean;

    @Expose()
    age: number | null;

    @Expose()
    weight: number | null;

    @Expose()
    weightUnit: string | null;

    @Expose()
    dietPreference: string | null;

    @Expose()
    memberFitnessAssessment?: MemberFitnessAssessmentResponseDto | null;

    @Expose()
    provider: string;

    @Expose()
    providerId: string | null;

    @Expose()
    isEmailVerified: boolean;

    @Expose()
    isPhoneVerified: boolean;

    @Expose()
    isActive: boolean;

    @Expose()
    dob: Date | null;

    @Expose()
    gender: string | null;

    @Expose()
    bio: string | null;

    @Expose()
    tagline: string | null;

    @Expose()
    website: string | null;

    @Expose()
    countryCodeIso3: string | null;

    @Expose()
    timezone: string | null;

    @Expose()
    locale: string | null;

    @Expose()
    metadata: any;

    @Expose()
    createdAt: Date;

    @Expose()
    updatedAt: Date | null;

    @Expose()
    roles?: RoleResponseDto[] | null;

    @Expose()
    recentActivity?: UserRecentActivityResponseDto[];

    constructor(partial: Partial<UserResponseDto>) {
        Object.assign(this, partial);
        // imageUrl is the member-app alias for profileImageUrl
        this.imageUrl = (partial as any).profileImageUrl ?? partial.imageUrl ?? null;
    }
}
