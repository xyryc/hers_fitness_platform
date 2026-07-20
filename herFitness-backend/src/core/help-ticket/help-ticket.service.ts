import { Injectable } from '@nestjs/common';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { NotificationService, NotificationType } from '../notification/notification.service';
import { HelpTicketRepository } from './domain/repositories/help-ticket.repository';
import { CreateHelpTicketDto } from './dto/create-help-ticket.dto';
import { ResolveHelpTicketDto } from './dto/resolve-help-ticket.dto';
import { HelpTicketResponseDto, HelpTicketSenderResponseDto } from './dto/help-ticket-response.dto';

@Injectable()
export class HelpTicketService {
    constructor(
        private readonly helpTicketRepository: HelpTicketRepository,
        private readonly notificationService: NotificationService,
    ) {}

    // ─── Member / Trainer ──────────────────────────────────────────────────────

    async submitTicket(senderUserId: string, model: CreateHelpTicketDto): Promise<HelpTicketResponseDto> {
        const ticket = await this.helpTicketRepository.create(senderUserId, model);
        return this.mapTicket(ticket);
    }

    async getMyTickets(senderUserId: string): Promise<HelpTicketResponseDto[]> {
        const tickets = await this.helpTicketRepository.findBySender(senderUserId);
        return tickets.map((t: any) => this.mapTicket(t));
    }

    async getMyTicketById(senderUserId: string, ticketId: string): Promise<HelpTicketResponseDto> {
        const ticket = await this.helpTicketRepository.findOneByIdAndSender(ticketId, senderUserId);
        if (!ticket) {
            throw new NotFoundAppException('Help ticket not found.', 'HELP_TICKET_NOT_FOUND');
        }
        return this.mapTicket(ticket);
    }

    // ─── Admin ─────────────────────────────────────────────────────────────────

    async getAllTickets(status?: string): Promise<HelpTicketResponseDto[]> {
        const tickets = await this.helpTicketRepository.findAll(status);
        return tickets.map((t: any) => this.mapTicket(t, true));
    }

    async getTicketById(ticketId: string): Promise<HelpTicketResponseDto> {
        const ticket = await this.helpTicketRepository.findById(ticketId);
        if (!ticket) {
            throw new NotFoundAppException('Help ticket not found.', 'HELP_TICKET_NOT_FOUND');
        }
        return this.mapTicket(ticket, true);
    }

    async resolveTicket(ticketId: string, model: ResolveHelpTicketDto): Promise<HelpTicketResponseDto> {
        const existing = await this.helpTicketRepository.findById(ticketId);
        if (!existing) {
            throw new NotFoundAppException('Help ticket not found.', 'HELP_TICKET_NOT_FOUND');
        }

        const ticket = await this.helpTicketRepository.resolve(ticketId, model);

        // Notify the user that their ticket has been resolved
        await this.notificationService.notifyUser({
            userId: existing.senderUserId,
            type: NotificationType.HELP_TICKET_RESOLVED,
            title: 'Your support ticket has been resolved',
            body: model.adminNote
                ? `Admin replied: ${model.adminNote.slice(0, 100)}${model.adminNote.length > 100 ? '...' : ''}`
                : 'Your help ticket has been marked as resolved.',
            data: { ticketId },
        });

        return this.mapTicket(ticket);
    }

    async markTicketInReview(ticketId: string): Promise<HelpTicketResponseDto> {
        const existing = await this.helpTicketRepository.findById(ticketId);
        if (!existing) {
            throw new NotFoundAppException('Help ticket not found.', 'HELP_TICKET_NOT_FOUND');
        }
        const ticket = await this.helpTicketRepository.markInReview(ticketId);
        return this.mapTicket(ticket);
    }

    // ─── Mapper ────────────────────────────────────────────────────────────────

    private mapTicket(ticket: any, includeSender = false): HelpTicketResponseDto {
        return new HelpTicketResponseDto({
            id: ticket.id,
            senderUserId: ticket.senderUserId,
            title: ticket.title,
            body: ticket.body,
            status: ticket.status,
            adminNote: ticket.adminNote ?? null,
            resolvedAt: ticket.resolvedAt ?? null,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt ?? null,
            sender: includeSender && ticket.sender
                ? this.mapSender(ticket.sender)
                : undefined,
        });
    }

    private mapSender(sender: any): HelpTicketSenderResponseDto {
        const roleName = sender.roles?.[0]?.role?.name ?? null;
        return new HelpTicketSenderResponseDto({
            id: sender.id,
            name: sender.displayName ?? sender.firstName ?? null,
            email: sender.email ?? null,
            profileImageUrl: sender.profileImageUrl ?? null,
            role: roleName,
        });
    }
}
