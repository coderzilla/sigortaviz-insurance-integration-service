// src/products/products.controller.ts
import { Controller, Get, Param, ParseEnumPipe, Query } from '@nestjs/common';
import { ProductsService } from './products.service';
import { GetConfigQuery } from './dtos/get-config-query';
import {
  FieldConfig,
  FormStage,
  ProductFormConfig,
} from '../common/types/field-types';
import { GetConfigUnionQuery } from './dtos/get-config-union-query';
import { ProductCode } from '../common/types/domain-types';

@Controller()
export class ProductsController {
  constructor(
    private readonly productsService: ProductsService,
  ) {}

  @Get('config')
  async getConfig(
    @Query() query: GetConfigQuery,
  ): Promise<{
    product: string;
    carrier: string;
    fields: FieldConfig[];
    pageChangeRequest?: ProductFormConfig['pageChangeRequest'];
    steps?: ProductFormConfig['steps'];
  }> {
    const formConfig = await this.productsService.getFieldConfig(
      query.product,
      query.carrier,
      query.stage ?? 'QUOTE',
    );

    return {
      product: query.product,
      carrier: query.carrier,
      fields: formConfig.fields,
      pageChangeRequest: formConfig.pageChangeRequest,
      steps: formConfig.steps,
    };
  }

  @Get('config/product/:product')
  async getUnionConfig(
    @Param('product', new ParseEnumPipe(ProductCode)) product: ProductCode,
    @Query() query: GetConfigUnionQuery,
  ): Promise<{
    product: ProductCode;
    stage: FormStage;
    carriers: string[];
    fields: Array<
      FieldConfig & { requiredFor: string[]; optionalFor: string[] }
    >;
    pageChangeRequests: Record<string, ProductFormConfig['pageChangeRequest']>;
    steps?: ProductFormConfig['steps'];
  }> {
    const stage = query.stage ?? 'QUOTE';
    const carriers =
      query.carriers ||
      (query.carrier
        ? [query.carrier]
        : await this.productsService.getCarriersWithConfig(product, stage));

    const config = await this.productsService.getUnionFieldConfig(
      product,
      carriers,
      stage,
    );

    return {
      product: config.product,
      stage: config.stage,
      carriers: config.carriers,
      fields: config.fields,
      pageChangeRequests: config.pageChangeRequests,
      steps: config.steps,
    };
  }
}
