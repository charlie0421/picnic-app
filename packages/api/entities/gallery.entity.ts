import {AfterLoad, Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {PrameUserEntity} from "./prame-user.entity";
import {Celeb} from "./celeb.entity";
import {GalleryArticleEntity} from "./gallery_article.entity";
import {GalleryArticleImageEntity} from "./gallery_article_image.entity";

@Entity("gallery")
export class GalleryEntity extends BaseEntity {
    @Column({name: "title_ko"})
    titleKo: string;

    @Column({name: "title_en"})
    titleEn: string;

    @Column({name: "cover", default: ""})
    cover: string;

    @AfterLoad()
    getThumbnail() {
        if (this.cover)
            this.cover = `${process.env.CDN_URL}/prame/gallery/${this.id}/${this.cover}`;
    }

    @ManyToOne(() => Celeb, (celeb) => celeb.galleries)
    @JoinColumn ({name: "celeb_id"})
    celeb: Celeb;

    @OneToMany(() => GalleryArticleEntity, (article) => article.gallery)
    articles: GalleryArticleEntity[];

    @ManyToMany(() => PrameUserEntity, (user) => user.galleries)
    @JoinTable({name: "gallery_user", joinColumn: {name: "gallery_id"}, inverseJoinColumn: {name: "user_id"}})
    users: PrameUserEntity[];
}
