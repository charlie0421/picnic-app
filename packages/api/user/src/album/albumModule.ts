import {Module} from '@nestjs/common';
import {AlbumService} from './album.service';
import {AlbumController} from './albumController';
import {TypeOrmModule} from '@nestjs/typeorm';
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {GalleryArticleImageEntity} from "../../../entities/gallery_article_image.entity";
import {PrameAlbumEntity} from "../../../entities/prame-album.entity";
import { JwtStrategy } from 'api-auth/dist/auth/src/auth/jwt.strategy';

@Module({
    imports: [TypeOrmModule.forFeature([PrameAlbumEntity,PrameUserEntity,GalleryArticleImageEntity])],
    controllers: [AlbumController],
    providers: [AlbumService, JwtStrategy],
})
export class AlbumModule {
}
