import {AfterLoad, Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne} from "typeorm";

import {BaseEntity} from './base_entity';
import {Celeb} from "./celeb.entity";

@Entity('celeb_banner')
export class CelebBanner extends BaseEntity {
    @Column({name: 'title_ko'})
    titleKo: string;

    @Column({name: 'title_en'})
    titleEn: string;

    @Column({name: 'subtitle_ko'})
    subtitleKo: string;

    @Column({name: 'subtitle_en'})
    subtitleEn: string;

    @Column()
    thumbnail: string;

    @AfterLoad()
    getThumbnail() {
        this.thumbnail = `${process.env.CDN_URL}/celeb_banner/${this.id}/${this.thumbnail}`;
    }

    @Column({nullable: true})
    url: string;

    @Column({type: 'datetime', name: 'start_at'})
    startAt: Date;

    @Column({type: 'datetime', name: 'end_at', nullable: true})
    endAt?: Date;

    @ManyToOne(() => Celeb, (celeb) => celeb.banners)
    @JoinColumn({name: 'celeb_id'})
    celeb : Celeb;
}
