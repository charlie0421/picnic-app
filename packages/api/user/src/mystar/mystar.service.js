"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MystarService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const class_transformer_1 = require("class-transformer");
const nestjs_typeorm_paginate_1 = require("nestjs-typeorm-paginate");
const typeorm_2 = require("typeorm");
const mystar_group_entity_1 = require("../../../libs/entities/src/entities/mystar-group.entity");
const mystar_member_entity_1 = require("../../../libs/entities/src/entities/mystar-member.entity");
const mystar_follower_entity_1 = require("../../../libs/entities/src/entities/mystar-follower.entity");
const mystar_reply_entity_1 = require("../../../libs/entities/src/entities/mystar-reply.entity");
const mystar_pick_entity_1 = require("../../../libs/entities/src/entities/mystar-pick.entity");
const mystar_follower_dto_1 = require("./dto/mystar-follower.dto");
const mystar_group_dto_1 = require("./dto/mystar-group.dto");
const mystar_member_dto_1 = require("./dto/mystar-member.dto");
const mystar_pick_list_dto_1 = require("./dto/mystar-pick-list.dto");
const mystar_artist_dto_1 = require("./dto/mystar-artist.dto");
const mystar_pick_dto_1 = require("./dto/mystar-pick.dto");
const user_entity_1 = require("../../../libs/entities/src/entities/user.entity");
const s3_service_1 = require("../s3/s3.service");
const config_1 = require("@nestjs/config");
let MystarService = class MystarService {
    constructor(mystarGroupRepository, mystarMemberRepository, mystarFollowerRepository, mystarReplyRepository, mystarPickRepository, usersRepository, s3Service, configService, connection) {
        this.mystarGroupRepository = mystarGroupRepository;
        this.mystarMemberRepository = mystarMemberRepository;
        this.mystarFollowerRepository = mystarFollowerRepository;
        this.mystarReplyRepository = mystarReplyRepository;
        this.mystarPickRepository = mystarPickRepository;
        this.usersRepository = usersRepository;
        this.s3Service = s3Service;
        this.configService = configService;
        this.connection = connection;
    }
    async findAll(options, sort, order) {
        const queryBuilder = this.mystarGroupRepository
            .createQueryBuilder('Group')
            .where('Group.deleted_at is null')
            .orderBy(sort, order);
        const group_info = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_group_dto_1.MystarGroupMainDto, group_info);
    }
    async getGroupsByName(options, name, sort, order) {
        const queryBuilder = this.mystarGroupRepository
            .createQueryBuilder('Group')
            .where('Group.group_name like :name', { name: `%${name}%` })
            .orWhere('Group.eng_group_name like :name', { name: `%${name}%` })
            .orderBy(sort, order);
        const groups = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_group_dto_1.MystarGroupMainDto, groups);
    }
    async getGroupsByNameDeprecated(name) {
        const mystarGroups = await this.mystarGroupRepository.find({
            where: [{ groupName: (0, typeorm_2.Like)(`%${name}%`) }, { engGroupName: (0, typeorm_2.Like)(`%${name}%`) }],
        });
        return (0, class_transformer_1.plainToInstance)(mystar_group_dto_1.MystarGroupDto, mystarGroups);
    }
    getGroupMemberList(id) {
        const member_info = this.mystarMemberRepository
            .createQueryBuilder('Member')
            .where('Member.deleted_at is null')
            .andWhere(`mystar_group_id = ${id}`)
            .getMany();
        return (0, class_transformer_1.plainToInstance)(mystar_member_dto_1.MystarMemberDto, member_info);
    }
    async getArtists(options, gender, sort, order) {
        const queryBuilder = this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where('Member.gender = :gender', { gender })
            .andWhere('Member.deleted_at is null')
            .orderBy(sort, order);
        const soloist_info = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_artist_dto_1.MystarArtistMainDto, soloist_info);
    }
    async getArtistsByName(options, name, gender, sort, order) {
        const queryBuilder = this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where('Member.gender = :gender', { gender })
            .andWhere('Member.deleted_at is null')
            .andWhere(new typeorm_2.Brackets((qb) => {
            qb.where(`Member.memberName like '%${name}%'`)
                .orWhere(`Member.engMemberName like '%${name}%'`)
                .orWhere(`group.groupName like '%${name}%'`)
                .orWhere(`group.engGroupName like '%${name}%'`);
        }))
            .orderBy(sort, order);
        const artists = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_artist_dto_1.MystarArtistMainDto, artists);
    }
    async getArtist(artistId) {
        const artist = await this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where(`Member.id = ${artistId}`)
            .getOne();
        if (artist === undefined) {
            throw new common_1.NotFoundException(`There is no artist where id: ${artistId}`);
        }
        return (0, class_transformer_1.plainToInstance)(mystar_artist_dto_1.MystarArtistDto, artist);
    }
    async getArtistsByNameDeprecated(gender, name) {
        const mystarMembers = await this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where(`Member.gender = '${gender}'`)
            .andWhere('Member.deleted_at is null')
            .andWhere(new typeorm_2.Brackets((qb) => {
            qb.where(`Member.memberName like '%${name}%'`)
                .orWhere(`Member.engMemberName like '%${name}%'`)
                .orWhere(`group.groupName like '%${name}%'`)
                .orWhere(`group.engGroupName like '%${name}%'`);
        }))
            .orderBy('Member.id', 'ASC')
            .getMany();
        return (0, class_transformer_1.plainToInstance)(mystar_artist_dto_1.MystarArtistDto, mystarMembers);
    }
    async getAllArticlesPagination(mystarMemberId, options, sort, order) {
        const queryBuilder = this.mystarFollowerRepository
            .createQueryBuilder('Follower')
            .select('Follower.id, Follower.title, Follower.contents, Follower.imgPath, Follower.videoPath, Follower.created_at')
            .innerJoinAndSelect('Follower.member', 'member')
            .innerJoinAndSelect('Follower.user', 'user')
            .where('Follower.deleted_at is null')
            .andWhere(`Follower.mystar_member_id = ${mystarMemberId}`)
            .orderBy(sort, order);
        const articles = await (0, nestjs_typeorm_paginate_1.paginateRaw)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_follower_dto_1.MystarArticlesPaginationForRawQueryDto, articles);
    }
    async getMyArticlesPagination(userId, mystarMemberId, options, sort, order) {
        const queryBuilder = this.mystarFollowerRepository
            .createQueryBuilder('Follower')
            .innerJoinAndSelect('Follower.member', 'member')
            .where('Follower.deleted_at is null')
            .andWhere(`Follower.users_id = ${userId}`)
            .andWhere(`Follower.mystar_member_id = ${mystarMemberId}`)
            .orderBy(sort, order);
        const myArticles = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_follower_dto_1.MystarArticlesPaginationDto, myArticles);
    }
    async getFollowerDetail(articleId) {
        const followerDetailInfo = await this.mystarFollowerRepository
            .createQueryBuilder('Follower')
            .loadRelationCountAndMap('Follower.replyCount', 'Follower.replies')
            .innerJoinAndSelect('Follower.member', 'member')
            .innerJoinAndSelect('Follower.user', 'user')
            .leftJoinAndSelect('Follower.replies', 'reply')
            .leftJoinAndSelect('reply.user', 'users')
            .where('Follower.deleted_at is null')
            .andWhere('reply.deleted_at is null')
            .andWhere(`Follower.id = ${articleId}`)
            .getOne();
        if (!followerDetailInfo) {
            throw new common_1.NotFoundException(`There is no article where id: ${articleId}`);
        }
        return (0, class_transformer_1.plainToInstance)(mystar_follower_dto_1.MystarFollowerDetailDto, followerDetailInfo);
    }
    async getFollowerReplyList(articleId, options, sort, order) {
        const queryBuilder = await this.mystarReplyRepository
            .createQueryBuilder('Reply')
            .leftJoinAndSelect('Reply.follower', 'follower')
            .leftJoinAndSelect('follower.member', 'member')
            .leftJoinAndSelect('Reply.user', 'user')
            .leftJoinAndSelect('Reply.reports', 'reports')
            .where('Reply.deleted_at is null')
            .andWhere(`Reply.mystar_follower_id = ${articleId}`)
            .orderBy(sort, order);
        const followerReplyInfo = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(mystar_follower_dto_1.MystarFollowerReplyMainDto, followerReplyInfo);
    }
    async createArticle(userId, artistId, title, contents, image, videoPath) {
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();
        const em = queryRunner.manager;
        try {
            const article = mystar_follower_entity_1.MystarFollower.from(userId, artistId, title, contents, image, videoPath);
            const savedArticle = await em.save(article);
            await queryRunner.commitTransaction();
            return savedArticle;
        }
        catch (e) {
            await queryRunner.rollbackTransaction();
        }
        finally {
            await queryRunner.release();
        }
    }
    async updateArticle(articleId, title, contents, image, videoPath) {
        const article = await this.mystarFollowerRepository.findOne(articleId);
        if (!article) {
            throw new common_1.NotFoundException(`There is no article where id: ${articleId}`);
        }
        if (title) {
            article.title = title;
        }
        if (contents) {
            article.contents = contents;
        }
        if (image) {
            article.imgPath = image;
        }
        if (videoPath) {
            article.videoPath = videoPath;
        }
        article.updated_at = new Date();
        await this.mystarFollowerRepository.save(article);
    }
    async isArticleMine(userId, articleId) {
        const article = await this.mystarFollowerRepository.findOne(articleId);
        if (article === undefined) {
            throw new common_1.NotFoundException(`There is no article where id: ${articleId}`);
        }
        return article.usersId === userId;
    }
    async uploadArticleImageByArtistId(image, artistId) {
        const unixTimeStampInSecond = Math.floor(Date.now() / 1000);
        const fileName = `follow_${unixTimeStampInSecond}.jpg`;
        const filePath = `path/mystarFollower/${artistId}/${fileName}`;
        await this.s3Service.uploadImage(this.configService.get('S3_BUCKET_FOLLOWER'), filePath, image);
        return fileName;
    }
    async getArticle(articleId) {
        const article = await this.mystarFollowerRepository.findOne(articleId);
        if (!article) {
            throw new common_1.NotFoundException(`There is no article where id: ${articleId}`);
        }
        return article;
    }
    async uploadArticleImageByArticleId(image, articleId) {
        const { mystarMemberId: artistId } = await this.getArticle(articleId);
        return this.uploadArticleImageByArtistId(image, artistId);
    }
    async deleteArticle(articleId) {
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();
        try {
            const updateResult = await this.mystarFollowerRepository.softDelete(articleId);
            if (updateResult.affected !== 1) {
                throw new common_1.BadRequestException('The article is not deleted');
            }
            await queryRunner.commitTransaction();
        }
        catch (e) {
            await queryRunner.rollbackTransaction();
            throw e;
        }
        finally {
            await queryRunner.release();
        }
    }
    async getMystarPickList(id) {
        const mystarPicks = await this.mystarPickRepository
            .createQueryBuilder('mystar_pick')
            .leftJoinAndSelect('mystar_pick.member', 'member')
            .where('mystar_pick.deleted_at is null')
            .andWhere(`mystar_pick.users_id = ${id}`)
            .getMany();
        return (0, class_transformer_1.plainToInstance)(mystar_pick_list_dto_1.MystarPickListDto, mystarPicks);
    }
    async isAlreadyPicked(userId, artistId) {
        const mystarPick = await this.mystarPickRepository.findOne({
            where: { usersId: userId, mystarMemberId: artistId },
        });
        return mystarPick !== undefined;
    }
    async hasAvailableMystarSlot(userId) {
        const user = await this.usersRepository.findOne(userId);
        if (user === undefined) {
            throw new common_1.NotFoundException(`There is no user where id: ${userId}`);
        }
        const mystarPicks = await this.mystarPickRepository.find({
            where: { usersId: userId },
        });
        return user.myOpenSlotCount - mystarPicks.length >= 1;
    }
    async followArtist(userId, artistId) {
        const mystarPick = mystar_pick_entity_1.MystarPick.mystarPick(userId, artistId);
        const savedMystarPick = await this.mystarPickRepository.save(mystarPick);
        return (0, class_transformer_1.plainToInstance)(mystar_pick_dto_1.MystarPickDto, savedMystarPick);
    }
    async validateThereAreAllMystarPicks(mystarPickIds) {
        const mystarPicks = await this.mystarPickRepository.find({
            where: { id: (0, typeorm_2.In)(mystarPickIds), deleted_at: (0, typeorm_2.IsNull)() },
        });
        const foundMystarPickIds = mystarPicks.map((it) => it.id);
        const notFoundedMystarPickIds = mystarPickIds.filter((it) => !foundMystarPickIds.includes(it));
        if (notFoundedMystarPickIds.length > 0) {
            throw new common_1.BadRequestException(`There is/are no mystar picks where id(s): ${notFoundedMystarPickIds}`);
        }
    }
    async validateUserOwnsMystarPicks(userId, mystarPickIds) {
        const mystarPicks = await this.mystarPickRepository.findByIds(mystarPickIds);
        for (const mystarPick of mystarPicks) {
            if (mystarPick.usersId !== userId) {
                throw new common_1.ForbiddenException(`Mystar pick(${mystarPick.id}) doesn't belong to user`);
            }
        }
    }
    async unfollowArtists(mystarPickIds) {
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();
        try {
            const updateResult = await this.mystarPickRepository.softDelete(mystarPickIds);
            if (updateResult.affected !== mystarPickIds.length) {
                throw new common_1.BadRequestException('Any element is not deleted');
            }
            await queryRunner.commitTransaction();
        }
        catch (e) {
            await queryRunner.rollbackTransaction();
            throw e;
        }
        finally {
            await queryRunner.release();
        }
    }
};
MystarService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(mystar_group_entity_1.MystarGroup)),
    __param(1, (0, typeorm_1.InjectRepository)(mystar_member_entity_1.MystarMember)),
    __param(2, (0, typeorm_1.InjectRepository)(mystar_follower_entity_1.MystarFollower)),
    __param(3, (0, typeorm_1.InjectRepository)(mystar_reply_entity_1.MystarReply)),
    __param(4, (0, typeorm_1.InjectRepository)(mystar_pick_entity_1.MystarPick)),
    __param(5, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        s3_service_1.S3Service,
        config_1.ConfigService,
        typeorm_2.Connection])
], MystarService);
exports.MystarService = MystarService;
//# sourceMappingURL=mystar.service.js.map