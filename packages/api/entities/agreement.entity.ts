import { Column, Entity } from 'typeorm';

import { BaseEntity } from './base_entity';

export type AgreementType = 'TERMS' | 'COMMERCE' | 'PRIVACY' | 'LOCATION' | 'MARKETING';

@Entity('agreement')
export class AgreementEntity extends BaseEntity {
  @Column({ name: 'type', type: 'varchar', length: 255 })
  type: AgreementType;

  @Column({ name: 'title', type: 'varchar', length: 255 })
  title: string;

  @Column({ name: 'content', type: 'text' })
  content: string;

  @Column({ name: 'version', type: 'varchar', length: 255 })
  version: string;

  @Column({ name: 'effective_date', type: 'datetime' })
  effectiveDate: Date;

  @Column({ name: 'is_required', type: 'boolean' })
  isRequired: boolean;
}
