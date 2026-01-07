import { Type } from 'class-transformer';
import { IsInt, IsNotEmptyObject, IsObject, Min } from 'class-validator';

export class UpdateQuoteSessionStepDto {
  @IsInt()
  @Min(1)
  @Type(() => Number)
  step: number;

  @IsObject()
  @IsNotEmptyObject()
  payload: Record<string, any>;
}
