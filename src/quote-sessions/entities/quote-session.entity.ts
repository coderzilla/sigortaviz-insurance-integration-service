import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Customer } from '../../users/entities/user.entity';
import { Identity } from '../../users/entities/identity.entity';
import { QuoteSessionStatus, ProductCode } from '../../common/types/domain-types';
import { QuoteSessionStepEvent } from './quote-session-step-event.entity';
import { QuoteSessionAssetSnapshot } from './quote-session-asset-snapshot.entity';

@Entity('quote_sessions')
@Index(['phoneNumber', 'productCode', 'updatedAt'])
@Index(['userId', 'productCode', 'createdAt'])
export class QuoteSession {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'char', length: 36, nullable: true })
  userId?: string | null;

  @ManyToOne(() => Customer, (user) => user.quoteSessions, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'userId' })
  user?: Customer | null;

  @Column({ type: 'varchar', length: 32 })
  phoneNumber: string;

  @Column({ type: 'char', length: 36, nullable: true })
  identityId?: string | null;

  @ManyToOne(() => Identity, (identity) => identity.quoteSessions, {
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'identityId' })
  identity?: Identity | null;

  @Column({ type: 'varchar', length: 64 })
  productCode: ProductCode;

  @Column({
    type: 'enum',
    enum: QuoteSessionStatus,
    default: QuoteSessionStatus.IN_PROGRESS,
  })
  status: QuoteSessionStatus;

  @Column({ type: 'int', default: 1 })
  currentStep: number;

  @Column({ type: 'json', nullable: true })
  stepDataJson?: Record<string, any> | null;

  @Column({ type: 'json', nullable: true })
  leadIdentitySnapshotJson?: Record<string, any> | null;

  @Column({ type: 'varchar', length: 100, nullable: true, unique: true })
  idempotencyKey?: string | null;

  @Column({ type: 'datetime', nullable: true })
  submittedAt?: Date | null;

  @Column({ type: 'datetime', nullable: true })
  expiresAt?: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => QuoteSessionStepEvent, (event) => event.quoteSession)
  stepEvents?: QuoteSessionStepEvent[];

  @OneToMany(
    () => QuoteSessionAssetSnapshot,
    (snapshot) => snapshot.quoteSession,
  )
  assetSnapshots?: QuoteSessionAssetSnapshot[];
}
