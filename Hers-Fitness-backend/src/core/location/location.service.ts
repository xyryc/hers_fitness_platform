import { Injectable } from '@nestjs/common';
import { BadRequestAppException } from 'src/common/exceptions/bad-request.exception';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import {
  MemberCurrentLocationDto,
  TrainerBaseLocationDto,
  TrainerLiveLocationDto,
  TrainerOnlineStatusDto,
} from './dto/trainer-location.dto';
import { FitnessClassAvailabilitySlotResponseDto } from '../class/dto/fitness-class-response.dto';
import {
  TrainerReviewAuthorResponseDto,
  TrainerReviewResponseDto,
} from '../review/dto/trainer-review-response.dto';
import {
  MemberLocationStateResponseDto,
  TrainerClassSummaryResponseDto,
  TrainerLocationStateResponseDto,
  TrainerOverviewClassResponseDto,
  TrainerOverviewLocationResponseDto,
  TrainerOverviewResponseDto,
  TrainerOverviewStatsResponseDto,
  TrainerProfileResponseDto,
  TrainerSearchResponseDto,
} from './dto/location-response.dto';
import {
  NearbyTrainersQueryDto,
  SearchTrainersQueryDto,
  TrainerProfileDistanceQueryDto,
} from './dto/trainer-discovery-query.dto';
import { LocationRepository } from './domain/repositories/location.repository';

@Injectable()
export class LocationService {
  constructor(private readonly locationRepository: LocationRepository) {}

  async setTrainerBaseLocation(
    userId: string,
    model: TrainerBaseLocationDto,
  ): Promise<TrainerLocationStateResponseDto> {
    const trainerProfile =
      await this.locationRepository.updateTrainerBaseLocation(
        userId,
        model.lat,
        model.lng,
        model.timezone,
      );
    if (!trainerProfile) {
      throw new NotFoundAppException(
        'Trainer profile not found',
        'TRAINER_PROFILE_NOT_FOUND',
      );
    }

    return this.mapTrainerLocationState(trainerProfile);
  }

  async updateTrainerLiveLocation(
    userId: string,
    model: TrainerLiveLocationDto,
  ): Promise<TrainerLocationStateResponseDto> {
    const trainerProfile =
      await this.locationRepository.updateTrainerLiveLocation(
        userId,
        model.lat,
        model.lng,
        model.timezone,
      );
    if (!trainerProfile) {
      throw new NotFoundAppException(
        'Trainer profile not found',
        'TRAINER_PROFILE_NOT_FOUND',
      );
    }

    return this.mapTrainerLocationState(trainerProfile);
  }

  async clearTrainerLiveLocation(
    userId: string,
  ): Promise<TrainerLocationStateResponseDto> {
    const trainerProfile =
      await this.locationRepository.clearTrainerLiveLocation(userId);
    if (!trainerProfile) {
      throw new NotFoundAppException(
        'Trainer profile not found',
        'TRAINER_PROFILE_NOT_FOUND',
      );
    }

    return this.mapTrainerLocationState(trainerProfile);
  }

  async updateTrainerStatus(
    userId: string,
    model: TrainerOnlineStatusDto,
  ): Promise<TrainerLocationStateResponseDto> {
    const trainerProfile =
      await this.locationRepository.updateTrainerOnlineStatus(
        userId,
        model.isOnline,
      );
    if (!trainerProfile) {
      throw new NotFoundAppException(
        'Trainer profile not found',
        'TRAINER_PROFILE_NOT_FOUND',
      );
    }

    return this.mapTrainerLocationState(trainerProfile);
  }

  async updateMemberLocation(
    userId: string,
    model: MemberCurrentLocationDto,
  ): Promise<MemberLocationStateResponseDto> {
    const member: any =
      await this.locationRepository.updateMemberCurrentLocation(
        userId,
        model.lat,
        model.lng,
        model.timezone,
      );
    return new MemberLocationStateResponseDto({
      userId: member.id,
      currentLat: member.currentLat,
      currentLng: member.currentLng,
      locationUpdatedAt: member.locationUpdatedAt,
    });
  }

  async findNearbyTrainers(
    model: NearbyTrainersQueryDto,
  ): Promise<TrainerSearchResponseDto[]> {
    const trainers = await this.locationRepository.findNearbyTrainers(
      model.lat,
      model.lng,
      model.radiusKm ?? 10,
    );
    return trainers.map((trainer) => this.mapTrainerSearchResult(trainer));
  }

  async searchTrainers(
    model: SearchTrainersQueryDto,
  ): Promise<TrainerSearchResponseDto[]> {
    if (
      model.priceMin !== undefined &&
      model.priceMax !== undefined &&
      model.priceMin > model.priceMax
    ) {
      throw new BadRequestAppException(
        'price_min cannot be greater than price_max.',
        ['INVALID_PRICE_RANGE'],
      );
    }

    const trainers = await this.locationRepository.searchTrainers(model);
    return trainers.map((trainer) => this.mapTrainerSearchResult(trainer));
  }

  async findTrainerProfile(
    id: string,
    query: TrainerProfileDistanceQueryDto,
  ): Promise<TrainerProfileResponseDto> {
    const trainer: any =
      await this.locationRepository.findTrainerProfileById(id);
    if (
      !trainer ||
      (trainer.verification &&
        trainer.verification.verificationStatus !== 'APPROVED')
    ) {
      throw new NotFoundAppException('Trainer not found', 'TRAINER_NOT_FOUND');
    }

    const distanceMeters =
      query.lat !== undefined && query.lng !== undefined
        ? this.calculateDistanceMeters(
            query.lat,
            query.lng,
            trainer.trainerProfile?.isOnline &&
              trainer.trainerProfile?.liveLocationLat != null &&
              trainer.trainerProfile?.liveLocationLng != null
              ? trainer.trainerProfile.liveLocationLat
              : trainer.trainerProfile?.baseLocationLat,
            trainer.trainerProfile?.isOnline &&
              trainer.trainerProfile?.liveLocationLat != null &&
              trainer.trainerProfile?.liveLocationLng != null
              ? trainer.trainerProfile.liveLocationLng
              : trainer.trainerProfile?.baseLocationLng,
          )
        : null;

    const locationLabel =
      trainer.trainerProfile?.isOnline &&
      trainer.trainerProfile?.liveLocationLat != null &&
      trainer.trainerProfile?.liveLocationLng != null
        ? 'Active Now'
        : 'Based Nearby';

    return new TrainerProfileResponseDto({
      id: trainer.id,
      name: trainer.displayName ?? trainer.firstName ?? null,
      profileImageUrl: trainer.profileImageUrl ?? null,
      bio: trainer.trainerProfile?.bio ?? null,
      classesTaught: trainer.trainerProfile?.classesTaught ?? null,
      certifications: trainer.trainerProfile?.certifications ?? null,
      classDeliveryMode: trainer.trainerProfile?.classDeliveryMode ?? null,
      instructorExperience:
        trainer.trainerProfile?.instructorExperience ?? null,
      experienceYears: this.getExperienceYears(
        trainer.trainerProfile?.instructorExperience,
      ),
      clients: this.getClientCount(trainer.trainerBookings),
      isOnline: trainer.trainerProfile?.isOnline ?? false,
      lastSeen: trainer.trainerProfile?.lastSeen ?? null,
      startingPrice: this.getStartingPrice(trainer.createdClasses),
      averageRating: this.getAverageRating(trainer.trainerReviews),
      reviewCount: trainer.trainerReviews?.length ?? 0,
      distanceMeters,
      locationLabel: distanceMeters != null ? locationLabel : null,
      baseLocationLat: trainer.trainerProfile?.baseLocationLat ?? null,
      baseLocationLng: trainer.trainerProfile?.baseLocationLng ?? null,
      liveLocationLat: trainer.trainerProfile?.liveLocationLat ?? null,
      liveLocationLng: trainer.trainerProfile?.liveLocationLng ?? null,
      activeClasses: (trainer.createdClasses ?? []).map(
        (fitnessClass: any) =>
          new TrainerClassSummaryResponseDto({
            id: fitnessClass.id,
            name: fitnessClass.name,
            classType: fitnessClass.classType,
            sessionFormat: fitnessClass.sessionFormat,
            pricePerMember:
              fitnessClass.pricePerMember?.toString?.() ??
              String(fitnessClass.pricePerMember),
            scheduledAt: fitnessClass.scheduledAt,
            status: fitnessClass.status,
          }),
      ),
    });
  }

  async findTrainerOverview(
    id: string,
    query: TrainerProfileDistanceQueryDto,
  ): Promise<TrainerOverviewResponseDto> {
    const trainer: any =
      await this.locationRepository.findTrainerOverviewById(id);
    if (
      !trainer ||
      (trainer.verification &&
        trainer.verification.verificationStatus !== 'APPROVED')
    ) {
      throw new NotFoundAppException('Trainer not found', 'TRAINER_NOT_FOUND');
    }

    const distanceMeters =
      query.lat !== undefined && query.lng !== undefined
        ? this.calculateDistanceMeters(
            query.lat,
            query.lng,
            trainer.trainerProfile?.isOnline &&
              trainer.trainerProfile?.liveLocationLat != null &&
              trainer.trainerProfile?.liveLocationLng != null
              ? trainer.trainerProfile.liveLocationLat
              : trainer.trainerProfile?.baseLocationLat,
            trainer.trainerProfile?.isOnline &&
              trainer.trainerProfile?.liveLocationLat != null &&
              trainer.trainerProfile?.liveLocationLng != null
              ? trainer.trainerProfile.liveLocationLng
              : trainer.trainerProfile?.baseLocationLng,
          )
        : null;

    const locationLabel =
      distanceMeters != null
        ? trainer.trainerProfile?.isOnline &&
          trainer.trainerProfile?.liveLocationLat != null &&
          trainer.trainerProfile?.liveLocationLng != null
          ? 'Active Now'
          : 'Based Nearby'
        : (trainer.location ?? null);

    return new TrainerOverviewResponseDto({
      id: trainer.id,
      name: trainer.displayName ?? trainer.firstName ?? null,
      profileImageUrl: trainer.profileImageUrl ?? null,
      bio: trainer.trainerProfile?.bio ?? null,
      classesTaught: trainer.trainerProfile?.classesTaught ?? null,
      certifications: trainer.trainerProfile?.certifications ?? null,
      classDeliveryMode: trainer.trainerProfile?.classDeliveryMode ?? null,
      instructorExperience:
        trainer.trainerProfile?.instructorExperience ?? null,
      isOnline: trainer.trainerProfile?.isOnline ?? false,
      lastSeen: trainer.trainerProfile?.lastSeen ?? null,
      startingPrice: this.getStartingPrice(trainer.createdClasses),
      priceRange: this.getPriceRange(trainer.createdClasses),
      stats: new TrainerOverviewStatsResponseDto({
        experienceYears: this.getExperienceYears(
          trainer.trainerProfile?.instructorExperience,
        ),
        reviewCount: trainer._count?.trainerReviews ?? 0,
        averageRating:
          trainer.reviewAverageRating == null
            ? 0
            : Number(Number(trainer.reviewAverageRating).toFixed(2)),
        clients: this.getClientCount(trainer.trainerBookings),
      }),
      classes: (trainer.createdClasses ?? [])
        .map((fitnessClass: any) => this.mapTrainerOverviewClass(fitnessClass))
        .filter(
          (fitnessClass: TrainerOverviewClassResponseDto) =>
            fitnessClass.availableSlots.length > 0,
        ),
      reviews: (trainer.trainerReviews ?? []).map((review: any) =>
        this.mapTrainerOverviewReview(review),
      ),
      location: new TrainerOverviewLocationResponseDto({
        label: locationLabel,
        distanceMeters,
        baseLocationLat: trainer.trainerProfile?.baseLocationLat ?? null,
        baseLocationLng: trainer.trainerProfile?.baseLocationLng ?? null,
        liveLocationLat: trainer.trainerProfile?.liveLocationLat ?? null,
        liveLocationLng: trainer.trainerProfile?.liveLocationLng ?? null,
      }),
    });
  }

  private mapTrainerLocationState(
    trainerProfile: any,
  ): TrainerLocationStateResponseDto {
    return new TrainerLocationStateResponseDto({
      userId: trainerProfile.userId,
      baseLocationLat: trainerProfile.baseLocationLat,
      baseLocationLng: trainerProfile.baseLocationLng,
      liveLocationLat: trainerProfile.liveLocationLat,
      liveLocationLng: trainerProfile.liveLocationLng,
      isOnline: trainerProfile.isOnline,
      lastSeen: trainerProfile.lastSeen,
    });
  }

  private mapTrainerSearchResult(trainer: any): TrainerSearchResponseDto {
    return new TrainerSearchResponseDto({
      id: trainer.id,
      name: trainer.name ?? null,
      profileImageUrl: trainer.profileImageUrl ?? null,
      bio: trainer.bio ?? null,
      classesTaught: trainer.classesTaught ?? null,
      certifications: trainer.certifications ?? null,
      classDeliveryMode: trainer.classDeliveryMode ?? null,
      isOnline: Boolean(trainer.isOnline),
      lastSeen: trainer.lastSeen ?? null,
      startingPrice: trainer.startingPrice ?? null,
      averageRating:
        trainer.averageRating != null
          ? Number(Number(trainer.averageRating).toFixed(2))
          : null,
      reviewCount:
        trainer.reviewCount != null ? Number(trainer.reviewCount) : 0,
      distanceMeters:
        trainer.distanceMeters != null ? Number(trainer.distanceMeters) : null,
      locationLabel: trainer.locationLabel ?? null,
    });
  }

  private getStartingPrice(classes: any[] | undefined): string | null {
    if (!classes || classes.length === 0) return null;

    const prices = classes
      .map((fitnessClass) => Number(fitnessClass.pricePerMember))
      .filter((price) => !Number.isNaN(price));
    if (prices.length === 0) return null;

    return Math.min(...prices).toFixed(2);
  }

  private getPriceRange(classes: any[] | undefined): string | null {
    if (!classes || classes.length === 0) return null;

    const prices = classes
      .map((fitnessClass) => Number(fitnessClass.pricePerMember))
      .filter((price) => !Number.isNaN(price));
    if (prices.length === 0) return null;

    const minPrice = Math.min(...prices).toFixed(2);
    const maxPrice = Math.max(...prices).toFixed(2);
    return minPrice === maxPrice ? minPrice : `${minPrice}-${maxPrice}`;
  }

  private getExperienceYears(
    instructorExperience?: string | null,
  ): number | null {
    if (!instructorExperience) return null;

    const match = instructorExperience.match(/\d+(\.\d+)?/);
    if (!match) return null;

    const years = Number(match[0]);
    return Number.isFinite(years) ? years : null;
  }

  private getClientCount(bookings: any[] | undefined): number {
    if (!bookings || bookings.length === 0) return 0;

    return new Set(bookings.map((booking) => booking.memberUserId)).size;
  }

  private getAverageRating(reviews: any[] | undefined): number | null {
    if (!reviews || reviews.length === 0) return null;

    const total = reviews.reduce(
      (sum, review) => sum + Number(review.rating),
      0,
    );
    return Number((total / reviews.length).toFixed(2));
  }

  private mapTrainerOverviewClass(
    fitnessClass: any,
  ): TrainerOverviewClassResponseDto {
    const availableSlots = (fitnessClass.availabilitySlots ?? [])
      .map((slot: any) => this.mapTrainerOverviewSlot(fitnessClass, slot))
      .filter(
        (slot: FitnessClassAvailabilitySlotResponseDto) =>
          slot.availabilityStatus === 'AVAILABLE',
      );
    const nextSlot = availableSlots[0] ?? null;

    return new TrainerOverviewClassResponseDto({
      id: fitnessClass.id,
      trainerUserId: fitnessClass.trainerUserId,
      name: fitnessClass.name,
      classType: fitnessClass.classType,
      sessionPlanType: fitnessClass.sessionPlanType,
      durationMinutes: fitnessClass.durationMinutes,
      pricePerMember:
        fitnessClass.pricePerMember?.toString?.() ??
        String(fitnessClass.pricePerMember),
      sessionFormat: fitnessClass.sessionFormat,
      capacity: fitnessClass.maxMembers ?? null,
      bookedMemberCount: this.getClientCount(fitnessClass.bookings),
      spotsRemaining: nextSlot?.spotsRemaining ?? null,
      nextSlot,
      availableSlots,
      createdAt: fitnessClass.createdAt,
      updatedAt: fitnessClass.updatedAt ?? null,
    });
  }

  private mapTrainerOverviewSlot(
    fitnessClass: any,
    slot: any,
  ): FitnessClassAvailabilitySlotResponseDto {
    const capacity =
      fitnessClass.sessionFormat === 'GROUP'
        ? (fitnessClass.maxMembers ?? 1)
        : 1;
    const bookings = slot.bookings ?? [];
    const bookedCount = bookings.filter((booking: any) =>
      [
        'CONFIRMED',
        'RESCHEDULE_REQUESTED',
        'RESCHEDULED',
        'COMPLETED',
      ].includes(booking.bookingStatus),
    ).length;
    const heldCount = bookings.filter(
      (booking: any) =>
        booking.bookingStatus === 'HELD' &&
        booking.reservedUntil &&
        booking.reservedUntil > new Date(),
    ).length;
    const occupiedCount = bookedCount + heldCount;
    const spotsRemaining = Math.max(capacity - occupiedCount, 0);

    return new FitnessClassAvailabilitySlotResponseDto({
      id: slot.id,
      date: slot.date,
      startTime: slot.startTime,
      endTime: slot.endTime,
      startAt: slot.startAt,
      endAt: slot.endAt,
      status: slot.status,
      availabilityStatus: spotsRemaining > 0 ? 'AVAILABLE' : 'BOOKED',
      isRescheduleProposal: slot.isRescheduleProposal ?? false,
      rescheduleStatus: slot.rescheduleStatus ?? null,
      bookedCount,
      heldCount,
      capacity,
      spotsRemaining,
    });
  }

  private mapTrainerOverviewReview(review: any): TrainerReviewResponseDto {
    return new TrainerReviewResponseDto({
      id: review.id,
      memberUserId: review.memberUserId,
      trainerUserId: review.trainerUserId,
      rating: review.rating,
      comment: review.comment,
      member: new TrainerReviewAuthorResponseDto({
        id: review.member.id,
        name: review.member.displayName ?? review.member.firstName ?? null,
        profileImageUrl: review.member.profileImageUrl ?? null,
      }),
      createdAt: review.createdAt,
      updatedAt: review.updatedAt ?? null,
    });
  }

  private calculateDistanceMeters(
    originLat: number,
    originLng: number,
    targetLat?: number | null,
    targetLng?: number | null,
  ): number | null {
    if (targetLat == null || targetLng == null) {
      return null;
    }

    const toRadians = (value: number) => (value * Math.PI) / 180;
    const earthRadiusMeters = 6371000;
    const dLat = toRadians(targetLat - originLat);
    const dLng = toRadians(targetLng - originLng);
    const lat1 = toRadians(originLat);
    const lat2 = toRadians(targetLat);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return Math.round(earthRadiusMeters * c);
  }
}
