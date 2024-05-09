import {AfterLoad, Column, Entity, JoinTable, ManyToMany, OneToMany,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {UserEntity} from "./user.entity";
import {CelebBannerEntity} from "./celeb-banner.entity";
import {GalleryEntity} from "./gallery.entity";

@Entity("celeb")
export class CelebEntity extends BaseEntity {
    @Column({name: "name_ko"})
    nameKo: string;

    @Column({name: "name_en"})
    nameEn: string;

    @Column({name: "thumbnail", default: ""})
    thumbnail: string

    @AfterLoad()
    getThumbnail() {
        if (this.thumbnail)
            this.thumbnail = `${process.env.CDN_URL}/celeb/${this.id}/${this.thumbnail}`;
    }

    @ManyToMany(() => UserEntity, (user) => user.celebs)
    @JoinTable({name: "celeb_user", joinColumn: {name: "celeb_id"}, inverseJoinColumn: {name: "user_id"}})
    users: UserEntity[];

    @OneToMany(() => CelebBannerEntity, (banner) => banner.celeb)
    banners: CelebBannerEntity[];

    @OneToMany(() => GalleryEntity, (gallery) => gallery.celeb)
    galleries: GalleryEntity[];

}
