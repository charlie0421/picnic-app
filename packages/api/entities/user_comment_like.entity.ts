import { Column, Entity, JoinColumn, ManyToOne, Unique } from "typeorm";
import { BaseEntity } from "./base_entity";
import {UserEntity} from "./user.entity";
import {ArticleCommentEntity} from "./article_comment.entity";

@Entity("user_comment_like")
@Unique(["userId", "commentId"])
export class UserCommentLikeEntity extends BaseEntity {
  @ManyToOne(() => UserEntity, (user) => user.id)
  @JoinColumn({ name: "user_id" })
  user: UserEntity;
  @Column({ name: "user_id", nullable: false })
  userId: number;

  @ManyToOne(() => ArticleCommentEntity, (comment) => comment.id)
  @JoinColumn({ name: "comment_id" })
  comment: ArticleCommentEntity;
  @Column({ name: "comment_id", nullable: false })
  commentId: number;
}
