// src/products/entities/carrier-product-field-set.entity.ts
import {
  Column,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { CarrierProduct } from './carrier-product.entity';
import { CarrierProductField } from './carrier-product-field.entity';

@Entity('carrier_product_field_sets')
export class CarrierProductFieldSet {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => CarrierProduct)
  carrierProduct: CarrierProduct;

  @Column()
  version: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'timestamp', nullable: true })
  validFrom?: Date;

  @Column({ type: 'timestamp', nullable: true })
  validTo?: Date;

  @OneToMany(() => CarrierProductField, (field) => field.fieldSet, {
    eager: true,
  })
  fields: CarrierProductField[];

  @Column({ type: 'json', nullable: true })
  pageChangeRequestJson?: any; // optional request to trigger between page changes
}
