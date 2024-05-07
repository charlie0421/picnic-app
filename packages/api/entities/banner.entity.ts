import { AfterLoad, Column, Entity } from "typeorm";

import { BaseEntity } from './base_entity';

@Entity('event_banner')
export class EventBanner extends BaseEntity {
  @Column()
  tag_ko: string;

  @Column()
  tag_en: string;

  @Column()
  title_ko: string;

  @Column()
  title_en: string;

  @Column()
  subtitle_ko: string;

  @Column()
  subtitle_en: string;

  @Column()
  event_img_ko: string;
  @AfterLoad()
  getImageKo() {
    this.event_img_ko = `${process.env.CDN_URL}/banner/${this.id}/${this.event_img_ko}`;
  }

  @Column()
  event_img_en: string;
  @AfterLoad()
  getImageEn() {
    this.event_img_en = `${process.env.CDN_URL}/banner/${this.id}/${this.event_img_en}`;
  }

  @Column({ nullable: true })
  url: string;

  @Column({ type: 'datetime' })
  start_at: Date;

  @Column({ type: 'datetime' })
  end_at: Date;
}