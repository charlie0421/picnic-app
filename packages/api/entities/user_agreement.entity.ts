import { Column, Entity, JoinColumn, OneToOne, PrimaryColumn } from "typeorm";

import { BaseEntity } from './base_entity';
import { UserEntity } from "./user.entity";

@Entity('user_agreement')
export class UserAgreementEntity extends BaseEntity {

  @OneToOne(() => UserEntity, (user) => user.userAgreement)
  @JoinColumn({ name: 'user_id' })
  user: UserEntity;
  @Column({ name: 'user_id', type: 'int' , nullable: false})
  userId: number;

  @Column({ name: 'terms', type: 'timestamp' })
  terms: Date;

  @Column({ name: 'privacy', type: 'timestamp' })
  privacy: Date;

}
