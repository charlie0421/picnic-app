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
exports.VoteService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const moment = require("moment");
const nestjs_typeorm_paginate_1 = require("nestjs-typeorm-paginate");
const typeorm_2 = require("typeorm");
const vote_entity_1 = require("../../../libs/entities/src/entities/vote.entity");
const vote_item_entity_1 = require("../../../libs/entities/src/entities/vote-item.entity");
const vote_reply_entity_1 = require("../../../libs/entities/src/entities/vote-reply.entity");
const vote_detail_dto_1 = require("./dto/vote-detail.dto");
const vote_list_dto_1 = require("./dto/vote-list.dto");
const vote_reply_dto_1 = require("./dto/vote-reply.dto");
const user_entity_1 = require("../../../libs/entities/src/entities/user.entity");
const vote_pick_entity_1 = require("../../../libs/entities/src/entities/vote-pick.entity");
const point_sst_entity_1 = require("../../../libs/entities/src/entities/point-sst.entity");
const sub_sst_entity_1 = require("../../../libs/entities/src/entities/sub-sst.entity");
const enums_1 = require("../users/enums");
const vote_pick_for_sst_vote_response_dto_1 = require("./dto/vote-pick-for-sst-vote-response.dto");
const point_right_entity_1 = require("../../../libs/entities/src/entities/point-right.entity");
const sub_right_entity_1 = require("../../../libs/entities/src/entities/sub-right.entity");
const vote_pick_for_right_vote_response_dto_1 = require("./dto/vote-pick-for-right-vote-response.dto");
const class_transformer_1 = require("class-transformer");
let VoteService = class VoteService {
    constructor(voteRepository, voteItemRepository, voteReplyRepository, userRepository, votePickRepository, connection) {
        this.voteRepository = voteRepository;
        this.voteItemRepository = voteItemRepository;
        this.voteReplyRepository = voteReplyRepository;
        this.userRepository = userRepository;
        this.votePickRepository = votePickRepository;
        this.connection = connection;
    }
    async findAll(options, category, activeOnly, includeArtists, isMainTop, sort, order) {
        const current = moment().format();
        const queryBuilder = this.voteRepository
            .createQueryBuilder('vote')
            .loadRelationCountAndMap('vote.replycount', 'vote.replies')
            .where('vote.deleted_at is null');
        if (includeArtists) {
            queryBuilder.leftJoinAndSelect('vote.items', 'vote_item').andWhere('vote_item.deleted_at is null');
        }
        if (activeOnly) {
            queryBuilder.andWhere(`vote.visible_at <= '${current}'`).andWhere(`vote.stop_at >= '${current}'`);
        }
        else {
            queryBuilder.andWhere(`vote.visible_at <= '${current}'`);
        }
        if (category.includes(','))
            queryBuilder.andWhere(`vote.vote_category in (:categories)`, { categories: category.split(',') });
        else
            queryBuilder.andWhere(`vote.vote_category = '${category}'`);
        if (isMainTop) {
            queryBuilder.orderBy(`vote.main_top`, `DESC`);
            queryBuilder.addOrderBy(sort, order);
        }
        else {
            queryBuilder.orderBy(sort, order);
        }
        const vote_info = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(vote_list_dto_1.VoteMainDto, vote_info);
    }
    async getMainPageVotes() {
        const em = (0, typeorm_2.getManager)();
        const current = moment().format();
        const voteQuery = `select *
                           from ((select 1 as status, a.*
                                  from (select *
                                        from vote
                                        where visible_at = start_at
                                          and visible_at <= '${current}'
                                          and stop_at >= '${current}'
                                          and deleted_at is null
                                        order by start_at desc) a)
                                 UNION ALL
                                 (select 2 as status, b.*
                                  from (select *
                                        from vote
                                        where visible_at <> start_at
                                          and visible_at <= '${current}'
                                          and stop_at >= '${current}'
                                          and deleted_at is null) b)) c
                           order by c.main_top desc, c.status, c.start_at desc;`;
        const votes = await em.query(voteQuery);
        const voteIds = votes.map((it) => it.id).join(',');
        const replyCountQuery = `
            select vote_id, count(*) as cnt
            from vote_reply
            where vote_id in (${voteIds})
              and deleted_at is null
            group by vote_id;
        `;
        const voteReplyCounts = await em.query(replyCountQuery);
        const voteItemQuery = `
            select *
            from vote_item
            where vote_id in (${voteIds})
              and deleted_at is null
            order by id;
        `;
        const voteItems = await em.query(voteItemQuery);
        return this.toVoteMainDto(votes, voteReplyCounts, voteItems);
    }
    toVoteMainDto(votes, voteReplyCounts, voteItems) {
        return votes.map((it) => {
            var _a;
            const vote = new vote_list_dto_1.VoteDto();
            vote.id = it.id;
            vote.vote_title = it.vote_title;
            vote.eng_vote_title = it.eng_vote_title;
            vote.vote_category = it.vote_category;
            vote.main_img = it.main_img;
            vote.vote_content = it.vote_content;
            vote.eng_vote_content = it.eng_vote_content;
            vote.vote_episode = it.vote_episode;
            vote.eng_vote_episode = it.eng_vote_episode;
            vote.start_at = it.start_at;
            vote.stop_at = it.stop_at;
            vote.visible_at = it.visible_at;
            vote.replycount = ((_a = voteReplyCounts.find((voteReplyCount) => voteReplyCount.vote_id === it.id)) === null || _a === void 0 ? void 0 : _a.cnt) || 0;
            vote.items = voteItems
                .filter((voteItem) => voteItem.vote_id === it.id)
                .map((value) => {
                const voteItem = new vote_list_dto_1.VoteItemDto();
                voteItem.id = value.id;
                voteItem.item_img = this.toFullImagePath(value);
                return voteItem;
            });
            return vote;
        });
    }
    toFullImagePath(value) {
        if (value.item_img === null) {
            return `${process.env.CDN_PATH_IMAGE}/profile_base2.png`;
        }
        else {
            return `${process.env.CDN_PATH_VOTE_ITEM}/${value.id}/${value.item_img}`;
        }
    }
    getVoteDetail(id) {
        const vote_info = this.voteRepository
            .createQueryBuilder('vote')
            .loadRelationCountAndMap('vote.replycount', 'vote.replies')
            .where('vote.deleted_at is null')
            .andWhere(`vote.id = ${id}`)
            .getOne();
        return (0, class_transformer_1.plainToInstance)(vote_detail_dto_1.VoteDetailtDto, vote_info);
    }
    async getVoteDetailList(id, options, sort, order) {
        const queryBuilder = this.voteItemRepository
            .createQueryBuilder('vote_item')
            .where('vote_item.deleted_at is null')
            .andWhere(`vote_item.vote_id = ${id}`)
            .orderBy(sort, order);
        const voteItem = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(vote_detail_dto_1.VoteDetailListMainDto, voteItem);
    }
    async getVoteReplyList(id, options, sort, order) {
        const queryBuilder = this.voteReplyRepository
            .createQueryBuilder('vote_reply')
            .withDeleted()
            .innerJoinAndSelect('vote_reply.user', 'user')
            .where('vote_reply.deleted_at is null')
            .andWhere(`vote_reply.vote_id = ${id}`)
            .orderBy(sort, order);
        const vote_reply = await (0, nestjs_typeorm_paginate_1.paginate)(queryBuilder, options);
        return (0, class_transformer_1.plainToInstance)(vote_reply_dto_1.VoteReplyMainDto, vote_reply);
    }
    async postVoteReply(voteId, userId, reply_text) {
        const vote = await this.voteRepository.findOne(voteId);
        if (!vote) {
            throw new common_1.NotFoundException('vote not found');
        }
        const comment = await this.voteReplyRepository.create({
            voteId: voteId,
            usersId: userId,
            replyText: reply_text,
            created_at: new Date(),
            updated_at: new Date(),
        });
        await this.voteReplyRepository.save(comment);
        return { statusCode: 201, message: 'Created' };
    }
    async isVoteOver(voteId) {
        const vote = await this.voteRepository.findOne(voteId);
        return vote.stop_at <= new Date();
    }
    async isThereVote(voteId) {
        const vote = await this.voteRepository.findOne(voteId);
        return vote !== undefined;
    }
    async isThereVoteItem(voteId, voteItemId) {
        const voteItem = await this.voteItemRepository.findOne({
            where: { id: voteItemId, vote_id: voteId },
        });
        return voteItem !== undefined;
    }
    async isUserSstLessThan(userId, sst) {
        const user = await this.userRepository.findOne(userId);
        if (user === undefined) {
            throw new common_1.NotFoundException(`There is no user where id: ${userId}`);
        }
        return user.pointSst < sst;
    }
    async isUserRightLessThan(userId, right) {
        const user = await this.userRepository.findOne(userId);
        if (user === undefined) {
            throw new common_1.NotFoundException(`There is no user where id: ${userId}`);
        }
        return user.pointRight < right;
    }
    async isTotalRightAmountOverTwo(voteId, userId) {
        const votePicks = await this.votePickRepository.find({
            where: { voteId: voteId, usersId: userId },
        });
        let totalRightAmount = 0;
        votePicks.forEach((value) => (totalRightAmount += value.rightAmount));
        return totalRightAmount > 2;
    }
    async voteUsingSst(userId, voteId, voteItemId, sst) {
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();
        const em = queryRunner.manager;
        try {
            const user = await this.userRepository.findOne({
                where: { id: userId },
            });
            if (user === undefined) {
                throw new common_1.NotFoundException(`There is no user where id: ${userId}`);
            }
            user.pointSst -= Math.abs(sst);
            user.updated_at = new Date();
            await em.save(user);
            const votePick = vote_pick_entity_1.VotePick.sstVotePick(userId, voteId, voteItemId, Math.abs(sst));
            await em.save(votePick);
            const pointSst = new point_sst_entity_1.PointSst();
            pointSst.usersId = userId;
            pointSst.amount = Math.abs(sst);
            pointSst.type = point_sst_entity_1.PointSstType.VOTE;
            pointSst.votePickId = votePick.id;
            pointSst.created_at = new Date();
            pointSst.updated_at = new Date();
            await em.save(pointSst);
            const voteItem = await this.voteItemRepository.findOne({
                where: { id: voteItemId },
            });
            if (voteItem === undefined) {
                throw new common_1.NotFoundException(`There is no vote item where id: ${voteItemId}`);
            }
            voteItem.vote_total += Math.abs(sst);
            voteItem.updated_at = new Date();
            await em.save(voteItem);
            if (user.grade !== enums_1.UserGrade.PLAY) {
                const subSst = new sub_sst_entity_1.SubSst();
                subSst.usersId = userId;
                subSst.usersRole = user.grade;
                subSst.amount = Math.abs(sst);
                subSst.type = sub_sst_entity_1.SubSstType.VOTE;
                subSst.voteId = voteId;
                subSst.resSst = user.pointSst;
                subSst.created_at = new Date();
                subSst.updated_at = new Date();
                await em.save(subSst);
            }
            await queryRunner.commitTransaction();
            return (0, class_transformer_1.plainToInstance)(vote_pick_for_sst_vote_response_dto_1.VotePickForSstVoteResponseDto, votePick);
        }
        catch (err) {
            await queryRunner.rollbackTransaction();
            throw err;
        }
        finally {
            await queryRunner.release();
        }
    }
    async voteUsingRight(userId, voteId, voteItemId, right, voteType) {
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();
        const em = queryRunner.manager;
        try {
            const user = await this.userRepository.findOne({
                where: { id: userId },
            });
            if (user === undefined) {
                throw new common_1.NotFoundException(`There is no user where id: ${userId}`);
            }
            user.pointRight -= right;
            await em.save(user);
            const votePick = vote_pick_entity_1.VotePick.rightVotePick(userId, voteId, voteItemId, right);
            await em.save(votePick);
            const pointRight = new point_right_entity_1.PointRight();
            pointRight.usersId = userId;
            pointRight.amount = right;
            pointRight.type = point_right_entity_1.PointRightType.VOTE;
            pointRight.votePickId = votePick.id;
            pointRight.created_at = new Date();
            pointRight.updated_at = new Date();
            await em.save(pointRight);
            const voteItem = await this.voteItemRepository.findOne({
                where: { id: voteItemId },
            });
            if (voteItem === undefined) {
                throw new common_1.NotFoundException(`There is no vote item where id: ${voteItemId}`);
            }
            voteItem.vote_total += right;
            await em.save(voteItem);
            if (user.grade !== enums_1.UserGrade.PLAY) {
                const subRight = new sub_right_entity_1.SubRight();
                subRight.usersId = userId;
                subRight.usersRole = user.grade;
                subRight.amount = right;
                subRight.type = voteType;
                subRight.voteId = voteId;
                subRight.resRight = user.pointRight;
                subRight.created_at = new Date();
                subRight.updated_at = new Date();
                await em.save(subRight);
            }
            await queryRunner.commitTransaction();
            return (0, class_transformer_1.plainToInstance)(vote_pick_for_right_vote_response_dto_1.VotePickForRightVoteResponseDto, votePick);
        }
        catch (err) {
            await queryRunner.rollbackTransaction();
            throw err;
        }
        finally {
            await queryRunner.release();
        }
    }
    async alreadyReportedVoteComment(userId, commentId) {
        var _a;
        const comment = await this.voteReplyRepository.findOne(commentId);
        if (comment === undefined) {
            throw new common_1.NotFoundException(`There is no comment where id: ${commentId}`);
        }
        return Boolean((_a = comment.reportUsers) === null || _a === void 0 ? void 0 : _a.includes(userId.toString()));
    }
    async reportVoteComment(userId, commentId) {
        var _a;
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();
        const em = queryRunner.manager;
        try {
            const comment = await em.findOne(vote_reply_entity_1.VoteReply, commentId);
            if (comment === undefined) {
                throw new common_1.NotFoundException(`There is no comment where id: ${commentId}`);
            }
            if (comment.reportUsers) {
                comment.reportUsers = (_a = comment.reportUsers) === null || _a === void 0 ? void 0 : _a.concat(userId.toString(), ';');
            }
            else {
                comment.reportUsers = `${userId.toString()};`;
            }
            comment.updated_at = new Date();
            await em.save(comment);
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
VoteService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(vote_entity_1.Vote)),
    __param(1, (0, typeorm_1.InjectRepository)(vote_item_entity_1.VoteItem)),
    __param(2, (0, typeorm_1.InjectRepository)(vote_reply_entity_1.VoteReply)),
    __param(3, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(4, (0, typeorm_1.InjectRepository)(vote_pick_entity_1.VotePick)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Connection])
], VoteService);
exports.VoteService = VoteService;
class VoteReplyCount {
}
//# sourceMappingURL=vote.service.js.map