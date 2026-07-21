import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import CustomResponse from 'src/common/dto/custom-response.dto';
import { AllowedRoles } from 'src/common/decorators/roles.decorator';
import { Roles } from 'src/common/enums/roles.enum';
import { AuthGuard } from '../auth/guards/auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { LocationService } from './location.service';
import {
  MemberLocationStateResponseDto,
  TrainerLocationStateResponseDto,
  TrainerOverviewResponseDto,
  TrainerProfileResponseDto,
  TrainerSearchResponseDto,
} from './dto/location-response.dto';
import {
  MemberCurrentLocationDto,
  TrainerBaseLocationDto,
  TrainerLiveLocationDto,
  TrainerOnlineStatusDto,
} from './dto/trainer-location.dto';
import {
  NearbyTrainersQueryDto,
  SearchTrainersQueryDto,
  TrainerProfileDistanceQueryDto,
} from './dto/trainer-discovery-query.dto';

@ApiBearerAuth()
@Controller()
export class LocationController {
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

  @ApiTags('1. Member App')
  @Post('location/member')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Member)
  @ApiOperation({ summary: 'Save member current location' })
  async updateMemberLocation(
    @Body() model: MemberCurrentLocationDto,
    @Request() req,
  ) {
    const data = await this.locationService.updateMemberLocation(
      req.user.currentUserId,
      model,
    );
    return new CustomResponse<MemberLocationStateResponseDto>(
      'Member location updated successfully',
      data,
      200,
    );
  }

  @ApiTags('4. Discovery')
  @Get('trainers/nearby')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Member)
  @ApiOperation({ summary: 'Find nearby trainers' })
  async findNearbyTrainers(@Query() query: NearbyTrainersQueryDto) {
    const data = await this.locationService.findNearbyTrainers(query);
    return new CustomResponse<TrainerSearchResponseDto[]>(
      'Nearby trainers fetched successfully',
      data,
      200,
    );
  }

  @ApiTags('4. Discovery')
  @Get('trainers/search')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Member)
  @ApiOperation({ summary: 'Search trainers by filters' })
  async searchTrainers(@Query() query: SearchTrainersQueryDto) {
    const data = await this.locationService.searchTrainers(query);
    return new CustomResponse<TrainerSearchResponseDto[]>(
      'Trainers fetched successfully',
      data,
      200,
    );
  }

  @ApiTags('4. Discovery')
  @Get('trainers/:id/overview')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Member)
  @ApiOperation({
    summary: 'Member: get trainer overview with classes, reviews, and location',
  })
  async findTrainerOverview(
    @Param('id') id: string,
    @Query() query: TrainerProfileDistanceQueryDto,
  ) {
    const data = await this.locationService.findTrainerOverview(id, query);
    return new CustomResponse<TrainerOverviewResponseDto>(
      'Trainer overview fetched successfully',
      data,
      200,
    );
  }

  @ApiTags('4. Discovery')
  @Get('trainers/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @AllowedRoles(Roles.Member)
  @ApiOperation({ summary: 'Get a trainer profile' })
  async findTrainerProfile(
    @Param('id') id: string,
    @Query() query: TrainerProfileDistanceQueryDto,
  ) {
    const data = await this.locationService.findTrainerProfile(id, query);
    return new CustomResponse<TrainerProfileResponseDto>(
      'Trainer profile fetched successfully',
      data,
      200,
    );
  }
}
