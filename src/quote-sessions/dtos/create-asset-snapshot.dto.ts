import { IsEnum, IsObject, IsOptional, IsString } from 'class-validator';
import { AssetType } from '../../common/types/domain-types';

export class CreateAssetSnapshotDto {
  @IsEnum(AssetType)
  assetType: AssetType;

  @IsOptional()
  @IsString()
  assetId?: string;

  @IsOptional()
  @IsObject()
  snapshot?: Record<string, any>;
}
