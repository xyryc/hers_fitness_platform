import { Body, Controller, Get, HttpCode, Param, Post, Request, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { ApprovedAccountGuard } from '../../auth/guards/approved-account.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { HelpTicketService } from '../../help-ticket/help-ticket.service';
import { CreateHelpTicketDto } from '../../help-ticket/dto/create-help-ticket.dto';
import { HelpTicketResponseDto } from '../../help-ticket/dto/help-ticket-response.dto';

@ApiTags('7. Help Tickets')
@ApiBearerAuth('access-token')
@Controller('help-tickets')
@UseGuards(AuthGuard, ApprovedAccountGuard)
export class TrainerHelpTicketController {
    constructor(private readonly helpTicketService: HelpTicketService) {}

    @Post()
    @HttpCode(201)
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: Submit a help ticket to admin' })
    async submitTicket(
        @Body() model: CreateHelpTicketDto,
        @Request() req,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.submitTicket(req.user.currentUserId, model);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket submitted successfully', ticket, 201);
    }

    @Get('my')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: List own submitted help tickets' })
    async getMyTickets(@Request() req): Promise<CustomResponse<HelpTicketResponseDto[]>> {
        const tickets = await this.helpTicketService.getMyTickets(req.user.currentUserId);
        return new CustomResponse<HelpTicketResponseDto[]>('Help tickets fetched successfully', tickets, 200);
    }

    @Get('my/:ticketId')
    @UseGuards(RolesGuard)
    @AllowedRoles(Roles.Trainer)
    @ApiOperation({ summary: 'Trainer: Get a specific own help ticket by ID' })
    async getMyTicketById(
        @Param('ticketId') ticketId: string,
        @Request() req,
    ): Promise<CustomResponse<HelpTicketResponseDto>> {
        const ticket = await this.helpTicketService.getMyTicketById(req.user.currentUserId, ticketId);
        return new CustomResponse<HelpTicketResponseDto>('Help ticket fetched successfully', ticket, 200);
    }
}
