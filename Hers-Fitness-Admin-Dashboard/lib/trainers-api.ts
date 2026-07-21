import { adminApiFetch } from "@/lib/auth-api";
import type { AdminMemberActivity } from "@/lib/members-api";

type AdminTrainerRole = {
  id?: string;
  name: string;
  description?: string;
};

type AdminTrainerApiItem = {
  id: string;
  email: string;
  username?: string | null;
  firstName?: string | null;
  lastName?: string | null;
  displayName?: string | null;
  phoneNumber?: string | null;
  profileImageUrl?: string | null;
  state?: string | null;
  location?: string | null;
  idCardType?: string | null;
  idCardNumber?: string | null;
  idCardFrontImageUrl?: string | null;
  idCardBackImageUrl?: string | null;
  verificationStatus?: string | null;
  classesTaught?: string | null;
  instructorExperience?: string | number | null;
  certifications?: string | null;
  classDeliveryMode?: string | null;
  specialties?: string | null;
  classCount?: number | null;
  status?: string | null;
  rating?: number | string | null;
  isActive?: boolean;
  bio?: string | null;
  tagline?: string | null;
  createdAt: string;
  updatedAt?: string;
  roles?: AdminTrainerRole[];
  recentActivity?: AdminMemberActivity[];
};

type AdminTrainersResponse = {
  success: boolean;
  message: string;
  data: AdminTrainerApiItem[];
  status: number;
};

type AdminTrainerResponse = {
  success: boolean;
  message: string;
  data: AdminTrainerApiItem;
  status: number;
};

export type AdminTrainer = {
  id: string;
  email?: string;
  name: string;
  username?: string | null;
  user: string;
  phoneNumber?: string | null;
  profileImageUrl?: string | null;
  state?: string | null;
  location?: string | null;
  idCardType?: string | null;
  idCardNumber?: string | null;
  idCardFrontImageUrl?: string | null;
  idCardBackImageUrl?: string | null;
  verificationStatus?: string | null;
  classesTaught?: string | null;
  instructorExperience?: string | number | null;
  certifications?: string | null;
  classDeliveryMode?: string | null;
  bio?: string | null;
  tagline?: string | null;
  isActive?: boolean;
  joined?: string;
  createdAt?: string;
  status: string;
  specialty: string;
  classes: string;
  rating: string;
  roles?: AdminTrainerRole[];
  recentActivity?: AdminMemberActivity[];
};

function formatTrainerStatus(trainer: AdminTrainerApiItem) {
  const status = trainer.status?.toUpperCase();
  const verificationStatus = trainer.verificationStatus?.toUpperCase();

  if (verificationStatus === "PENDING") return "Pending";
  if (status === "ACTIVE") return "Active";
  if (status === "INACTIVE") return "Inactive";
  if (status === "SUSPENDED") return "Suspended";
  if (status === "PENDING") return "Pending";
  if (verificationStatus === "REJECTED") return "Suspended";
  if (trainer.isActive === false) return "Inactive";

  return "Active";
}

function formatJoinedDate(createdAt: string) {
  const date = new Date(createdAt);

  if (Number.isNaN(date.getTime())) return "-";

  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  }).format(date);
}

function getDisplayName(trainer: AdminTrainerApiItem) {
  const fullName = [trainer.firstName, trainer.lastName].filter(Boolean).join(" ");

  return trainer.displayName || fullName || trainer.username || trainer.email;
}

function emptyAsDash(value?: string | number | null) {
  return value === null || value === undefined || value === "" ? "-" : String(value);
}

function mapAdminTrainer(trainer: AdminTrainerApiItem): AdminTrainer {
  return {
    id: trainer.id,
    email: trainer.email,
    name: getDisplayName(trainer),
    username: trainer.username,
    user: trainer.username || trainer.email,
    phoneNumber: trainer.phoneNumber,
    profileImageUrl: trainer.profileImageUrl,
    state: trainer.state,
    location: trainer.location,
    idCardType: trainer.idCardType,
    idCardNumber: trainer.idCardNumber,
    idCardFrontImageUrl: trainer.idCardFrontImageUrl,
    idCardBackImageUrl: trainer.idCardBackImageUrl,
    verificationStatus: trainer.verificationStatus,
    classesTaught: trainer.classesTaught,
    instructorExperience: trainer.instructorExperience,
    certifications: trainer.certifications,
    classDeliveryMode: trainer.classDeliveryMode,
    bio: trainer.bio,
    tagline: trainer.tagline,
    isActive: trainer.isActive,
    joined: formatJoinedDate(trainer.createdAt),
    createdAt: trainer.createdAt,
    status: formatTrainerStatus(trainer),
    specialty: emptyAsDash(trainer.specialties ?? trainer.classesTaught),
    classes: emptyAsDash(trainer.classCount ?? trainer.classDeliveryMode),
    rating: emptyAsDash(trainer.rating ?? trainer.instructorExperience),
    roles: trainer.roles,
    recentActivity: trainer.recentActivity ?? [],
  };
}

export async function fetchAdminTrainers() {
  const response =
    await adminApiFetch<AdminTrainersResponse>("/api/users/admin/trainers");

  return response.data.map(mapAdminTrainer);
}

export async function fetchAdminTrainer(userId: string) {
  const response = await adminApiFetch<AdminTrainerResponse>(
    `/api/users/admin/trainers/${userId}`,
  );

  return mapAdminTrainer(response.data);
}
