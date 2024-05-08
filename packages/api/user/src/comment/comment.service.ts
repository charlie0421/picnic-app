import {Injectable, Logger} from '@nestjs/common';
import {CreateCommentDto} from './dto/create-comment.dto';
import {UpdateCommentDto} from './dto/update-comment.dto';
import {InjectDataSource, InjectRepository} from '@nestjs/typeorm';
import {DataSource, Repository} from 'typeorm';
import {paginate} from 'nestjs-typeorm-paginate';
import {ArticleCommentEntity} from "../../../entities/article_comment.entity";
import {GalleryArticleEntity} from "../../../entities/article.entity";
import {PrameUserCommentLikeEntity} from "../../../entities/user_comment_like.entity";
import {UserCommentReportEntity} from "../../../entities/user-comment-report.entity";

@Injectable()
export class CommentService {
    private readonly logger = new Logger(CommentService.name);

    constructor(
        @InjectRepository(ArticleCommentEntity)
        private commentRepository: Repository<ArticleCommentEntity>,
        @InjectRepository(GalleryArticleEntity)
        private articleRepository: Repository<GalleryArticleEntity>,
        @InjectRepository(PrameUserCommentLikeEntity)
        private userCommentLikeRepository: Repository<PrameUserCommentLikeEntity>,
        @InjectRepository(UserCommentReportEntity)
        private userCommentReportRepository: Repository<UserCommentReportEntity>,
        @InjectDataSource() private dataSource: DataSource,
    ) {
    }

    async createComment(dto: CreateCommentDto) {
        try {
            const comment = this.commentRepository.create({
                content: dto.content,
                parentId: dto.parentId,
                articleId: dto.articleId,
                userId: dto.userId,
            });

            this.articleRepository.increment({id: dto.articleId}, 'commentCount', 1);

            return this.commentRepository.save(comment);
        } catch (e) {
            this.logger.error(e);
            throw e;
        }
    }

    async findAll(userId: number, articleId: number, page: number, limit: number , sort: string = 'comment.created_at', order: string = 'DESC') {
        const queryBuilder = this.commentRepository.createQueryBuilder('comment');
        queryBuilder
            .leftJoinAndMapOne(
                'comment.myLike',
                PrameUserCommentLikeEntity,
                'myLike',
                'comment.id = `myLike`.comment_id and comment.userId = `myLike`.user_id',
            )
            .leftJoinAndMapOne(
                'comment.report',
                UserCommentReportEntity,
                'report_myReport',
                'comment.id = `report_myReport`.comment_id and report_myReport.user_id = :userId',
                {userId},
            )
            .leftJoinAndSelect('comment.user', 'user', 'user.id = comment.user_id')

            // children
            .leftJoinAndMapMany(
                'comment.children',
                ArticleCommentEntity,
                'children',
                'children.parent_id = comment.id',
                (order) => order.addOrderBy('children.createdAt', 'DESC'),
            )
            .loadRelationCountAndMap(
                'comment.childrenCount',
                'comment.children',
                'children',
                qb => qb.andWhere('deleted_at IS NULL'),
            )
            .addSelect(subQuery => {
                return subQuery
                    .select('COUNT(*)', 'childrenCount')
                    .from(ArticleCommentEntity, 'children')
                    .where('children.parent_id = comment.id')
                    .andWhere('children.deleted_at IS NULL')
            })
            .leftJoinAndMapOne(
                'children.myLike',
                PrameUserCommentLikeEntity,
                'children_myLike',
                'children.id = `children_myLike`.comment_id and children.userId = `children_myLike`.user_id',
            )
            .leftJoinAndSelect(
                'children.user',
                'children_user',
                'children_user.id = children.user_id',
            ) // Added this line
            .leftJoinAndMapOne(
                'children.myReport',
                UserCommentReportEntity,
                'children_myReport',
                'children.id = `children_myReport`.comment_id and children.userId = `children_myReport`.user_id',
            )
            .andWhere('comment.article.id = :articleId', {articleId})
            .andWhere('comment.parent_id IS NULL')
            .andWhere('report_myReport.id IS NULL')
            .andWhere('children_myReport.id IS NULL')
            .select([
                'comment',
                'myLike',
                'children.id',
                'children.content',
                'children.likes',
                'children.parentId',
                'children.createdAt',
                'children_user.id',
                'children_user.nickname',
                'children_user.profileImage',
                'children_myLike',
                'report_myReport',
                'children_myReport',
                'user.id',
                'user.nickname',
                'user.profileImage',
                // 'children.childrenCount'
            ])
            .orderBy(sort, order == 'DESC' ? 'DESC' : 'ASC');

        const results = await paginate(queryBuilder, {page, limit});

        results.meta.totalItems += results.items.reduce((sum, item) => sum + item?.childrenCount, 0);

        return results;
    }

    findPopular(articleId: number) {
        const queryBuilder = this.commentRepository.createQueryBuilder('comment');
        queryBuilder
            .andWhere('comment.episode_id = :articleId', {articleId})
            .leftJoinAndSelect('comment.user', 'user', 'user.id = comment.user_id')
            .select(['comment', 'user'])
            .limit(1)
            .orderBy('comment.likes', 'DESC');

        return paginate(queryBuilder, {page: 1, limit: 1});
    }

    async addLike(userId: number, commentId: number) {
        try {
            return await this.dataSource.transaction(
                async (transactionalEntityManager) => {
                    const comment = await this.userCommentLikeRepository.findOne({
                        where: {
                            user: {id: userId},
                            comment: {id: commentId},
                        },
                        withDeleted: true,
                    });
                    if (comment != null && comment.deletedAt != null) {
                        await transactionalEntityManager.restore(
                            PrameUserCommentLikeEntity,
                            comment.id,
                        );
                    } else {
                        await transactionalEntityManager.insert(PrameUserCommentLikeEntity, {
                            userId,
                            commentId,
                        });
                    }

                    return await transactionalEntityManager.increment(
                        ArticleCommentEntity,
                        {id: commentId},
                        'likes',
                        1,
                    );
                },
            );
        } catch (e) {
            this.logger.error(e);
            throw e;
        }
    }

    async removeLike(userId: number, commentId: number) {
        try {
            return await this.dataSource.transaction(
                async (transactionalEntityManager) => {
                    const comment = await this.userCommentLikeRepository.softDelete({
                        user: {id: userId},
                        comment: {id: commentId},
                    });

                    return await transactionalEntityManager.decrement(
                        ArticleCommentEntity,
                        {id: commentId},
                        'likes',
                        1,
                    );
                },
            );
        } catch (e) {
            this.logger.error(e);
            throw e;
        }
    }

    async addReport(userId: number, commentId: number) {
        try {
            const userCommentReportEntity = new UserCommentReportEntity();
            userCommentReportEntity.userId = userId;
            userCommentReportEntity.commentId = commentId;
            if (userCommentReportEntity.userId == userCommentReportEntity.commentId) {
                throw new Error('자기 자신을 신고할 수 없습니다.');
            }
            return await this.userCommentReportRepository.save(
                userCommentReportEntity,
            );
        } catch (e) {
            this.logger.error(e);
            throw e;
        }
    }

    findOne(id: number) {
        return `This action returns a #${id} comment`;
    }

    update(id: number, updateCommentDto: UpdateCommentDto) {
        return `This action updates a #${id} comment`;
    }

    remove(id: number) {
        return `This action removes a #${id} comment`;
    }
}
