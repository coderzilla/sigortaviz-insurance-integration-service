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
  RequestTriggerConfig,
  StepDefinition,
} from '../common/types/field-types';
import { ProductCode } from '../common/types/domain-types';

@Injectable()
export class ProductsService {
  private readonly quickCarrierCode = 'QUICK_SIGORTA';
  private readonly quickApiGatewayPlaceholder = '{{api-gw-uri}}';
  private readonly quickApiGatewayBase = (process.env.QUICK_API_BASE ?? '')
    .trim()
    .replace(/\/$/, '');

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

    let steps: StepDefinition[] = [];
    let stepsConfig: { steps: StepDefinition[]; defaults?: Record<string, any> } | undefined;

    if (Array.isArray(effectiveFieldSet.stepsJson)) {
      steps = effectiveFieldSet.stepsJson;
    } else if (
      effectiveFieldSet.stepsJson &&
      Array.isArray(effectiveFieldSet.stepsJson.steps)
    ) {
      steps = effectiveFieldSet.stepsJson.steps;
      stepsConfig = {
        steps,
        defaults: effectiveFieldSet.stepsJson.defaults,
      };
    }

    const stepOrderLookup = new Map<string, number>();
    let stepOrderCounter = 0;
    const registerSteps = (nodes?: StepDefinition[], path: string[] = []) => {
      (nodes || []).forEach((node) => {
        const currentPath = [...path, node.id];
        stepOrderLookup.set(currentPath.join('/'), ++stepOrderCounter);
        if (node.children?.length) {
          registerSteps(node.children, currentPath);
        }
      });
    };
    registerSteps(steps);

    const getStepOrder = (path?: string[]) => {
      if (!path || !path.length) return Number.MAX_SAFE_INTEGER;
      return stepOrderLookup.get(path.join('/')) ?? Number.MAX_SAFE_INTEGER;
    };

    const fieldConfigs: FieldConfig[] = (effectiveFieldSet.fields || [])
      .map((f): FieldConfig => {
        const validation: FieldValidationRules = {
          regex: f.validationRegex || undefined,
          minLength: f.minLength ?? undefined,
          maxLength: f.maxLength ?? undefined,
          minValue: f.minValue !== null ? Number(f.minValue) : undefined,
          maxValue: f.maxValue !== null ? Number(f.maxValue) : undefined,
        };

        const stepPath =
          (f.stepPathJson && f.stepPathJson.length
            ? f.stepPathJson
            : undefined) ??
          (typeof f.page === 'number' ? [`legacy-page-${f.page}`] : undefined);

        const rawExtraConfig = f.extraConfigJson || undefined;
        const { isShown: extraIsShown, ...restExtraConfig } = rawExtraConfig ?? {};
        const isShown = f.isShown ?? extraIsShown;
        const normalizedExtraConfig =
          restExtraConfig && Object.keys(restExtraConfig).length
            ? restExtraConfig
            : undefined;

        return {
          internalCode: f.internalCode,
          label: f.label,
          description: f.description || undefined,
          inputType: f.inputType as any,
          required: f.required,
          isShown: isShown ?? true,
          orderIndex: f.orderIndex,
          stepPath,
          placeholder: f.placeholder || undefined,
          options: f.optionsJson || undefined,
          validation,
          extraConfig: normalizedExtraConfig,
          onBlurRequest: f.onBlurRequestJson || undefined,
        };
      })
      .sort((a, b) => {
        const stepDiff = getStepOrder(a.stepPath) - getStepOrder(b.stepPath);
        return stepDiff !== 0 ? stepDiff : a.orderIndex - b.orderIndex;
      });

    const config: ProductFormConfig = {
      fields: fieldConfigs,
      pageChangeRequest: effectiveFieldSet.pageChangeRequestJson || undefined,
      steps,
      stepsConfig,
    };

    return this.applyQuickGatewayBaseIfNeeded(config, carrier.code);
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
    steps?: StepDefinition[];
    stepsConfig?: { steps: StepDefinition[]; defaults?: Record<string, any> };
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

    const stepsConfig =
      carrierConfigs
        .map((c) => c.config.stepsConfig)
        .find((s) => s && s.steps?.length);

    const steps =
      stepsConfig?.steps ||
      carrierConfigs
        .map((c) => c.config.steps)
        .find((s) => s && s.length) ||
      [];

    const stepOrderLookup = new Map<string, number>();
    let stepOrderCounter = 0;
    const registerSteps = (nodes?: StepDefinition[], path: string[] = []) => {
      (nodes || []).forEach((node) => {
        const currentPath = [...path, node.id];
        stepOrderLookup.set(currentPath.join('/'), ++stepOrderCounter);
        if (node.children?.length) {
          registerSteps(node.children, currentPath);
        }
      });
    };
    registerSteps(steps);

    const getStepOrder = (path?: string[]) => {
      if (!path || !path.length) return Number.MAX_SAFE_INTEGER;
      return stepOrderLookup.get(path.join('/')) ?? Number.MAX_SAFE_INTEGER;
    };

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
          // Keep the earliest ordering as baseline; carrier-specific overrides can be stored in extraConfig if needed
        } else {
          unionMap.set(field.internalCode, {
            ...field,
            requiredFor: field.required ? [carrierCode] : [],
            optionalFor: field.required ? [] : [carrierCode],
          });
        }
      });
    });

    const unionConfig = {
      product,
      stage,
      carriers,
      fields: Array.from(unionMap.values()).sort((a, b) => {
        const stepDiff = getStepOrder(a.stepPath) - getStepOrder(b.stepPath);
        return stepDiff !== 0 ? stepDiff : a.orderIndex - b.orderIndex;
      }),
      pageChangeRequests,
      steps,
      stepsConfig,
    };

    return unionConfig;
  }

  private applyQuickGatewayBaseIfNeeded<T>(value: T, carrierCode: string): T {
    if (!this.isQuickCarrier(carrierCode)) {
      return value;
    }

    if (typeof value === 'string') {
      if (
        value.includes(this.quickApiGatewayPlaceholder) &&
        !this.quickApiGatewayBase
      ) {
        throw new Error(
          'QUICK_API_BASE env variable is required to resolve {{api-gw-uri}}',
        );
      }

      return value
        .split(this.quickApiGatewayPlaceholder)
        .join(this.quickApiGatewayBase) as unknown as T;
    }

    if (Array.isArray(value)) {
      return value.map((item) => this.applyQuickGatewayBaseIfNeeded(item, carrierCode)) as unknown as T;
    }

    if (value && typeof value === 'object') {
      if (value instanceof Date) {
        return value;
      }

      const entries = Object.entries(
        value as Record<string, unknown>,
      ).map(([k, v]) => [k, this.applyQuickGatewayBaseIfNeeded(v, carrierCode)]);
      return Object.fromEntries(entries) as T;
    }

    return value;
  }

  private isQuickCarrier(code: string): boolean {
    return code?.toUpperCase() === this.quickCarrierCode;
  }
}
