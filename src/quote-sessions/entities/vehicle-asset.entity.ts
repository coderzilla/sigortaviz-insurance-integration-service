import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Customer } from '../../users/entities/user.entity';

@Entity('vehicle_assets')
@Index(['userId', 'plate'], { unique: true })
@Index(['userId', 'vin'], { unique: true })
export class VehicleAsset {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'char', length: 36 })
  userId: string;

  @ManyToOne(() => Customer, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: Customer;

  @Column({ type: 'varchar', length: 16, nullable: true })
  plate?: string | null;

  @Column({ type: 'varchar', length: 32, nullable: true })
  vin?: string | null;

  @Column({ type: 'int', nullable: true })
  modelYear?: number | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  brand?: string | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  model?: string | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  usageType?: string | null;

  @Column({ type: 'varchar', length: 32, nullable: true })
  fuelType?: string | null;

  @Column({ type: 'json', nullable: true })
  extraJson?: Record<string, any> | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
