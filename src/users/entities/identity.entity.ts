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
import { Customer } from './user.entity';
import { QuoteSession } from '../../quote-sessions/entities/quote-session.entity';

@Entity('identities')
@Index(['userId', 'idNumberHash'], { unique: true })
export class Identity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'char', length: 36 })
  userId: string;

  @ManyToOne(() => Customer, (user) => user.identities, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: Customer;

  @Column({ type: 'varchar', length: 64 })
  idNumber: string;

  @Column({ type: 'varchar', length: 128 })
  idNumberHash: string;

  @Column({ type: 'varchar', length: 160, nullable: true })
  fullName?: string | null;

  @Column({ type: 'date', nullable: true })
  birthDate?: Date | null;

  @Column({ type: 'boolean', default: false })
  isPreferred: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => QuoteSession, (session) => session.identity)
  quoteSessions?: QuoteSession[];
}
