import { Column, Entity } from 'typeorm';
import { BaseEntity } from "./base_entity";
import { PolicyType } from "../common/enums";

@Entity('policy')
export class PolicyEntity extends BaseEntity {
  @Column()
  type: PolicyType;

  @Column({ type: 'text' })
  content: string;

  @Column()
  version: string;
}
