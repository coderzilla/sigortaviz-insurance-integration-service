// src/products/products.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Carrier } from './entities/carrier.entity';
import { Product } from './entities/product.entity';
import { CarrierProduct } from './entities/carrier-product.entity';
import { CarrierProductFieldSet } from './entities/carrier-product-field-set.entity';
import { CarrierProductField } from './entities/carrier-product-field.entity';
import { CarrierFieldMapping } from './entities/carrier-field-mapping.entity';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Carrier,
      Product,
      CarrierProduct,
      CarrierProductFieldSet,
      CarrierProductField,
      CarrierFieldMapping,
    ]),
  ],
  providers: [ProductsService],
  controllers: [ProductsController],
  exports: [ProductsService],
})
export class ProductsModule {}
