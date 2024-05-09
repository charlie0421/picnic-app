import { BaseEntity } from "./base_entity";
import { Column, Entity, JoinColumn, ManyToOne, Unique } from "typeorm";
import {VoteCommentEntity} from "./vote-comment.entity";
import {UserEntity} from "./user.entity";

@Entity("vote_comment_report")
@Unique(["voteId", "commentId"])
export class VoteCommentReportEntity extends BaseEntity {
  @ManyToOne(() => UserEntity, (vote) => vote.id)
  @JoinColumn({ name: "user_id" })
  user: UserEntity;
  @Column({ name: "user_id", nullable: false })
  user_id: number;

  @ManyToOne(() => VoteCommentEntity, (comment) => comment.id)
  @JoinColumn({ name: "user_id" })
  comment: VoteCommentEntity;
  @Column({ name: "comment_id", nullable: false })
  commentId: number;
}
