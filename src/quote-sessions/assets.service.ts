import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { VehicleAsset } from './entities/vehicle-asset.entity';
import { PropertyAsset } from './entities/property-asset.entity';
import { QuoteSession } from './entities/quote-session.entity';
import { QuoteSessionAssetSnapshot } from './entities/quote-session-asset-snapshot.entity';
import { AccessTokenPayload } from '../auth/token.service';
import { AssetType } from '../common/types/domain-types';
import { CreateVehicleAssetDto } from './dtos/create-vehicle-asset.dto';
import { CreatePropertyAssetDto } from './dtos/create-property-asset.dto';
import { CreateAssetSnapshotDto } from './dtos/create-asset-snapshot.dto';

@Injectable()
export class AssetsService {
  constructor(
    @InjectRepository(VehicleAsset)
    private readonly vehicleRepo: Repository<VehicleAsset>,
    @InjectRepository(PropertyAsset)
    private readonly propertyRepo: Repository<PropertyAsset>,
    @InjectRepository(QuoteSession)
    private readonly quoteSessionRepo: Repository<QuoteSession>,
    @InjectRepository(QuoteSessionAssetSnapshot)
    private readonly snapshotRepo: Repository<QuoteSessionAssetSnapshot>,
  ) {}

  async upsertVehicle(
    userId: string,
    dto: CreateVehicleAssetDto,
  ): Promise<VehicleAsset> {
    let existing: VehicleAsset | null = null;
    if (dto.plate) {
      existing = await this.vehicleRepo.findOne({
        where: { userId, plate: dto.plate },
      });
    }
    if (!existing && dto.vin) {
      existing = await this.vehicleRepo.findOne({
        where: { userId, vin: dto.vin },
      });
    }

    const record =
      existing ??
      this.vehicleRepo.create({
        userId,
      });

    Object.assign(record, dto);
    return this.vehicleRepo.save(record);
  }

  async upsertProperty(
    userId: string,
    dto: CreatePropertyAssetDto,
  ): Promise<PropertyAsset> {
    const record =
      (await this.propertyRepo.findOne({
        where: {
          userId,
          addressLine: dto.addressLine ?? undefined,
          city: dto.city ?? undefined,
        },
      })) ??
      this.propertyRepo.create({
        userId,
      });
    Object.assign(record, dto);
    return this.propertyRepo.save(record);
  }

  async createSnapshot(
    sessionId: string,
    user: AccessTokenPayload,
    dto: CreateAssetSnapshotDto,
  ): Promise<QuoteSessionAssetSnapshot> {
    const session = await this.quoteSessionRepo.findOne({
      where: { id: sessionId },
    });
    if (!session) throw new NotFoundException('Quote session not found');
    if (session.userId !== user.sub) {
      throw new ForbiddenException('Session does not belong to user');
    }

    let snapshotData = dto.snapshot;

    if (!snapshotData) {
      if (!dto.assetId) {
        throw new BadRequestException('assetId required when no snapshot');
      }
      if (dto.assetType === AssetType.VEHICLE) {
        const asset = await this.vehicleRepo.findOne({
          where: { id: dto.assetId, userId: user.sub },
        });
        if (!asset) throw new NotFoundException('Vehicle asset not found');
        snapshotData = {
          plate: asset.plate,
          vin: asset.vin,
          modelYear: asset.modelYear,
          brand: asset.brand,
          model: asset.model,
          usageType: asset.usageType,
          fuelType: asset.fuelType,
          extraJson: asset.extraJson,
        };
      } else if (dto.assetType === AssetType.PROPERTY) {
        const asset = await this.propertyRepo.findOne({
          where: { id: dto.assetId, userId: user.sub },
        });
        if (!asset) throw new NotFoundException('Property asset not found');
        snapshotData = {
          addressLine: asset.addressLine,
          city: asset.city,
          district: asset.district,
          neighborhood: asset.neighborhood,
          buildingYear: asset.buildingYear,
          sqm: asset.sqm,
          usageType: asset.usageType,
          extraJson: asset.extraJson,
        };
      }
    }

    if (!snapshotData) {
      throw new BadRequestException('Snapshot payload missing');
    }

    const snapshot = this.snapshotRepo.create({
      quoteSessionId: session.id,
      assetType: dto.assetType,
      assetId: dto.assetId ?? null,
      snapshotJson: snapshotData,
    });
    return this.snapshotRepo.save(snapshot);
  }
}
