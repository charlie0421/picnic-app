import {Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany} from "typeorm";

import {BaseEntity} from "./base_entity";
import {UserEntity} from "./user.entity";
import {UserCommentLikeEntity} from "./user_comment_like.entity";
import {UserCommentReportEntity} from "./user-comment-report.entity";
import {VoteEntity} from "./vote.entity";

@Entity("vote_comment")
export class VoteCommentEntity extends BaseEntity {
    @ManyToOne(() => VoteEntity, (vote) => vote.id)
    @JoinColumn({name: "vote_id"})
    vote: VoteEntity;
    @Column({name: "vote_id"})
    voteId: number;

    @ManyToOne(() => UserEntity, (user) => user.id)
    @JoinColumn({name: "user_id"})
    user: UserEntity;
    @Column({name: "user_id"})
    userId: number;

    @ManyToOne(() => VoteCommentEntity, (voteComment) => voteComment.children, {onDelete: "CASCADE"})
    @JoinColumn({name: "parent_id"})
    parent: VoteCommentEntity;
    @Column({name: "parent_id", nullable: true})
    parentId: number | null;

    @OneToMany(() => VoteCommentEntity, (comment) => comment.parent)
    children: VoteCommentEntity[]; // 자식 댓글 목록

    @Column({default: 0})
    childrenCount: number;

    @Column({default: 0})
    likes: number;

    @Column({type: "text", nullable: false})
    content: string; // 댓글 내용

    @ManyToMany(() => UserEntity, (user) => user.likedComments)
    @JoinTable({name: "vote_comment_like", joinColumn: {name: "comment_id"}, inverseJoinColumn: {name: "user_id"}})
    likedUsers: UserEntity[];

    @ManyToMany(() => UserEntity, (user) => user.reportedComments)
    @JoinTable({name: "vote_comment_report", joinColumn: {name: "comment_id"}, inverseJoinColumn: {name: "user_id"}})
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
