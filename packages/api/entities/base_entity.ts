import { instanceToPlain } from 'class-transformer';

import {
  CreateDateColumn,
  DeleteDateColumn,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';


export class BaseEntity {
  @PrimaryGeneratedColumn()
  id: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp', nullable: false, default: () => 'CURRENT_TIMESTAMP(6)'})
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp', nullable: false, default: () => 'CURRENT_TIMESTAMP(6)' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamp', nullable: true })
  deletedAt?: Date;

  toJSON() {
    const record = instanceToPlain(this);

    const cleanUnderscoresProperties = (obj: object): void => {
      for (const [key, val] of Object.entries(obj)) {
        if (key.startsWith('__') && key.endsWith('__')) {
          const newKey = key.substring(2, key.length - 2);
          obj[newKey] = obj[key];
          delete obj[key];
        } else if (typeof val === 'object') {
          if (val != null) {
            cleanUnderscoresProperties(val);
          }
        }
      }
    };

    if (record != null) {
      cleanUnderscoresProperties(record);
    }

    return record;
  }
}
