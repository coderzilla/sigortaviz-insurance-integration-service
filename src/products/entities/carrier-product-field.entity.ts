// src/products/entities/carrier-product-field.entity.ts
import {
  Column,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { CarrierProductFieldSet } from './carrier-product-field-set.entity';

@Entity('carrier_product_fields')
export class CarrierProductField {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => CarrierProductFieldSet, (set) => set.fields)
  fieldSet: CarrierProductFieldSet;

  @Column()
  internalCode: string; // "insuredBirthDate"

  @Column()
  label: string;

  @Column({ nullable: true })
  description?: string;

  @Column()
  inputType: string; // FieldInputType - stored as string

  @Column({ default: true })
  required: boolean;

  @Column({ default: true })
  isShown: boolean;

  @Column()
  orderIndex: number;

  @Column({ nullable: true })
  placeholder?: string;

  @Column({ nullable: true })
  validationRegex?: string;

  @Column({ type: 'int', nullable: true })
  minLength?: number;

  @Column({ type: 'int', nullable: true })
  maxLength?: number;

  @Column({ type: 'decimal', nullable: true })
  minValue?: number;

  @Column({ type: 'decimal', nullable: true })
  maxValue?: number;

  @Column({ type: 'json', nullable: true })
  optionsJson?: any; // FieldOption[]

  @Column({ type: 'json', nullable: true })
  extraConfigJson?: any;

  @Column({ type: 'json', nullable: true })
  stepPathJson?: string[]; // hierarchical path for grouping (e.g. ["vehicle","license"])

  @Column({ type: 'int', nullable: true })
  page?: number; // legacy pagination, kept for migration fallback

  @Column({ type: 'json', nullable: true })
  onBlurRequestJson?: any; // optional request to trigger on blur with valid value
}
