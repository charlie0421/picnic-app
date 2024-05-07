import {Injectable, Logger} from '@nestjs/common';
import {DataSource, Repository} from 'typeorm';
import {InjectDataSource, InjectRepository} from '@nestjs/typeorm';
import {paginate} from 'nestjs-typeorm-paginate';
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {CreateLibraryDto} from "./dto/create-library.dto";
import {PrameAlbumEntity} from "../../../entities/prame-album.entity";
import {GalleryArticleImageEntity} from "../../../entities/gallery_article_image.entity";

@Injectable()
export class AlbumService {
    private readonly logger = new Logger(AlbumService.name);

    constructor(
        @InjectRepository(GalleryArticleImageEntity) private articleImageRepository: Repository<GalleryArticleImageEntity>,
        @InjectRepository(PrameAlbumEntity) private albumRepository: Repository<PrameAlbumEntity>,
        @InjectRepository(PrameUserEntity) private userRepository: Repository<PrameUserEntity>,
        @InjectDataSource() private dataSource: DataSource,
    ) {
    }

    async findMine(id: number) {
        const queryBuilder = this.albumRepository.createQueryBuilder('album')
            .leftJoinAndSelect('album.images', 'image')
            .leftJoinAndSelect('album.user', 'user')
            .where('user.id = :id', {id})
            .select(['album', 'image', 'user.id', 'user.nickname'])

        return paginate<PrameAlbumEntity>(queryBuilder, {limit: 100, page: 1});
    }

    async addImageToLibrary(userId: number, albumId: number, imageId: number) {
        this.logger.log('addImageToLibrary userId: ' + userId + ' albumId: ' + albumId + ' imageId: ' + imageId);

        const result = await this.dataSource.transaction(async manager => {
            const albumRepository = manager.getRepository(PrameAlbumEntity);
            const articleImageRepository = manager.getRepository(GalleryArticleImageEntity);
            const userRepository = manager.getRepository(PrameUserEntity);

            const album = await albumRepository.findOne({
                relations: ['images'],
                where: {id: albumId}
            });

            const image = await articleImageRepository.findOne({where: {id: imageId}, relations : ['bookmarkUsers']});
            const user = await userRepository.findOne({where: {id: userId}});

            album.images.push(image);
            image.bookmarkUsers.push(user);

            await this.articleImageRepository.save(image);
            await this.albumRepository.save(album);
        });

        return result;
    }
}
