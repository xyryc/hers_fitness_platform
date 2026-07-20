import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { FaqService } from './faq.service';
import { FaqResponseDto } from './dto/faq-response.dto';
import { CreateFaqDto, ReorderFaqsDto, UpdateFaqDto } from './dto/admin-faq.dto';

// ─── Public ───────────────────────────────────────────────────────────────────

@ApiTags('5. Public')
@Controller('faqs')
export class FaqController {
    constructor(private readonly faqService: FaqService) {}

    @Get()
    @ApiOperation({ summary: 'Public: list all active FAQs ordered by display order' })
    async findAll(): Promise<CustomResponse<FaqResponseDto[]>> {
        const faqs = await this.faqService.findAll();
        return new CustomResponse<FaqResponseDto[]>('FAQs fetched successfully', faqs, 200);
    }
}

// ─── Admin ────────────────────────────────────────────────────────────────────

@ApiTags('6. Admin Dashboard')
@ApiBearerAuth('access-token')
@Controller('admin/faqs')
@UseGuards(AuthGuard, RolesGuard)
@AllowedRoles(Roles.Admin)
export class AdminFaqController {
    constructor(private readonly faqService: FaqService) {}

    @Get()
    @ApiOperation({ summary: 'Admin: list all FAQs including inactive ones' })
    async findAll(): Promise<CustomResponse<FaqResponseDto[]>> {
        const faqs = await this.faqService.adminFindAll();
        return new CustomResponse<FaqResponseDto[]>('FAQs fetched successfully', faqs, 200);
    }

    @Post()
    @HttpCode(201)
    @ApiOperation({ summary: 'Admin: create a new FAQ' })
    async create(@Body() dto: CreateFaqDto): Promise<CustomResponse<FaqResponseDto>> {
        const faq = await this.faqService.adminCreate(dto);
        return new CustomResponse<FaqResponseDto>('FAQ created successfully', faq, 201);
    }

    @Patch('reorder')
    @ApiOperation({ summary: 'Admin: bulk-update display order for multiple FAQs in one request' })
    async reorder(@Body() dto: ReorderFaqsDto): Promise<CustomResponse<null>> {
        await this.faqService.adminReorder(dto);
        return new CustomResponse<null>('FAQs reordered successfully', null, 200);
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Admin: update a FAQ (question, answer, order, isActive)' })
    async update(
        @Param('id') id: string,
        @Body() dto: UpdateFaqDto,
    ): Promise<CustomResponse<FaqResponseDto>> {
        const faq = await this.faqService.adminUpdate(id, dto);
        return new CustomResponse<FaqResponseDto>('FAQ updated successfully', faq, 200);
    }

    @Delete(':id')
    @HttpCode(200)
    @ApiOperation({ summary: 'Admin: permanently delete a FAQ' })
    async delete(@Param('id') id: string): Promise<CustomResponse<null>> {
        await this.faqService.adminDelete(id);
        return new CustomResponse<null>('FAQ deleted successfully', null, 200);
    }
}
