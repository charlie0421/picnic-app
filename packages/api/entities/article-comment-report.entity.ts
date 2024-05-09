import { BaseEntity } from "./base_entity";
import { Column, Entity, JoinColumn, ManyToOne, Unique } from "typeorm";
import {UserEntity} from "./user.entity";
import {ArticleCommentEntity} from "./article-comment.entity";

@Entity("user_comment_report")
@Unique(["userId", "commentId"])
export class ArticleCommentReportEntity extends BaseEntity {
  @ManyToOne(() => ArticleCommentEntity ,(comment) => comment.reportsList)
  @JoinColumn({ name: "comment_id" })
  comment: ArticleCommentEntity;
  @Column({ name: "comment_id", nullable: false })
  commentId: number;

  @ManyToOne(() => UserEntity, (user) => user.userCommentReports)
  @JoinColumn({ name: "user_id" })
  user: UserEntity;
  @Column({ name: "user_id", nullable: false })
  userId: number;
}
