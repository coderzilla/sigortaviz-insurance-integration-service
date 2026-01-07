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

@Entity('property_assets')
@Index(['userId', 'addressLine'], { unique: false })
export class PropertyAsset {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'char', length: 36 })
  userId: string;

  @ManyToOne(() => Customer, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: Customer;

  @Column({ type: 'varchar', length: 255, nullable: true })
  addressLine?: string | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  city?: string | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  district?: string | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  neighborhood?: string | null;

  @Column({ type: 'int', nullable: true })
  buildingYear?: number | null;

  @Column({ type: 'int', nullable: true })
  sqm?: number | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  usageType?: string | null;

  @Column({ type: 'json', nullable: true })
  extraJson?: Record<string, any> | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
