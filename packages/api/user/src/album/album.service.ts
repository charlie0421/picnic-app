import {Injectable, Logger} from '@nestjs/common';
import {DataSource, Repository} from 'typeorm';
import {InjectDataSource, InjectRepository} from '@nestjs/typeorm';
import {paginate} from 'nestjs-typeorm-paginate';
import {UserEntity} from "../../../entities/user.entity";
import {CreateLibraryDto} from "./dto/create-library.dto";
import {AlbumEntity} from "../../../entities/album.entity";
import {ArticleImageEntity} from "../../../entities/article_image.entity";

@Injectable()
export class AlbumService {
    private readonly logger = new Logger(AlbumService.name);

    constructor(
        @InjectRepository(ArticleImageEntity) private articleImageRepository: Repository<ArticleImageEntity>,
        @InjectRepository(AlbumEntity) private albumRepository: Repository<AlbumEntity>,
        @InjectRepository(UserEntity) private userRepository: Repository<UserEntity>,
        @InjectDataSource() private dataSource: DataSource,
    ) {
    }

    async findMine(id: number) {
        const queryBuilder = this.albumRepository.createQueryBuilder('album')
            .leftJoinAndSelect('album.images', 'image')
            .leftJoinAndSelect('album.user', 'user')
            .where('user.id = :id', {id})
            .select(['album', 'image', 'user.id', 'user.nickname'])

        return paginate<AlbumEntity>(queryBuilder, {limit: 100, page: 1});
    }

    async addImageToLibrary(userId: number, albumId: number, imageId: number) {
        this.logger.log('addImageToLibrary userId: ' + userId + ' albumId: ' + albumId + ' imageId: ' + imageId);

        const result = await this.dataSource.transaction(async manager => {
            const albumRepository = manager.getRepository(AlbumEntity);
            const articleImageRepository = manager.getRepository(ArticleImageEntity);
            const userRepository = manager.getRepository(UserEntity);

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
