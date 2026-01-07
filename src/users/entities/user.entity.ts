import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Identity } from './identity.entity';
import { UserStatus } from '../../common/types/domain-types';
import { QuoteSession } from '../../quote-sessions/entities/quote-session.entity';

@Entity('customers')
export class Customer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 32, unique: true })
  phoneNumber: string;

  @Column({ type: 'varchar', length: 160, nullable: true })
  email?: string | null;

  @Column({ type: 'datetime', nullable: true })
  phoneVerifiedAt?: Date | null;

  @Column({ type: 'datetime', nullable: true })
  emailVerifiedAt?: Date | null;

  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.ACTIVE,
  })
  status: UserStatus;

  @Column({ type: 'boolean', default: false })
  marketingConsent: boolean;

  @Column({ type: 'boolean', default: false })
  kvkkConsent: boolean;

  @Column({ type: 'datetime', nullable: true })
  anonymizedAt?: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => Identity, (identity) => identity.user)
  identities?: Identity[];

  @OneToMany(() => QuoteSession, (session) => session.user)
  quoteSessions?: QuoteSession[];
}
