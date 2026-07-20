import { Body, Controller, Get, HttpCode, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../auth/guards/auth.guard';
import { ApprovedAccountGuard } from '../auth/guards/approved-account.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { HelpTicketService } from './help-ticket.service';
import { CreateHelpTicketDto } from './dto/create-help-ticket.dto';
import { ResolveHelpTicketDto } from './dto/resolve-help-ticket.dto';
import { HelpTicketResponseDto } from './dto/help-ticket-response.dto';

@ApiTags('7. Help Tickets')
@ApiBearerAuth('access-token')
@Controller('help-tickets')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class HelpTicketController {
    constructor(private readonly helpTicketService: HelpTicketService) {}

    // ─── Member / Trainer endpoints ────────────────────────────────────────────

    @Post()
    @HttpCode(201)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member, Roles.Trainer)
    @ApiOperation({ summary: 'Member / Trainer: Submit a help ticket to admin' })
    async submitTicket(
        @Body() model: CreateHelpTicketDto,
        @Request() req,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.submitTicket(req.user.currentUserId, model);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket submitted successfully', ticket, 201);
    }

    @Get('my')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member, Roles.Trainer)
    @ApiOperation({ summary: 'Member / Trainer: List own submitted help tickets' })
    async getMyTickets(@Request() req): Promise<CustomResponse<HelpTicketResponseDto[]>> {
        const tickets = await this.helpTicketService.getMyTickets(req.user.currentUserId);
        return new CustomResponse<HelpTicketResponseDto[]>('Help tickets fetched successfully', tickets, 200);
    }

    @Get('my/:ticketId')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Member, Roles.Trainer)
    @ApiOperation({ summary: 'Member / Trainer: Get a specific own help ticket by ID' })
    async getMyTicketById(
        @Param('ticketId') ticketId: string,
        @Request() req,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.getMyTicketById(req.user.currentUserId, ticketId);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket fetched successfully', ticket, 200);
    }

    // ─── Admin endpoints ───────────────────────────────────────────────────────

    @Get()
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: List all help tickets (optionally filter by status)' })
    @ApiQuery({ name: 'status', required: false, enum: ['OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'] })
    async getAllTickets(
        @Query('status') status?: string,
    ): Promise<CustomResponse<HelpTicketResponseDto[]>> {
        const tickets = await this.helpTicketService.getAllTickets(status);
        return new CustomResponse<HelpTicketResponseDto[]>('Help tickets fetched successfully', tickets, 200);
    }

    @Get(':ticketId')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: Get any help ticket by ID' })
    async getTicketById(
        @Param('ticketId') ticketId: string,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.getTicketById(ticketId);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket fetched successfully', ticket, 200);
    }

    @Patch(':ticketId/review')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: Mark a help ticket as IN_REVIEW' })
    async markInReview(
        @Param('ticketId') ticketId: string,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.markTicketInReview(ticketId);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket marked as in-review', ticket, 200);
    }

    @Patch(':ticketId/resolve')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Admin)
    @ApiOperation({ summary: 'Admin: Resolve or close a help ticket' })
    async resolveTicket(
        @Param('ticketId') ticketId: string,
        @Body() model: ResolveHelpTicketDto,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.resolveTicket(ticketId, model);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket resolved successfully', ticket, 200);
    }
}
