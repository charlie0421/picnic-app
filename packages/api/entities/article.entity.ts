import { Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany, OneToOne, ViewColumn,} from "typeorm";
import {BaseEntity} from "./base_entity";
import {GalleryEntity} from "./gallery.entity";
import { ArticleImageEntity } from "./article_image.entity";
import {ArticleCommentEntity} from "./article_comment.entity";

@Entity("article")
export class ArticleEntity extends BaseEntity {
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

    @OneToMany(() => ArticleImageEntity, (image) => image.article, {lazy: true})
    images: ArticleImageEntity[];

    @OneToMany(() => ArticleCommentEntity, (comment) => comment.article)
    comments: ArticleCommentEntity[];

    mostLikedComment: ArticleCommentEntity;


}
