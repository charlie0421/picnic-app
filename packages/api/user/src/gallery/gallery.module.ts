import {Module} from '@nestjs/common';
import {TypeOrmModule} from '@nestjs/typeorm';
import {JwtStrategy} from '../../../common/auth/jwt.strategy';
import {GalleryEntity} from "../../../entities/gallery.entity";
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {Celeb} from "../../../entities/celeb.entity";
import {GalleryController} from "./gallery.controller";
import {GalleryService} from "./gallery.service";
import {GalleryArticleEntity} from "../../../entities/gallery_article.entity";
import {GalleryArticleImageEntity} from "../../../entities/gallery_article_image.entity";
import {ArticleCommentEntity} from "../../../entities/article_comment.entity";
import {PrameAlbumEntity} from "../../../entities/prame-album.entity";

@Module({
    imports: [TypeOrmModule.forFeature([Celeb,PrameUserEntity,GalleryEntity, GalleryArticleEntity,GalleryArticleImageEntity, ArticleCommentEntity, PrameAlbumEntity])],
    controllers: [GalleryController],
    providers: [GalleryService, JwtStrategy],
})
export class GalleryModule {
}
