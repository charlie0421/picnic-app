import {Module} from '@nestjs/common';
import {TypeOrmModule} from '@nestjs/typeorm';
import { JwtStrategy } from '../../../common/auth/jwt.strategy';
import {GalleryEntity} from "../../../entities/gallery.entity";
import {UserEntity} from "../../../entities/user.entity";
import {CelebEntity} from "../../../entities/celeb.entity";
import {GalleryController} from "./gallery.controller";
import {GalleryService} from "./gallery.service";
import {ArticleEntity} from "../../../entities/article.entity";
import {ArticleImageEntity} from "../../../entities/article_image.entity";
import {ArticleCommentEntity} from "../../../entities/article_comment.entity";
import {AlbumEntity} from "../../../entities/album.entity";

@Module({
    imports: [TypeOrmModule.forFeature([CelebEntity,UserEntity,GalleryEntity, ArticleEntity,ArticleImageEntity, ArticleCommentEntity, AlbumEntity])],
    controllers: [GalleryController],
    providers: [GalleryService, JwtStrategy],
})
export class GalleryModule {
}
