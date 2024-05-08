import {Injectable, InternalServerErrorException, Logger} from '@nestjs/common';
import {Repository} from 'typeorm';
import {InjectRepository} from '@nestjs/typeorm';
import {IPaginationOptions, paginate} from 'nestjs-typeorm-paginate';
import {GalleryEntity} from "../../../entities/gallery.entity";
import {GalleryArticleEntity} from "../../../entities/article.entity";
import {ArticleCommentEntity} from "../../../entities/article_comment.entity";
import {GalleryArticleImageEntity} from "../../../entities/article_image.entity";

@Injectable()
export class GalleryService {
    private readonly logger = new Logger(GalleryService.name);

    constructor(
        @InjectRepository(GalleryEntity)
        private readonly galleryRepository: Repository<GalleryEntity>,
        @InjectRepository(GalleryArticleEntity)
        private readonly galleryArticleRepository: Repository<GalleryArticleEntity>,
        @InjectRepository(ArticleCommentEntity)
        private readonly articleCommentRepository: Repository<ArticleCommentEntity>,
        @InjectRepository(GalleryArticleImageEntity)
        private readonly galleryImageRepository: Repository<GalleryArticleImageEntity>,
    ) {
    }

    async findAll() {
        return this.paginateGallery(this.galleryRepository.createQueryBuilder('gallery').leftJoinAndSelect('gallery.celeb', 'celeb'));
    }

    async findGalleryByCeleb(celebId: number) {
        return this.paginateGallery(this.galleryRepository.createQueryBuilder('gallery').leftJoinAndSelect('gallery.celeb', 'celeb').where('celeb.id = :celebId', {celebId}));
    }

async findArticles(userId: number, galleryId: number, paginationOptions: IPaginationOptions, sort: string, order: 'ASC' | 'DESC') {
    try {
        const queryBuilder = this.galleryArticleRepository.createQueryBuilder('article')
            .leftJoinAndSelect('article.gallery', 'gallery')
            .leftJoinAndSelect('article.comments', 'comment')
            .leftJoinAndSelect('article.images', 'images')
            .leftJoinAndSelect('images.bookmarkUsers', 'bookmarkUsers')
            .select([
                'article.id',
                'article.titleKo',
                'article.titleEn',
                'article.content',
                'article.createdAt',
                'article.commentCount',
                'gallery.id',
                'gallery.titleKo',
                'gallery.titleEn',
                'gallery.cover',
                'bookmarkUsers',
            ])
            .where('gallery.id = :galleryId', {galleryId})
            .andWhere('article.deletedAt IS NULL')
            .groupBy('article.id');

        queryBuilder.addOrderBy(`article.${sort}`, order);

        const paginationResult = await paginate(queryBuilder, paginationOptions);

        for (const article of paginationResult.items) {
            const [images, mostLikedComment] = await Promise.all([
                this.galleryImageRepository.find({
                    relations: ['bookmarkUsers'],
                    where: {article: {id: article.id}},
                    order: {order: 'ASC'}
                }),
                this.getMostLikedComment(article.id, userId)
            ]);

            article.images = images;
            article.mostLikedComment = mostLikedComment;
        }

        return paginationResult;
    } catch (error) {
        this.logger.error(`An error occurred while fetching galleries: ${error.message}`, error.stack);
        throw new InternalServerErrorException('An error occurred while fetching galleries');
    }
}
    async findImages(galleryId: number) {
        return this.paginateGallery(this.galleryImageRepository.createQueryBuilder('galleryImage').leftJoinAndSelect('galleryImage.gallery', 'gallery').where('gallery.id = :galleryId', {galleryId}));
    }

    async findImagesMine(userId: number, galleryId: number) {
        return this.paginateGallery(this.galleryImageRepository.createQueryBuilder('galleryImage').leftJoinAndSelect('galleryImage.gallery', 'gallery').leftJoinAndSelect('galleryImage.users', 'user').having('user.id = :userId', {userId}));
    }

    private async paginateGallery(queryBuilder) {
        try {
            queryBuilder.orderBy('gallery.id', 'DESC');
            return paginate(queryBuilder, {limit: 100, page: 1});
        } catch (error) {
            this.logger.error(`An error occurred while fetching galleries: ${error.message}`, error.stack);
            throw new InternalServerErrorException('An error occurred while fetching galleries');
        }
    }

    private async getMostLikedComment(articleId: number, userId: number) {
        return this.articleCommentRepository.createQueryBuilder('comment')
            .leftJoinAndSelect('comment.user', 'commentUser')
            .select(['comment.id', 'comment.content', 'comment.likes', 'comment.createdAt', 'commentUser.id', 'commentUser.nickname', 'commentUser.profileImage'])
            .where('comment.article.id = :articleId', {articleId})
            .orderBy('comment.likes', 'DESC')
            .take(1)
            .getOne();
    }
}