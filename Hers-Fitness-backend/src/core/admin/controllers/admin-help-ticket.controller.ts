import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { HelpTicketService } from '../../help-ticket/help-ticket.service';
import { ResolveHelpTicketDto } from '../dto/resolve-help-ticket.dto';
import { HelpTicketResponseDto } from '../../help-ticket/dto/help-ticket-response.dto';

@ApiTags('7. Help Tickets')
@ApiBearerAuth('access-token')
@Controller('help-tickets')
@UseGuards(AuthGuard, RolesGuard)
@AllowedRoles(Roles.Admin)
export class AdminHelpTicketController {
    constructor(private readonly helpTicketService: HelpTicketService) {}

    @Get()
    @ApiOperation({ summary: 'Admin: List all help tickets (optionally filter by status)' })
    @ApiQuery({ name: 'status', required: false, enum: ['OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'] })
    async getAllTickets(
        @Query('status') status?: string,
    ): Promise<CustomResponse<HelpTicketResponseDto[]>> {
        const tickets = await this.helpTicketService.getAllTickets(status);
        return new CustomResponse<HelpTicketResponseDto[]>('Help tickets fetched successfully', tickets, 200);
    }

    @Get(':ticketId')
    @ApiOperation({ summary: 'Admin: Get any help ticket by ID' })
    async getTicketById(
        @Param('ticketId') ticketId: string,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.getTicketById(ticketId);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket fetched successfully', ticket, 200);
    }

    @Patch(':ticketId/review')
    @ApiOperation({ summary: 'Admin: Mark a help ticket as IN_REVIEW' })
    async markInReview(
        @Param('ticketId') ticketId: string,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.markTicketInReview(ticketId);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket marked as in-review', ticket, 200);
    }

    @Patch(':ticketId/resolve')
    @ApiOperation({ summary: 'Admin: Resolve or close a help ticket' })
    async resolveTicket(
        @Param('ticketId') ticketId: string,
        @Body() model: ResolveHelpTicketDto,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.resolveTicket(ticketId, model);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket resolved successfully', ticket, 200);
    }
}
