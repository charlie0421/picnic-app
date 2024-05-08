import {AfterLoad, Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {GalleryArticleEntity} from "./article.entity";
import {UserEntity} from "./user.entity";
import {AlbumEntity} from "./album.entity";

@Entity("gallery_article_image")
export class GalleryArticleImageEntity extends BaseEntity {
    @Column({name: "order"})
    order: number;

    @Column({name: "title_ko"})
    titleKo: string;

    @Column({name: "title_en"})
    titleEn: string;

    @Column({name: "image"})
    image: string;

    @AfterLoad()
    getImage() {
        this.image = this.image ? `${process.env.CDN_URL}/prame/article/${this.articleId}/images/${this.id}/${this.image}` : '';
    }

    @ManyToOne(() => GalleryArticleEntity, (article) => article.images, {eager: true})
    @JoinColumn({name: "article_id"})
    article: GalleryArticleEntity;

    @Column({name: "article_id"})
    articleId: number;


    @ManyToMany(() => UserEntity, (user) => user.bookmarks)
    @JoinTable({
        name: "album_image_user",
        joinColumn: {
            name: "user_id",
        },
        inverseJoinColumn: {
            name: "image_id",
        },
    })
    bookmarkUsers: UserEntity[];


    @ManyToMany(() => AlbumEntity, (library) => library.images)
    @JoinTable({
        name: "album_image",
        joinColumn: {
            name: "image_id",
            referencedColumnName: "id",
        },
        inverseJoinColumn: {
            name: "album_id",
            referencedColumnName: "id",
        },
    })
    albums: AlbumEntity[];

}
