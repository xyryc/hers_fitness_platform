import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/database/prisma.service';

@Injectable()
export class FaqRepository {
    constructor(private readonly prisma: PrismaService) {}

    // ─── Public ───────────────────────────────────────────────────────────────

    async findAllActive(): Promise<any[]> {
        return (this.prisma as any).faq.findMany({
            where: { isActive: true },
            orderBy: { order: 'asc' },
        });
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    /** All FAQs including inactive ones, ordered by display order. */
    async findAll(): Promise<any[]> {
        return (this.prisma as any).faq.findMany({ orderBy: { order: 'asc' } });
    }

    async findById(id: string): Promise<any | null> {
        return (this.prisma as any).faq.findUnique({ where: { id } });
    }

    async create(data: { question: string; answer: string; order: number; isActive: boolean }): Promise<any> {
        return (this.prisma as any).faq.create({ data });
    }

    async update(id: string, data: Partial<{ question: string; answer: string; order: number; isActive: boolean }>): Promise<any> {
        return (this.prisma as any).faq.update({ where: { id }, data });
    }

    async delete(id: string): Promise<void> {
        await (this.prisma as any).faq.delete({ where: { id } });
    }

    /** Bulk-updates the `order` field for each item in the list. */
    async reorder(items: { id: string; order: number }[]): Promise<void> {
        await (this.prisma as any).$transaction(
            items.map(({ id, order }) =>
                (this.prisma as any).faq.update({ where: { id }, data: { order } }),
            ),
        );
    }
}
