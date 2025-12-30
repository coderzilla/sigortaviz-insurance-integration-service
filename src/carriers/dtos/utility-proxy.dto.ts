import { IsIn, IsObject, IsOptional, IsString } from 'class-validator';

export class UtilityProxyQueryDto {
  @IsString()
  url: string;
}

export class UtilityProxyBodyDto {
  @IsOptional()
  @IsIn(['GET', 'POST'])
  method?: 'GET' | 'POST';

  @IsOptional()
  @IsObject()
  params?: Record<string, any>;
}
