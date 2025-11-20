import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { Carrier } from './carrier.entity';
import { Product } from './product.entity';

@Entity('carrier_products')
export class CarrierProduct {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Carrier, { eager: true })
  carrier: Carrier;

  @ManyToOne(() => Product, { eager: true })
  product: Product;

  @Column()
  externalCode: string; // carrier's product code

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'decimal', nullable: true })
  minPremium?: number;

  @Column({ type: 'decimal', nullable: true })
  maxPremium?: number;
}