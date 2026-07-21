import { adminApiFetch } from "@/lib/auth-api";

type AdminMemberRole = {
  id?: string;
  name: string;
  description?: string;
};

export type AdminMemberActivity = {
  type: string;
  title: string;
  description?: string;
  occurredAt: string;
  metadata?: Record<string, unknown>;
};

export type AdminMemberFitnessAssessment = {
  fitnessGoal?: string | null;
  hasPreviousFitnessExperience?: boolean | null;
  physicalLimitations?: string | null;
  supplements?: string[] | null;
  age?: number | string | null;
  weight?: number | string | null;
  weightUnit?: string | null;
  sleepQuality?: string | null;
  dietPreference?: string | null;
  calorieGoal?: number | string | null;
  calorieUnit?: string | null;
};

type AdminMemberApiItem = {
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
  status?: string | null;
  hasCompletedMemberFitnessAssessment?: boolean;
  memberFitnessAssessment?: AdminMemberFitnessAssessment | null;
  isActive?: boolean;
  createdAt: string;
  updatedAt?: string;
  roles?: AdminMemberRole[];
  recentActivity?: AdminMemberActivity[];
};

type AdminMembersResponse = {
  success: boolean;
  message: string;
  data: AdminMemberApiItem[];
  status: number;
};

type AdminMemberResponse = {
  success: boolean;
  message: string;
  data: AdminMemberApiItem;
  status: number;
};

export type AdminMember = {
  id: string;
  email: string;
  name: string;
  username?: string | null;
  phoneNumber?: string | null;
  profileImageUrl?: string | null;
  state?: string | null;
  location?: string | null;
  idCardType?: string | null;
  idCardNumber?: string | null;
  idCardFrontImageUrl?: string | null;
  idCardBackImageUrl?: string | null;
  verificationStatus?: string | null;
  hasCompletedMemberFitnessAssessment?: boolean;
  memberFitnessAssessment?: AdminMemberFitnessAssessment | null;
  isActive?: boolean;
  joined: string;
  createdAt?: string;
  status: string;
  roles?: AdminMemberRole[];
  recentActivity?: AdminMemberActivity[];
};

function formatMemberStatus(member: AdminMemberApiItem) {
  const status = member.status?.toUpperCase();
  const verificationStatus = member.verificationStatus?.toUpperCase();

  if (status === "ACTIVE") return "Active";
  if (status === "INACTIVE") return "Inactive";
  if (status === "SUSPENDED") return "Suspended";
  if (status === "PENDING") return "Pending";
  if (verificationStatus === "PENDING") return "Pending";
  if (verificationStatus === "REJECTED") return "Suspended";
  if (member.isActive === false) return "Inactive";

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

function getDisplayName(member: AdminMemberApiItem) {
  const fullName = [member.firstName, member.lastName].filter(Boolean).join(" ");

  return member.displayName || fullName || member.username || member.email;
}

function mapAdminMember(member: AdminMemberApiItem): AdminMember {
  return {
    id: member.id,
    email: member.email,
    name: getDisplayName(member),
    username: member.username,
    phoneNumber: member.phoneNumber,
    profileImageUrl: member.profileImageUrl,
    state: member.state,
    location: member.location,
    idCardType: member.idCardType,
    idCardNumber: member.idCardNumber,
    idCardFrontImageUrl: member.idCardFrontImageUrl,
    idCardBackImageUrl: member.idCardBackImageUrl,
    verificationStatus: member.verificationStatus,
    hasCompletedMemberFitnessAssessment:
      member.hasCompletedMemberFitnessAssessment,
    memberFitnessAssessment: member.memberFitnessAssessment,
    isActive: member.isActive,
    joined: formatJoinedDate(member.createdAt),
    createdAt: member.createdAt,
    status: formatMemberStatus(member),
    roles: member.roles,
    recentActivity: member.recentActivity ?? [],
  };
}

export async function fetchAdminMembers() {
  const response =
    await adminApiFetch<AdminMembersResponse>("/api/users/admin/members");

  return response.data.map(mapAdminMember);
}

export async function fetchAdminMember(userId: string) {
  const response = await adminApiFetch<AdminMemberResponse>(
    `/api/users/admin/members/${userId}`,
  );

  return mapAdminMember(response.data);
}
