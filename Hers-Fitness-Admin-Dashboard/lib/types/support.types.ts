export type TicketStatus = 'OPEN' | 'IN_REVIEW' | 'RESOLVED' | 'CLOSED';

export interface HelpTicketSender {
  id:               string;
  name?:            string | null;
  email:            string;
  profileImageUrl?: string | null;
  role?:            string | null;
}

export interface HelpTicket {
  id:         string;
  senderUserId?: string;
  status:     TicketStatus;
  subject:    string;
  message:    string;
  adminNote?: string | null;
  resolvedAt?: string | null;
  createdAt:  string;
  updatedAt:  string;
  sender?:    HelpTicketSender | null;
}
