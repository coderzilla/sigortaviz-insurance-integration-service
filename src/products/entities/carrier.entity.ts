// src/products/entities/carrier.entity.ts
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('carriers')
export class Carrier {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  code: string; // CarrierCode

  @Column()
  name: string;

  @Column({ default: true })
  isActive: boolean;
}
