import { Module } from '@nestjs/common';
import { CommentService } from './comment.service';
import { CommentController } from './comment.controller';
import { TypeOrmModule } from "@nestjs/typeorm";
import {ArticleCommentEntity} from "../../../entities/article_comment.entity";
import {GalleryArticleEntity} from "../../../entities/article.entity";
import {UserEntity} from "../../../entities/user.entity";
import {PrameUserCommentLikeEntity} from "../../../entities/user_comment_like.entity";
import {UserCommentReportEntity} from "../../../entities/user-comment-report.entity";

@Module({
  imports: [TypeOrmModule.forFeature([ArticleCommentEntity, GalleryArticleEntity, PrameUserCommentLikeEntity, UserEntity, ArticleCommentEntity, UserCommentReportEntity])],
  controllers: [CommentController],
  providers: [CommentService],
})
export class CommentModule {}
