import {Module} from '@nestjs/common';
import {AlbumService} from './album.service';
import {AlbumController} from './albumController';
import {TypeOrmModule} from '@nestjs/typeorm';
import {JwtStrategy} from '../../../common/auth/jwt.strategy';
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {GalleryArticleImageEntity} from "../../../entities/gallery_article_image.entity";
import {PrameAlbumEntity} from "../../../entities/prame-album.entity";

@Module({
    imports: [TypeOrmModule.forFeature([PrameAlbumEntity,PrameUserEntity,GalleryArticleImageEntity])],
    controllers: [AlbumController],
    providers: [AlbumService, JwtStrategy],
})
export class AlbumModule {
}
