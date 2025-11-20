// src/products/entities/carrier-field-mapping.entity.ts
import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { CarrierProduct } from './carrier-product.entity';

@Entity('carrier_field_mappings')
export class CarrierFieldMapping {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => CarrierProduct)
  carrierProduct: CarrierProduct;

  @Column()
  internalCode: string; // "insuredBirthDate"

  @Column()
  carrierParamName: string; // "insured_birthdate"

  @Column({ default: 'NONE' })
  transformType: string; // FieldTransformType

  @Column({ default: true })
  isRequiredForApi: boolean;
}
