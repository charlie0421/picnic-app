import {AfterLoad, Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {UserEntity} from "./user.entity";
import {Celeb} from "./celeb.entity";
import {GalleryArticleEntity} from "./article.entity";
import {GalleryArticleImageEntity} from "./article_image.entity";

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
            this.cover = `${process.env.CDN_URL}/gallery/${this.id}/${this.cover}`;
    }

    @ManyToOne(() => Celeb, (celeb) => celeb.galleries)
    @JoinColumn ({name: "celeb_id"})
    celeb: Celeb;

    @OneToMany(() => GalleryArticleEntity, (article) => article.gallery)
    articles: GalleryArticleEntity[];

    @ManyToMany(() => UserEntity, (user) => user.galleries)
    @JoinTable({name: "gallery_user", joinColumn: {name: "gallery_id"}, inverseJoinColumn: {name: "user_id"}})
    users: UserEntity[];
}
