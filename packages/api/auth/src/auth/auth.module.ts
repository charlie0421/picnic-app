import { Module } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { S3Module } from '../../../common/s3/s3.module';
import { SesModule } from '../../../common/ses/ses.module';
import { CelebEntity } from '../../../entities/celeb.entity';
import { LocalStrategy } from '../../../common/auth/local.strategy';
import { UserEntity } from '../../../entities/user.entity';
import { UsersService } from '../../../user/src/users/users.service';
import { CelebBannerEntity } from '../../../entities/celeb_banner.entity';
import { GalleryEntity } from '../../../entities/gallery.entity';
import { ArticleEntity } from '../../../entities/article.entity';
import { VoteEntity } from '../../../entities/vote.entity';
import { ArticleImageEntity } from '../../../entities/article_image.entity';
import { AlbumEntity } from '../../../entities/album.entity';
import { ArticleCommentEntity } from '../../../entities/article_comment.entity';
import { UserCommentLikeEntity } from '../../../entities/user_comment_like.entity';
import { UserCommentReportEntity } from '../../../entities/user-comment-report.entity';
import { VoteItemPickEntity } from '../../../entities/vote_item_pick.entity';
import { VoteItemEntity } from '../../../entities/vote_item.entity';
import { PointHistoryEntity } from '../../../entities/point_history.entity';
import { MystarMemberEntity } from '../../../entities/mystar-member.entity';
import { MystarGroupEntity } from '../../../entities/mystar-group.entity';
import { VoteCommentEntity } from '../../../entities/vote_comment.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserEntity, CelebEntity, CelebBannerEntity, GalleryEntity, ArticleEntity, ArticleImageEntity, AlbumEntity, ArticleCommentEntity, UserCommentLikeEntity,UserCommentReportEntity,VoteItemPickEntity,VoteItemEntity,PointHistoryEntity,MystarMemberEntity,MystarGroupEntity,VoteCommentEntity,
      VoteEntity]),
    PassportModule,
    JwtModule.register({}),
    SesModule,
    S3Module,
  ],
  controllers: [AuthController],
  providers: [AuthService, LocalStrategy, JwtService, UsersService],
})
export class AuthModule {
}
