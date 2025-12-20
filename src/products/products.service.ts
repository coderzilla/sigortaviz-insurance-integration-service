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
  FormStage,
  ProductFormConfig,
} from '../common/types/field-types';
import { ProductCode } from '../common/types/domain-types';
import { RequestTriggerConfig } from '../common/types/field-types';

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
   * Returns carrier codes that have an active carrier_product and an active field set
   * configured for the given product + stage.
   *
   * This is the DB-driven source of truth for "which carriers can be quoted" in the UI.
   */
  async getCarriersWithConfig(
    product: ProductCode,
    stage: FormStage = 'QUOTE',
  ): Promise<string[]> {
    const rows = await this.carrierProductRepo
      .createQueryBuilder('cp')
      .innerJoin('cp.carrier', 'c')
      .innerJoin('cp.product', 'p')
      .innerJoin(
        CarrierProductFieldSet,
        'fs',
        'fs.carrierProductId = cp.id AND fs.isActive = true AND fs.stage = :stage',
        { stage },
      )
      .where('cp.isActive = true')
      .andWhere('c.isActive = true')
      .andWhere('p.code = :product', { product })
      .select('DISTINCT c.code', 'code')
      .orderBy('c.code', 'ASC')
      .getRawMany<{ code: string }>();

    return rows.map((r) => r.code).filter(Boolean);
  }

  /**
   * Returns FieldConfig[] for given product + carrier.
   * Example: product = HEALTH, carrierCode = "COMPANY_B"
   */
  async getFieldConfig(
    product: ProductCode,
    carrierCode: string,
    stage: FormStage = 'QUOTE',
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

    // Filter by stage and date, then pick the latest version
    const effectiveFieldSet = fieldSets
      .filter((set) => {
        const normalizedStage = (set.stage ?? 'QUOTE') as FormStage;
        const stageOk = normalizedStage === stage;
        const fromOk =
          !set.validFrom || set.validFrom.getTime() <= atDate.getTime();
        const toOk =
          !set.validTo || set.validTo.getTime() >= atDate.getTime();
        return stageOk && fromOk && toOk;
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

  /**
   * Returns a union of field configs across carriers for a given product/stage.
   * Useful for rendering a single form that satisfies multiple carriers.
   */
  async getUnionFieldConfig(
    product: ProductCode,
    carriers: string[],
    stage: FormStage = 'QUOTE',
  ): Promise<{
    product: ProductCode;
    stage: FormStage;
    carriers: string[];
    fields: Array<
      FieldConfig & {
        requiredFor: string[];
        optionalFor: string[];
      }
    >;
    pageChangeRequests: Record<string, RequestTriggerConfig | undefined>;
  }> {
    const carrierConfigs = await Promise.all(
      carriers.map(async (carrierCode) => {
        const cfg = await this.getFieldConfig(product, carrierCode, stage);
        return { carrierCode, config: cfg };
      }),
    );

    const pageChangeRequests: Record<string, RequestTriggerConfig | undefined> =
      {};
    const unionMap = new Map<
      string,
      FieldConfig & { requiredFor: string[]; optionalFor: string[] }
    >();

    carrierConfigs.forEach(({ carrierCode, config }) => {
      pageChangeRequests[carrierCode] = config.pageChangeRequest;
      (config.fields || []).forEach((field) => {
        const existing = unionMap.get(field.internalCode);
        if (existing) {
          if (field.required) {
            existing.requiredFor.push(carrierCode);
          } else {
            existing.optionalFor.push(carrierCode);
          }
          // Keep the earliest order/page as baseline; carrier-specific overrides can be stored in extraConfig if needed
        } else {
          unionMap.set(field.internalCode, {
            ...field,
            requiredFor: field.required ? [carrierCode] : [],
            optionalFor: field.required ? [] : [carrierCode],
          });
        }
      });
    });

    return {
      product,
      stage,
      carriers,
      fields: Array.from(unionMap.values()).sort((a, b) => {
        const pageDiff = (a.page ?? 1) - (b.page ?? 1);
        return pageDiff !== 0 ? pageDiff : a.orderIndex - b.orderIndex;
      }),
      pageChangeRequests,
    };
  }
}
