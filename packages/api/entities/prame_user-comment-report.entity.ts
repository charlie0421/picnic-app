import { BaseEntity } from "./base_entity";
import { Column, Entity, JoinColumn, ManyToOne, Unique } from "typeorm";
import {PrameUserEntity} from "./prame-user.entity";
import {ArticleCommentEntity} from "./article_comment.entity";

@Entity("user_comment_report")
@Unique(["userId", "commentId"])
export class PrameUserCommentReportEntity extends BaseEntity {
  @ManyToOne(() => ArticleCommentEntity ,(comment) => comment.reportsList)
  @JoinColumn({ name: "comment_id" })
  comment: ArticleCommentEntity;
  @Column({ name: "comment_id", nullable: false })
  commentId: number;

  @ManyToOne(() => PrameUserEntity, (user) => user.userCommentReports)
  @JoinColumn({ name: "user_id" })
  user: PrameUserEntity;
  @Column({ name: "user_id", nullable: false })
  userId: number;
}
