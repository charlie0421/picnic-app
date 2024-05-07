import { Module } from '@nestjs/common';
import { CommentService } from './comment.service';
import { CommentController } from './comment.controller';
import { TypeOrmModule } from "@nestjs/typeorm";
import {ArticleCommentEntity} from "../../../entities/article_comment.entity";
import {GalleryArticleEntity} from "../../../entities/gallery_article.entity";
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {PrameUserCommentLikeEntity} from "../../../entities/prame_user_comment_like.entity";
import {PrameUserCommentReportEntity} from "../../../entities/prame_user-comment-report.entity";

@Module({
  imports: [TypeOrmModule.forFeature([ArticleCommentEntity, GalleryArticleEntity, PrameUserCommentLikeEntity, PrameUserEntity, ArticleCommentEntity, PrameUserCommentReportEntity])],
  controllers: [CommentController],
  providers: [CommentService],
})
export class CommentModule {}
