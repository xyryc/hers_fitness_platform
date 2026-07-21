import { Injectable } from '@nestjs/common';
import { Prisma } from 'prisma/generated/prisma/client';
import { PrismaService } from 'src/database/prisma.service';
import { SearchTrainersQueryDto } from '../../dto/trainer-discovery-query.dto';

@Injectable()
export class LocationRepository {
  constructor(private readonly prisma: PrismaService) {}

  async updateTrainerBaseLocation(userId: string, lat: number, lng: number, timezone?: string | null) {
    const rows = await this.prisma.$transaction(async (tx: any) => {
      if (timezone) {
        await tx.user.update({
          where: { id: userId },
          data: { timezone },
        });
      }

      return tx.trainerProfile.updateManyAndReturn({
        where: { userId },
        data: {
          baseLocationLat: lat,
          baseLocationLng: lng,
        },
      });
    });

    return rows[0] ?? null;
  }

  async updateTrainerLiveLocation(userId: string, lat: number, lng: number, timezone?: string | null) {
    const rows = await this.prisma.$transaction(async (tx: any) => {
      if (timezone) {
        await tx.user.update({
          where: { id: userId },
          data: { timezone },
        });
      }

      return tx.trainerProfile.updateManyAndReturn({
        where: { userId },
        data: {
          liveLocationLat: lat,
          liveLocationLng: lng,
        },
      });
    });

    return rows[0] ?? null;
  }

  async clearTrainerLiveLocation(userId: string) {
    const rows = await (this.prisma as any).trainerProfile.updateManyAndReturn({
      where: { userId },
      data: {
        liveLocationLat: null,
        liveLocationLng: null,
        isOnline: false,
      },
    });

    return rows[0] ?? null;
  }

  async updateTrainerOnlineStatus(userId: string, isOnline: boolean) {
    const rows = await (this.prisma as any).trainerProfile.updateManyAndReturn({
      where: { userId },
      data: {
        isOnline,
        lastSeen: new Date(),
      },
    });

    return rows[0] ?? null;
  }

  async updateMemberCurrentLocation(userId: string, lat: number, lng: number, timezone?: string | null) {
    return (this.prisma as any).user.update({
      where: { id: userId },
      data: {
        currentLat: lat,
        currentLng: lng,
        ...(timezone ? { timezone } : {}),
        locationUpdatedAt: new Date(),
      },
    });
  }

  async findNearbyTrainers(lat: number, lng: number, radiusKm: number) {
    const radiusMeters = radiusKm * 1000;

    return this.prisma.$queryRaw<any[]>(Prisma.sql`
            SELECT
                u.id,
                COALESCE(u.display_name, u.first_name) AS name,
                u.profile_image_url AS "profileImageUrl",
                tp.bio,
                tp.classes_taught AS "classesTaught",
                tp.certifications,
                tp.class_delivery_mode AS "classDeliveryMode",
                tp.is_online AS "isOnline",
                tp.last_seen AS "lastSeen",
                MIN(fc.price_per_member)::text AS "startingPrice",
                AVG(tr.rating) AS "averageRating",
                COUNT(DISTINCT tr.id) AS "reviewCount",
                CASE
                    WHEN tp.is_online = true
                        AND tp.live_location_lat IS NOT NULL
                        AND tp.live_location_lng IS NOT NULL
                    THEN ST_DistanceSphere(
                        ST_MakePoint(tp.live_location_lng, tp.live_location_lat),
                        ST_MakePoint(${lng}, ${lat})
                    )
                    ELSE ST_DistanceSphere(
                        ST_MakePoint(tp.base_location_lng, tp.base_location_lat),
                        ST_MakePoint(${lng}, ${lat})
                    )
                END AS "distanceMeters",
                CASE
                    WHEN tp.is_online = true
                        AND tp.live_location_lat IS NOT NULL
                        AND tp.live_location_lng IS NOT NULL
                    THEN 'Active Now'
                    ELSE 'Based Nearby'
                END AS "locationLabel"
            FROM users u
            INNER JOIN trainer_profiles tp ON tp.user_id = u.id
            INNER JOIN user_roles ur ON ur.user_id = u.id
            INNER JOIN roles r ON r.id = ur.role_id AND r.name = 'TRAINER'
            LEFT JOIN user_verifications uv ON uv.user_id = u.id
            LEFT JOIN fitness_classes fc
                ON fc.trainer_user_id = u.id
                AND fc.status = 'ACTIVE'
            LEFT JOIN trainer_reviews tr
                ON tr.trainer_user_id = u.id
            WHERE u.is_active = true
              AND (uv.verification_status = 'APPROVED' OR uv.verification_status IS NULL)
              AND tp.base_location_lat <> 0
              AND tp.base_location_lng <> 0
              AND CASE
                    WHEN tp.is_online = true
                        AND tp.live_location_lat IS NOT NULL
                        AND tp.live_location_lng IS NOT NULL
                    THEN ST_DistanceSphere(
                        ST_MakePoint(tp.live_location_lng, tp.live_location_lat),
                        ST_MakePoint(${lng}, ${lat})
                    )
                    ELSE ST_DistanceSphere(
                        ST_MakePoint(tp.base_location_lng, tp.base_location_lat),
                        ST_MakePoint(${lng}, ${lat})
                    )
                END <= ${radiusMeters}
            GROUP BY
                u.id,
                u.display_name,
                u.first_name,
                u.profile_image_url,
                tp.bio,
                tp.classes_taught,
                tp.certifications,
                tp.class_delivery_mode,
                tp.is_online,
                tp.last_seen,
                tp.live_location_lat,
                tp.live_location_lng,
                tp.base_location_lat,
                tp.base_location_lng
            ORDER BY "distanceMeters" ASC
        `);
  }

  async searchTrainers(model: SearchTrainersQueryDto) {
    const conditions: Prisma.Sql[] = [
      Prisma.sql`u.is_active = true`,
      Prisma.sql`(uv.verification_status = 'APPROVED' OR uv.verification_status IS NULL)`,
    ];

    if (model.name) {
      conditions.push(
        Prisma.sql`(COALESCE(u.display_name, u.first_name) ILIKE ${`%${model.name}%`})`,
      );
    }

    if (model.specialty) {
      conditions.push(
        Prisma.sql`(tp.classes_taught ILIKE ${`%${model.specialty}%`})`,
      );
    }

    if (model.priceMin !== undefined) {
      conditions.push(
        Prisma.sql`EXISTS (
                    SELECT 1
                    FROM fitness_classes fc_min
                    WHERE fc_min.trainer_user_id = u.id
                      AND fc_min.status = 'ACTIVE'
                      AND fc_min.price_per_member >= ${model.priceMin}
                )`,
      );
    }

    if (model.priceMax !== undefined) {
      conditions.push(
        Prisma.sql`EXISTS (
                    SELECT 1
                    FROM fitness_classes fc_max
                    WHERE fc_max.trainer_user_id = u.id
                      AND fc_max.status = 'ACTIVE'
                      AND fc_max.price_per_member <= ${model.priceMax}
                )`,
      );
    }

    const whereClause = conditions.length
      ? Prisma.sql`WHERE ${Prisma.join(conditions, ' AND ')}`
      : Prisma.empty;

    return this.prisma.$queryRaw<any[]>(Prisma.sql`
            SELECT
                u.id,
                COALESCE(u.display_name, u.first_name) AS name,
                u.profile_image_url AS "profileImageUrl",
                tp.bio,
                tp.classes_taught AS "classesTaught",
                tp.certifications,
                tp.class_delivery_mode AS "classDeliveryMode",
                tp.is_online AS "isOnline",
                tp.last_seen AS "lastSeen",
                MIN(fc.price_per_member)::text AS "startingPrice",
                AVG(tr.rating) AS "averageRating",
                COUNT(DISTINCT tr.id) AS "reviewCount"
            FROM users u
            INNER JOIN trainer_profiles tp ON tp.user_id = u.id
            INNER JOIN user_roles ur ON ur.user_id = u.id
            INNER JOIN roles r ON r.id = ur.role_id AND r.name = 'TRAINER'
            LEFT JOIN user_verifications uv ON uv.user_id = u.id
            LEFT JOIN fitness_classes fc
                ON fc.trainer_user_id = u.id
                AND fc.status = 'ACTIVE'
            LEFT JOIN trainer_reviews tr
                ON tr.trainer_user_id = u.id
            ${whereClause}
            GROUP BY
                u.id,
                u.display_name,
                u.first_name,
                u.profile_image_url,
                tp.bio,
                tp.classes_taught,
                tp.certifications,
                tp.class_delivery_mode,
                tp.is_online,
                tp.last_seen
            ORDER BY name ASC
        `);
  }

  async findTrainerProfileById(id: string) {
    return (this.prisma as any).user.findFirst({
      where: {
        id,
        isActive: true,
        roles: {
          some: {
            role: {
              name: 'TRAINER',
            },
          },
        },
      },
      include: {
        verification: true,
        trainerProfile: true,
        createdClasses: {
          where: {
            status: 'ACTIVE',
          },
          orderBy: {
            scheduledAt: 'asc',
          },
        },
        trainerReviews: {
          select: {
            id: true,
            rating: true,
          },
        },
        trainerBookings: {
          where: {
            bookingStatus: {
              in: [
                'CONFIRMED',
                'RESCHEDULE_REQUESTED',
                'RESCHEDULED',
                'COMPLETED',
              ],
            },
          },
          select: {
            memberUserId: true,
          },
        },
      } as any,
    } as any);
  }

  async findTrainerOverviewById(id: string) {
    const now = new Date();

    const [trainer, reviewAggregate] = await Promise.all([
      (this.prisma as any).user.findFirst({
        where: {
          id,
          isActive: true,
          roles: {
            some: {
              role: {
                name: 'TRAINER',
              },
            },
          },
        },
        include: {
          verification: true,
          trainerProfile: true,
          createdClasses: {
            where: {
              status: 'ACTIVE',
              availabilitySlots: {
                some: {
                  status: 'AVAILABLE',
                  startAt: {
                    gte: now,
                  },
                  isRescheduleProposal: false,
                },
              },
            },
            include: {
              availabilitySlots: {
                where: {
                  status: 'AVAILABLE',
                  startAt: {
                    gte: now,
                  },
                  isRescheduleProposal: false,
                },
                include: {
                  bookings: {
                    where: {
                      OR: [
                        {
                          bookingStatus: {
                            in: [
                              'CONFIRMED',
                              'RESCHEDULE_REQUESTED',
                              'RESCHEDULED',
                              'COMPLETED',
                            ],
                          },
                        },
                        {
                          bookingStatus: 'HELD',
                          reservedUntil: {
                            gt: now,
                          },
                        },
                      ],
                    },
                    select: {
                      memberUserId: true,
                      bookingStatus: true,
                      paymentStatus: true,
                      reservedUntil: true,
                    },
                  },
                },
                orderBy: {
                  startAt: 'asc',
                },
              },
              bookings: {
                where: {
                  bookingStatus: {
                    in: [
                      'CONFIRMED',
                      'RESCHEDULE_REQUESTED',
                      'RESCHEDULED',
                      'COMPLETED',
                    ],
                  },
                  paymentStatus: 'PAID',
                },
                select: {
                  memberUserId: true,
                },
              },
            },
            orderBy: {
              createdAt: 'desc',
            },
          },
          trainerReviews: {
            include: {
              member: {
                select: {
                  id: true,
                  displayName: true,
                  firstName: true,
                  profileImageUrl: true,
                },
              },
            },
            orderBy: {
              createdAt: 'desc',
            },
            take: 3,
          },
          trainerBookings: {
            where: {
              bookingStatus: {
                in: [
                  'CONFIRMED',
                  'RESCHEDULE_REQUESTED',
                  'RESCHEDULED',
                  'COMPLETED',
                ],
              },
            },
            select: {
              memberUserId: true,
            },
          },
          _count: {
            select: {
              trainerReviews: true,
            },
          },
        } as any,
      } as any),
      (this.prisma as any).trainerReview.aggregate({
        where: {
          trainerUserId: id,
        },
        _avg: {
          rating: true,
        },
      }),
    ]);

    if (!trainer) return null;

    return {
      ...trainer,
      reviewAverageRating: reviewAggregate._avg.rating,
    };
  }
}
