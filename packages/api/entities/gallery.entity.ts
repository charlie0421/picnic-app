import {AfterLoad, Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {UserEntity} from "./user.entity";
import {CelebEntity} from "./celeb.entity";
import {ArticleEntity} from "./article.entity";
import {ArticleImageEntity} from "./article-image.entity";

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

    @ManyToOne(() => CelebEntity, (celeb) => celeb.galleries)
    @JoinColumn ({name: "celeb_id"})
    celeb: CelebEntity;

    @OneToMany(() => ArticleEntity, (article) => article.gallery)
    articles: ArticleEntity[];

    @ManyToMany(() => UserEntity, (user) => user.galleries)
    @JoinTable({name: "gallery_user", joinColumn: {name: "gallery_id"}, inverseJoinColumn: {name: "user_id"}})
    users: UserEntity[];
}
