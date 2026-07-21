import { Expose, Type } from 'class-transformer';
import { FitnessClassAvailabilitySlotResponseDto } from 'src/core/class/dto/fitness-class-response.dto';
import { TrainerReviewResponseDto } from 'src/core/review/dto/trainer-review-response.dto';

export class TrainerLocationStateResponseDto {
  @Expose()
  userId: string;

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

  constructor(partial: Partial<TrainerLocationStateResponseDto>) {
    Object.assign(this, partial);
  }
}

export class MemberLocationStateResponseDto {
  @Expose()
  userId: string;

  @Expose()
  currentLat: number | null;

  @Expose()
  currentLng: number | null;

  @Expose()
  locationUpdatedAt: Date | null;

  constructor(partial: Partial<MemberLocationStateResponseDto>) {
    Object.assign(this, partial);
  }
}

export class TrainerClassSummaryResponseDto {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose()
  classType: string;

  @Expose()
  sessionFormat: string;

  @Expose()
  pricePerMember: string;

  @Expose()
  scheduledAt: Date;

  @Expose()
  status: string;

  constructor(partial: Partial<TrainerClassSummaryResponseDto>) {
    Object.assign(this, partial);
  }
}

export class TrainerSearchResponseDto {
  @Expose()
  id: string;

  @Expose()
  name: string | null;

  @Expose()
  profileImageUrl: string | null;

  @Expose()
  bio: string | null;

  @Expose()
  classesTaught: string | null;

  @Expose()
  certifications: string | null;

  @Expose()
  classDeliveryMode: string | null;

  @Expose()
  isOnline: boolean;

  @Expose()
  lastSeen: Date | null;

  @Expose()
  startingPrice: string | null;

  @Expose()
  averageRating: number | null;

  @Expose()
  reviewCount: number;

  @Expose()
  distanceMeters?: number | null;

  @Expose()
  locationLabel?: string | null;

  constructor(partial: Partial<TrainerSearchResponseDto>) {
    Object.assign(this, partial);
  }
}

export class TrainerProfileResponseDto extends TrainerSearchResponseDto {
  @Expose()
  instructorExperience: string | null;

  @Expose()
  experienceYears: number | null;

  @Expose()
  clients: number;

  @Expose()
  baseLocationLat: number | null;

  @Expose()
  baseLocationLng: number | null;

  @Expose()
  liveLocationLat: number | null;

  @Expose()
  liveLocationLng: number | null;

  @Expose()
  @Type(() => TrainerClassSummaryResponseDto)
  activeClasses: TrainerClassSummaryResponseDto[];

  constructor(partial: Partial<TrainerProfileResponseDto>) {
    super(partial);
    Object.assign(this, partial);
  }
}

export class TrainerOverviewClassResponseDto {
  @Expose()
  id: string;

  @Expose()
  trainerUserId: string;

  @Expose()
  name: string;

  @Expose()
  classType: string;

  @Expose()
  sessionPlanType: string;

  @Expose()
  durationMinutes: number;

  @Expose()
  pricePerMember: string;

  @Expose()
  sessionFormat: string;

  @Expose()
  capacity: number | null;

  @Expose()
  bookedMemberCount: number;

  @Expose()
  spotsRemaining: number | null;

  @Expose()
  nextSlot: FitnessClassAvailabilitySlotResponseDto | null;

  @Expose()
  @Type(() => FitnessClassAvailabilitySlotResponseDto)
  availableSlots: FitnessClassAvailabilitySlotResponseDto[];

  @Expose()
  createdAt: Date;

  @Expose()
  updatedAt: Date | null;

  constructor(partial: Partial<TrainerOverviewClassResponseDto>) {
    Object.assign(this, partial);
  }
}

export class TrainerOverviewStatsResponseDto {
  @Expose()
  experienceYears: number | null;

  @Expose()
  reviewCount: number;

  @Expose()
  averageRating: number;

  @Expose()
  clients: number;

  constructor(partial: Partial<TrainerOverviewStatsResponseDto>) {
    Object.assign(this, partial);
  }
}

export class TrainerOverviewLocationResponseDto {
  @Expose()
  label: string | null;

  @Expose()
  distanceMeters: number | null;

  @Expose()
  baseLocationLat: number | null;

  @Expose()
  baseLocationLng: number | null;

  @Expose()
  liveLocationLat: number | null;

  @Expose()
  liveLocationLng: number | null;

  constructor(partial: Partial<TrainerOverviewLocationResponseDto>) {
    Object.assign(this, partial);
  }
}

export class TrainerOverviewResponseDto {
  @Expose()
  id: string;

  @Expose()
  name: string | null;

  @Expose()
  profileImageUrl: string | null;

  @Expose()
  bio: string | null;

  @Expose()
  classesTaught: string | null;

  @Expose()
  certifications: string | null;

  @Expose()
  classDeliveryMode: string | null;

  @Expose()
  instructorExperience: string | null;

  @Expose()
  isOnline: boolean;

  @Expose()
  lastSeen: Date | null;

  @Expose()
  startingPrice: string | null;

  @Expose()
  priceRange: string | null;

  @Expose()
  @Type(() => TrainerOverviewStatsResponseDto)
  stats: TrainerOverviewStatsResponseDto;

  @Expose()
  @Type(() => TrainerOverviewClassResponseDto)
  classes: TrainerOverviewClassResponseDto[];

  @Expose()
  @Type(() => TrainerReviewResponseDto)
  reviews: TrainerReviewResponseDto[];

  @Expose()
  @Type(() => TrainerOverviewLocationResponseDto)
  location: TrainerOverviewLocationResponseDto;

  constructor(partial: Partial<TrainerOverviewResponseDto>) {
    Object.assign(this, partial);
  }
}
