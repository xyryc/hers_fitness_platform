import {
  Body,
  Controller,
  Delete,
  Post,
  Put,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { RolesGuard } from '../../auth/guards/roles.guard';
import { LocationService } from '../../location/location.service';
import {
  TrainerLocationStateResponseDto,
} from '../../location/dto/location-response.dto';
import {
  TrainerBaseLocationDto,
  TrainerLiveLocationDto,
  TrainerOnlineStatusDto,
} from '../dto/trainer-location.dto';

@ApiBearerAuth()
@Controller()
export class TrainerLocationController {
  constructor(private readonly locationService: LocationService) {}

  @ApiTags('2. Trainer App')
  @Post('location/trainer/base')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Trainer)
  @ApiOperation({ summary: 'Set trainer base location' })
  async setTrainerBaseLocation(
    @Body() model: TrainerBaseLocationDto,
    @Request() req,
  ) {
    const data = await this.locationService.setTrainerBaseLocation(
      req.user.currentUserId,
      model,
    );
    return new CustomResponse<TrainerLocationStateResponseDto>(
      'Trainer base location saved successfully',
      data,
      200,
    );
  }

  @ApiTags('2. Trainer App')
  @Put('location/trainer/live')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Trainer)
  @ApiOperation({ summary: 'Update trainer live location' })
  async updateTrainerLiveLocation(
    @Body() model: TrainerLiveLocationDto,
    @Request() req,
  ) {
    const data = await this.locationService.updateTrainerLiveLocation(
      req.user.currentUserId,
      model,
    );
    return new CustomResponse<TrainerLocationStateResponseDto>(
      'Trainer live location updated successfully',
      data,
      200,
    );
  }

  @ApiTags('2. Trainer App')
  @Delete('location/trainer/live')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Trainer)
  @ApiOperation({ summary: 'Clear trainer live location' })
  async clearTrainerLiveLocation(@Request() req) {
    const data = await this.locationService.clearTrainerLiveLocation(
      req.user.currentUserId,
    );
    return new CustomResponse<TrainerLocationStateResponseDto>(
      'Trainer live location cleared successfully',
      data,
      200,
    );
  }

  @ApiTags('2. Trainer App')
  @Put('location/trainer/status')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Trainer)
  @ApiOperation({ summary: 'Update trainer online status' })
  async updateTrainerStatus(
    @Body() model: TrainerOnlineStatusDto,
    @Request() req,
  ) {
    const data = await this.locationService.updateTrainerStatus(
      req.user.currentUserId,
      model,
    );
    return new CustomResponse<TrainerLocationStateResponseDto>(
      'Trainer status updated successfully',
      data,
      200,
    );
  }
}
