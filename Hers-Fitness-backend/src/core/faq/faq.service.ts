import { Injectable } from '@nestjs/common';
import { NotFoundAppException } from 'src/common/exceptions/not-found-error';
import { FaqRepository } from './domain/faq.repository';
import { FaqResponseDto } from './dto/faq-response.dto';
import { CreateFaqDto, ReorderFaqsDto, UpdateFaqDto } from './dto/admin-faq.dto';

@Injectable()
export class FaqService {
    constructor(private readonly faqRepository: FaqRepository) {}

    // ─── Public ───────────────────────────────────────────────────────────────

    async findAll(): Promise<FaqResponseDto[]> {
        const faqs = await this.faqRepository.findAllActive();
        return faqs.map((faq) => this.toDto(faq));
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    async adminFindAll(): Promise<FaqResponseDto[]> {
        const faqs = await this.faqRepository.findAll();
        return faqs.map((faq) => this.toDto(faq));
    }

    async adminCreate(dto: CreateFaqDto): Promise<FaqResponseDto> {
        const faq = await this.faqRepository.create({
            question: dto.question,
            answer: dto.answer,
            order: dto.order ?? 0,
            isActive: dto.isActive ?? true,
        });
        return this.toDto(faq);
    }

    async adminUpdate(id: string, dto: UpdateFaqDto): Promise<FaqResponseDto> {
        await this.findOrFail(id);
        const faq = await this.faqRepository.update(id, {
            ...(dto.question !== undefined && { question: dto.question }),
            ...(dto.answer   !== undefined && { answer:   dto.answer   }),
            ...(dto.order    !== undefined && { order:    dto.order    }),
            ...(dto.isActive !== undefined && { isActive: dto.isActive }),
        });
        return this.toDto(faq);
    }

    async adminDelete(id: string): Promise<void> {
        await this.findOrFail(id);
        await this.faqRepository.delete(id);
    }

    async adminReorder(dto: ReorderFaqsDto): Promise<void> {
        await this.faqRepository.reorder(dto.items);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private async findOrFail(id: string): Promise<any> {
        const faq = await this.faqRepository.findById(id);
        if (!faq) throw new NotFoundAppException('FAQ not found', 'FAQ_NOT_FOUND');
        return faq;
    }

    private toDto(faq: any): FaqResponseDto {
        return new FaqResponseDto({
            id: faq.id,
            question: faq.question,
            answer: faq.answer,
            order: faq.order,
            isActive: faq.isActive,
        });
    }
}
