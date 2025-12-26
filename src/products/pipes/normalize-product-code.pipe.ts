import { BadRequestException, PipeTransform } from '@nestjs/common';

// Normalizes product code path params (trim + uppercase) before enum validation.
export class NormalizeProductCodePipe implements PipeTransform {
  transform(value: unknown): string {
    if (typeof value !== 'string') {
      throw new BadRequestException('product must be provided as a string path param');
    }

    const normalized = value.trim().toUpperCase();

    if (!normalized) {
      throw new BadRequestException('product path param is missing');
    }

    return normalized;
  }
}
