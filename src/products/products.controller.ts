// src/products/products.controller.ts
import { Controller, Get, Query } from '@nestjs/common';
import { ProductsService } from './products.service';
import { GetConfigQuery } from './dtos/get-config-query';
import { FieldConfig } from '../common/types/field-types';

@Controller()
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get('config')
  async getConfig(
    @Query() query: GetConfigQuery,
  ): Promise<{
    product: string;
    carrier: string;
    fields: FieldConfig[];
  }> {
    const fields = await this.productsService.getFieldConfig(
      query.product,
      query.carrier,
    );

    return {
      product: query.product,
      carrier: query.carrier,
      fields,
    };
  }
}
