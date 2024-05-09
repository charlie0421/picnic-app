import { Module } from '@nestjs/common';
import { CommentService } from './comment.service';
import { CommentController } from './comment.controller';
import { TypeOrmModule } from "@nestjs/typeorm";
import {ArticleCommentEntity} from "../../../entities/article-comment.entity";
import {ArticleEntity} from "../../../entities/article.entity";
import {UserEntity} from "../../../entities/user.entity";
import {ArticleCommentLikeEntity} from "../../../entities/article-comment-like.entity";
import {ArticleCommentReportEntity} from "../../../entities/article-comment-report.entity";

@Module({
  imports: [TypeOrmModule.forFeature([ArticleCommentEntity, ArticleEntity, ArticleCommentLikeEntity, UserEntity, ArticleCommentEntity, ArticleCommentReportEntity])],
  controllers: [CommentController],
  providers: [CommentService],
})
export class CommentModule {}
