// src/products/products.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Carrier } from './entities/carrier.entity';
import { Product } from './entities/product.entity';
import { CarrierProduct } from './entities/carrier-product.entity';
import { CarrierProductFieldSet } from './entities/carrier-product-field-set.entity';
import {
  FieldConfig,
  FieldValidationRules,
  ProductFormConfig,
} from '../common/types/field-types';
import { ProductCode } from '../common/types/domain-types';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Carrier)
    private readonly carrierRepo: Repository<Carrier>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(CarrierProduct)
    private readonly carrierProductRepo: Repository<CarrierProduct>,
    @InjectRepository(CarrierProductFieldSet)
    private readonly fieldSetRepo: Repository<CarrierProductFieldSet>,
  ) {}

  /**
   * Returns FieldConfig[] for given product + carrier.
   * Example: product = HEALTH, carrierCode = "COMPANY_B"
   */
  async getFieldConfig(
    product: ProductCode,
    carrierCode: string,
    atDate: Date = new Date(),
  ): Promise<ProductFormConfig> {
    const carrier = await this.carrierRepo.findOne({
      where: { code: carrierCode, isActive: true },
    });
    if (!carrier) {
      throw new NotFoundException(`Carrier not found: ${carrierCode}`);
    }

    const productEntity = await this.productRepo.findOne({
      where: { code: product },
    });
    if (!productEntity) {
      throw new NotFoundException(`Product not found: ${product}`);
    }

    const carrierProduct = await this.carrierProductRepo.findOne({
      where: {
        carrier: { id: carrier.id },
        product: { id: productEntity.id },
        isActive: true,
      },
    });

    if (!carrierProduct) {
      throw new NotFoundException(
        `Carrier product not found for carrier=${carrierCode}, product=${product}`,
      );
    }

    // Fetch active field set for date
    const fieldSets = await this.fieldSetRepo.find({
      where: {
        carrierProduct: { id: carrierProduct.id },
        isActive: true,
      },
      relations: ['fields'],
    });

    if (!fieldSets.length) {
      return { fields: [] };
    }

    // Simple: choose latest version valid at date
    const effectiveFieldSet = fieldSets
      .filter((set) => {
        const fromOk =
          !set.validFrom || set.validFrom.getTime() <= atDate.getTime();
        const toOk =
          !set.validTo || set.validTo.getTime() >= atDate.getTime();
        return fromOk && toOk;
      })
      .sort((a, b) => b.version - a.version)[0];

    if (!effectiveFieldSet) {
      return { fields: [] };
    }

    const fieldConfigs: FieldConfig[] = (effectiveFieldSet.fields || [])
      .sort((a, b) => {
        const pageDiff = (a.page ?? 1) - (b.page ?? 1);
        return pageDiff !== 0 ? pageDiff : a.orderIndex - b.orderIndex;
      })
      .map((f): FieldConfig => {
        const validation: FieldValidationRules = {
          regex: f.validationRegex || undefined,
          minLength: f.minLength ?? undefined,
          maxLength: f.maxLength ?? undefined,
          minValue: f.minValue !== null ? Number(f.minValue) : undefined,
          maxValue: f.maxValue !== null ? Number(f.maxValue) : undefined,
        };

        return {
          internalCode: f.internalCode,
          label: f.label,
          description: f.description || undefined,
          inputType: f.inputType as any,
          required: f.required,
          page: f.page ?? 1,
          orderIndex: f.orderIndex,
          placeholder: f.placeholder || undefined,
          options: f.optionsJson || undefined,
          validation,
          extraConfig: f.extraConfigJson || undefined,
          onBlurRequest: f.onBlurRequestJson || undefined,
        };
      });

    return {
      fields: fieldConfigs,
      pageChangeRequest: effectiveFieldSet.pageChangeRequestJson || undefined,
    };
  }
}
