import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AssetsService } from './assets.service';
import { JwtAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { CreateVehicleAssetDto } from './dtos/create-vehicle-asset.dto';
import { CreatePropertyAssetDto } from './dtos/create-property-asset.dto';

@Controller('assets')
@UseGuards(JwtAuthGuard)
export class AssetsController {
  constructor(private readonly assetsService: AssetsService) {}

  @Post('vehicles')
  async upsertVehicle(
    @Body() body: CreateVehicleAssetDto,
    @CurrentUser() user: any,
  ) {
    return this.assetsService.upsertVehicle(user.sub, body);
  }

  @Post('properties')
  async upsertProperty(
    @Body() body: CreatePropertyAssetDto,
    @CurrentUser() user: any,
  ) {
    return this.assetsService.upsertProperty(user.sub, body);
  }
}
