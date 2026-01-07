import { IsInt, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreatePropertyAssetDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  addressLine?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  district?: string;

  @IsOptional()
  @IsString()
  neighborhood?: string;

  @IsOptional()
  @IsInt()
  buildingYear?: number;

  @IsOptional()
  @IsInt()
  sqm?: number;

  @IsOptional()
  @IsString()
  usageType?: string;

  @IsOptional()
  extraJson?: Record<string, any>;
}
