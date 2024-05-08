import {Module} from '@nestjs/common';
import {AlbumService} from './album.service';
import {AlbumController} from './albumController';
import {TypeOrmModule} from '@nestjs/typeorm';
import {UserEntity} from "../../../entities/user.entity";
import {GalleryArticleImageEntity} from "../../../entities/article_image.entity";
import {AlbumEntity} from "../../../entities/album.entity";
import { JwtStrategy } from '../../../common/auth/jwt.strategy';

@Module({
    imports: [TypeOrmModule.forFeature([AlbumEntity,UserEntity,GalleryArticleImageEntity])],
    controllers: [AlbumController],
    providers: [AlbumService, JwtStrategy],
})
export class AlbumModule {
}
