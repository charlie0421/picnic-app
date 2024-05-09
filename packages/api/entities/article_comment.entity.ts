import {Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany} from "typeorm";

import {BaseEntity} from "./base_entity";
import {ArticleEntity} from "./article.entity";
import {UserEntity} from "./user.entity";
import {UserCommentLikeEntity} from "./user_comment_like.entity";
import {UserCommentReportEntity} from "./user-comment-report.entity";

@Entity("article_comment")
export class ArticleCommentEntity extends BaseEntity {
    @ManyToOne(() => ArticleEntity, (article) => article.id)
    @JoinColumn({name: "article_id"})
    article: ArticleEntity;
    @Column({name: "article_id"})
    articleId: number;

    @ManyToOne(() => UserEntity, (user) => user.id)
    @JoinColumn({name: "user_id"})
    user: UserEntity;
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

    @ManyToMany(() => UserEntity, (user) => user.likedComments)
    @JoinTable({name: "article_comment_like", joinColumn: {name: "comment_id"}, inverseJoinColumn: {name: "user_id"}})
    likedUsers: UserEntity[];

    @ManyToMany(() => UserEntity, (user) => user.reportedComments)
    @JoinTable({name: "article_comment_report", joinColumn: {name: "comment_id"}, inverseJoinColumn: {name: "user_id"}})
    reportedUsers: UserEntity[];

    @OneToMany(
      () => UserCommentLikeEntity,
      (userCommentLikeEntity) => userCommentLikeEntity.comment,
    )
    likesList: UserCommentLikeEntity[]; // 댓글 좋아요 목록

    @OneToMany(
      () => UserCommentReportEntity,
      (userCommentReportEntity) => userCommentReportEntity.comment,
    )
    reportsList: UserCommentReportEntity[]; // 댓글 신고 목록
}
