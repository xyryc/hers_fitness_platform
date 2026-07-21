import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
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
  MemberLocationStateResponseDto,
  TrainerOverviewResponseDto,
  TrainerProfileResponseDto,
  TrainerSearchResponseDto,
} from '../../location/dto/location-response.dto';
import {
  MemberCurrentLocationDto,
} from '../dto/member-location.dto';
import {
  NearbyTrainersQueryDto,
  SearchTrainersQueryDto,
  TrainerProfileDistanceQueryDto,
} from '../dto/trainer-discovery-query.dto';

@ApiBearerAuth()
@Controller()
export class MemberLocationController {
  constructor(private readonly locationService: LocationService) {}

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
