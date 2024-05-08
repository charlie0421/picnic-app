import { Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany, OneToOne, ViewColumn,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {GalleryEntity} from "./gallery.entity";
import { GalleryArticleImageEntity } from "./article_image.entity";
import {ArticleCommentEntity} from "./article_comment.entity";

@Entity("gallery_article")
export class GalleryArticleEntity extends BaseEntity {
    @Column({name: "title_ko"})
    titleKo: string;

    @Column({name: "title_en"})
    titleEn: string;

    @Column({name: "content"})
    content: string;

    @Column({name: "comment_count", default: 0})
    commentCount: number;

    @ManyToOne(() => GalleryEntity, (gallery) => gallery.articles)
    @JoinColumn({name: "gallery_id"})
    gallery: GalleryEntity;

    @OneToMany(() => GalleryArticleImageEntity, (image) => image.article, {lazy: true})
    images: GalleryArticleImageEntity[];

    @OneToMany(() => ArticleCommentEntity, (comment) => comment.article)
    comments: ArticleCommentEntity[];

    mostLikedComment: ArticleCommentEntity;


}
