import {Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany} from "typeorm";

import {BaseEntity} from "./base_entity";
import {GalleryArticleEntity} from "./gallery_article.entity";
import {PrameUserEntity} from "./prame-user.entity";
import {PrameUserCommentLikeEntity} from "./prame_user_comment_like.entity";
import {PrameUserCommentReportEntity} from "./prame_user-comment-report.entity";

@Entity("article_comment")
export class ArticleCommentEntity extends BaseEntity {
    @ManyToOne(() => GalleryArticleEntity, (article) => article.id)
    @JoinColumn({name: "article_id"})
    article: GalleryArticleEntity;
    @Column({name: "article_id"})
    articleId: number;

    @ManyToOne(() => PrameUserEntity, (user) => user.id)
    @JoinColumn({name: "user_id"})
    user: PrameUserEntity;
    @Column({name: "user_id"})
    userId: number;

    @ManyToOne(() => ArticleCommentEntity, (articleComment) => articleComment.children, { onDelete: "CASCADE"})
    @JoinColumn({name: "parent_id"})
    parent: ArticleCommentEntity;
    @Column({name: "parent_id", nullable: true})
    parentId: number | null;

    @OneToMany(() => ArticleCommentEntity, (comment) => comment.parent)
    children: ArticleCommentEntity[]; // 자식 댓글 목록

    @Column({ default: 0 })
    childrenCount: number;

    @Column({default: 0})
    likes: number;

    @Column({type: "text", nullable: false})
    content: string; // 댓글 내용

    @ManyToMany(() => PrameUserEntity, (user) => user.likedComments)
    @JoinTable({name: "article_comment_like", joinColumn: {name: "comment_id"}, inverseJoinColumn: {name: "user_id"}})
    likedUsers: PrameUserEntity[];

    @ManyToMany(() => PrameUserEntity, (user) => user.reportedComments)
    @JoinTable({name: "article_comment_report", joinColumn: {name: "comment_id"}, inverseJoinColumn: {name: "user_id"}})
    reportedUsers: PrameUserEntity[];

    @OneToMany(
      () => PrameUserCommentLikeEntity,
      (userCommentLikeEntity) => userCommentLikeEntity.comment,
    )
    likesList: PrameUserCommentLikeEntity[]; // 댓글 좋아요 목록

    @OneToMany(
      () => PrameUserCommentReportEntity,
      (userCommentReportEntity) => userCommentReportEntity.comment,
    )
    reportsList: PrameUserCommentReportEntity[]; // 댓글 신고 목록
}
