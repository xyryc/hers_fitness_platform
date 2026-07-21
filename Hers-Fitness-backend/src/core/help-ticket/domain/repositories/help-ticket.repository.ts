import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';
import { CreateHelpTicketDto } from '../../dto/create-help-ticket.dto';
import { ResolveHelpTicketDto } from '../../dto/resolve-help-ticket.dto';

@Injectable()
export class HelpTicketRepository {
    constructor(private readonly prisma: PrismaService) {}

    async create(senderUserId: string, model: CreateHelpTicketDto) {
        return (this.prisma as any).helpTicket.create({
            data: {
                senderUserId,
                title: model.title.trim(),
                body: model.body.trim(),
            },
        });
    }

    async findBySender(senderUserId: string) {
        return (this.prisma as any).helpTicket.findMany({
            where: { senderUserId },
            orderBy: { createdAt: 'desc' },
        });
    }

    async findOneByIdAndSender(id: string, senderUserId: string) {
        return (this.prisma as any).helpTicket.findFirst({
            where: { id, senderUserId },
        });
    }

    async findById(id: string) {
        return (this.prisma as any).helpTicket.findUnique({
            where: { id },
            include: this.getSenderInclude(),
        });
    }

    async findAll(status?: string) {
        const query: Record<string, any> = {
            include: this.getSenderInclude(),
            orderBy: { createdAt: 'desc' },
        };

        if (status) {
            query.where = { status };
        }

        return (this.prisma as any).helpTicket.findMany(query);
    }

    async resolve(id: string, model: ResolveHelpTicketDto) {
        return (this.prisma as any).helpTicket.update({
            where: { id },
            data: {
                status: model.status,
                adminNote: model.adminNote?.trim() ?? null,
                resolvedAt: new Date(),
            },
        });
    }

    async markInReview(id: string) {
        return (this.prisma as any).helpTicket.update({
            where: { id },
            data: { status: 'IN_REVIEW' },
        });
    }

    private getSenderInclude() {
        return {
            sender: {
                select: {
                    id: true,
                    displayName: true,
                    firstName: true,
                    lastName: true,
                    email: true,
                    profileImageUrl: true,
                    roles: {
                        select: {
                            role: { select: { name: true } },
                        },
                    },
                },
            },
        };
    }
}
