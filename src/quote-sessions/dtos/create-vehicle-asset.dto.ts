import { IsInt, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateVehicleAssetDto {
  @IsOptional()
  @IsString()
  @MaxLength(16)
  plate?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  vin?: string;

  @IsOptional()
  @IsInt()
  modelYear?: number;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @IsString()
  model?: string;

  @IsOptional()
  @IsString()
  usageType?: string;

  @IsOptional()
  @IsString()
  fuelType?: string;

  @IsOptional()
  extraJson?: Record<string, any>;
}
