export interface RevenueStats {
  totalGrossRevenue:     string;
  totalPlatformFee:      string;
  totalTrainerPayout:    string;
  currentCommissionRate: string;
  totalPaidBookings:     number;
  activeTrainerCount:    number;
}

export type EarningsPeriod = 'weekly' | 'monthly' | 'yearly';

export interface EarningsDataPoint {
  label:         string;
  key:           string;
  grossRevenue:  number;
  platformFee:   number;
  trainerPayout: number;
}

export interface RevenueEarnings {
  period:             EarningsPeriod;
  data:               EarningsDataPoint[];
  totalGrossRevenue:  number;
  totalPlatformFee:   number;
  totalTrainerPayout: number;
  weekStartDate?:     string; // weekly only
  weekEndDate?:       string; // weekly only
  year?:              number; // monthly only
}

export interface TrainerRevenueItem {
  trainerUserId:      string;
  trainerName:        string | null;
  profileImageUrl:    string | null;
  totalGrossRevenue:  string;
  totalPlatformFee:   string;
  totalTrainerPayout: string;
  totalBookings:      number;
}

export interface TrainerRevenueList {
  items:  TrainerRevenueItem[];
  total:  number;
  limit:  number;
  offset: number;
}

export interface CommissionConfig {
  id:              string;
  commissionRate:  string;
  updatedByUserId: string | null;
  updatedAt:       string | null;
  createdAt:       string;
}
