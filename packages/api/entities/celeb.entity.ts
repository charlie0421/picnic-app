import {AfterLoad, Column, Entity, JoinTable, ManyToMany, OneToMany,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {PrameUserEntity} from "./prame-user.entity";
import {CelebBanner} from "./celeb_banner.entity";
import {GalleryEntity} from "./gallery.entity";

@Entity("celeb")
export class Celeb extends BaseEntity {
    @Column({name: "name_ko"})
    nameKo: string;

    @Column({name: "name_en"})
    nameEn: string;

    @Column({name: "thumbnail", default: ""})
    thumbnail: string

    @AfterLoad()
    getThumbnail() {
        if (this.thumbnail)
            this.thumbnail = `${process.env.CDN_URL}/prame/celeb/${this.id}/${this.thumbnail}`;
    }

    @ManyToMany(() => PrameUserEntity, (user) => user.celebs)
    @JoinTable({name: "celeb_user", joinColumn: {name: "celeb_id"}, inverseJoinColumn: {name: "user_id"}})
    users: PrameUserEntity[];

    @OneToMany(() => CelebBanner, (banner) => banner.celeb)
    banners: CelebBanner[];

    @OneToMany(() => GalleryEntity, (gallery) => gallery.celeb)
    galleries: GalleryEntity[];

}
