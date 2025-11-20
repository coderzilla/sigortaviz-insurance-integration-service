import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  code: string; // ProductCode

  @Column()
  name: string;

  @Column({ nullable: true, type: 'text' })
  description?: string;
}