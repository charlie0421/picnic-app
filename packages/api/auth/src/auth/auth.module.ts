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
import { BannerEntity } from '../../../entities/banner.entity';
import { GalleryEntity } from '../../../entities/gallery.entity';
import { ArticleEntity } from '../../../entities/article.entity';
import { VoteEntity } from '../../../entities/vote.entity';
import { ArticleImageEntity } from '../../../entities/article-image.entity';
import { AlbumEntity } from '../../../entities/album.entity';
import { ArticleCommentEntity } from '../../../entities/article-comment.entity';
import { ArticleCommentLikeEntity } from '../../../entities/article-comment-like.entity';
import { ArticleCommentReportEntity } from '../../../entities/article-comment-report.entity';
import { VoteItemPickEntity } from '../../../entities/vote-item-pick.entity';
import { VoteItemEntity } from '../../../entities/vote-item.entity';
import { PointHistoryEntity } from '../../../entities/point_history.entity';
import { MystarMemberEntity } from '../../../entities/mystar-member.entity';
import { MystarGroupEntity } from '../../../entities/mystar-group.entity';
import { VoteCommentEntity } from '../../../entities/vote-comment.entity';
import { JwtStrategy } from '../../../common/auth/jwt.strategy';
import { UserAgreementEntity } from '../../../entities/user_agreement.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserEntity, UserAgreementEntity,CelebEntity, BannerEntity, GalleryEntity, ArticleEntity, ArticleImageEntity, AlbumEntity, ArticleCommentEntity, ArticleCommentLikeEntity,ArticleCommentReportEntity,VoteItemPickEntity,VoteItemEntity,PointHistoryEntity,MystarMemberEntity,MystarGroupEntity,VoteCommentEntity,
      VoteEntity]),
    PassportModule,
    JwtModule.register({}),
    SesModule,
    S3Module,
  ],
  controllers: [AuthController],
  providers: [AuthService, LocalStrategy, JwtStrategy, UsersService],
})
export class AuthModule {
}
