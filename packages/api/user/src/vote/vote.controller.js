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
exports.VoteController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const constants_1 = require("../constants");
const create_vote_reply_dto_1 = require("./dto/create-vote-reply.dto");
const vote_service_1 = require("./vote.service");
const do_sst_vote_dto_1 = require("./dto/do-sst-vote.dto");
const vote_pick_for_sst_vote_response_dto_1 = require("./dto/vote-pick-for-sst-vote-response.dto");
const vote_reply_dto_1 = require("./dto/vote-reply.dto");
const vote_pick_for_right_vote_response_dto_1 = require("./dto/vote-pick-for-right-vote-response.dto");
const do_right_vote_dto_1 = require("./dto/do-right-vote.dto");
const sub_right_entity_1 = require("../../../libs/entities/src/entities/sub-right.entity");
const message_dto_1 = require("../auth/dto/message.dto");
let VoteController = class VoteController {
    constructor(voteService) {
        this.voteService = voteService;
    }
    async findAll(page = 1, limit = 5, category = 'starplay', active = true, artist = true, mainTop = true, sort = 'vote.start_at', order = 'DESC') {
        return this.voteService.findAll({ page, limit }, category, active, artist, mainTop, sort, order);
    }
    async getMainPageVotes() {
        return this.voteService.getMainPageVotes();
    }
    getVoteDetail(id) {
        return this.voteService.getVoteDetail(id);
    }
    getVoteDetailList(id, page = 1, limit = 100, sort = 'vote_total', order = 'DESC') {
        return this.voteService.getVoteDetailList(id, { page, limit }, sort, order);
    }
    getVoteReplyList(id, page = 1, limit = 15, sort = 'vote_reply.created_at', order = 'DESC') {
        return this.voteService.getVoteReplyList(id, { page, limit }, sort, order);
    }
    async postVoteReply(voteId, body, req) {
        const { reply_text } = body;
        const { id } = req.user;
        return this.voteService.postVoteReply(voteId, id, reply_text);
    }
    async voteUsingSst(voteId, { sst, voteItemId }, req) {
        const { id: userId } = req.user;
        if (await this.voteService.isVoteOver(voteId)) {
            throw new common_1.BadRequestException('The vote is over');
        }
        if (!(await this.voteService.isThereVote(voteId))) {
            throw new common_1.NotFoundException(`There is no vote where id: ${voteId}`);
        }
        if (!(await this.voteService.isThereVoteItem(voteId, voteItemId))) {
            throw new common_1.NotFoundException(`There is no vote item(${voteItemId}) in vote(${voteId})`);
        }
        if (await this.voteService.isUserSstLessThan(userId, Math.abs(sst))) {
            throw new common_1.BadRequestException(`User silver star token is less than ${sst}`);
        }
        return await this.voteService.voteUsingSst(userId, voteId, voteItemId, sst);
    }
    async voteUsingRight(voteId, { right, voteItemId, voteType }, req) {
        const { id: userId } = req.user;
        if (await this.voteService.isVoteOver(voteId)) {
            throw new common_1.BadRequestException('The vote is over');
        }
        if (!(await this.voteService.isThereVote(voteId))) {
            throw new common_1.NotFoundException(`There is no vote where id: ${voteId}`);
        }
        if (!(await this.voteService.isThereVoteItem(voteId, voteItemId))) {
            throw new common_1.NotFoundException(`There is no vote item(${voteItemId}) in vote(${voteId})`);
        }
        if (await this.voteService.isUserRightLessThan(userId, right)) {
            throw new common_1.BadRequestException(`User right is less than ${right}`);
        }
        if (voteType === sub_right_entity_1.SubRightType.ON_AIR && (await this.voteService.isTotalRightAmountOverTwo(voteId, userId))) {
            throw new common_1.BadRequestException('User can vote on air at most two times');
        }
        return await this.voteService.voteUsingRight(userId, voteId, voteItemId, right, voteType);
    }
    async reportVoteComment(commentId, req) {
        const { id: userId } = req.user;
        if (await this.voteService.alreadyReportedVoteComment(userId, commentId)) {
            throw new common_1.BadRequestException('Already reported this comment');
        }
        await this.voteService.reportVoteComment(userId, commentId);
        return new message_dto_1.MessageDto('Successfully reported comment');
    }
};
__decorate([
    (0, common_1.Get)(),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    (0, swagger_1.ApiOperation)({ summary: '투표 목록 API', description: '투표 리스트(pagination 가능)' }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: false, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, schema: { type: 'number', default: 5 } }),
    (0, swagger_1.ApiQuery)({ name: 'category', required: false, schema: { type: 'string', default: 'starplay' } }),
    (0, swagger_1.ApiQuery)({ name: 'active', required: false, schema: { type: 'boolean', default: true } }),
    (0, swagger_1.ApiQuery)({ name: 'artist', required: false, schema: { type: 'boolean', default: true } }),
    (0, swagger_1.ApiQuery)({ name: 'mainTop', required: false, schema: { type: 'boolean', default: true } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: false, schema: { type: 'string', default: 'vote.start_at' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: false, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.desc } }),
    __param(0, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(1, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(5), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('category', new common_1.DefaultValuePipe('starplay'))),
    __param(3, (0, common_1.Query)('active', new common_1.DefaultValuePipe(true), common_1.ParseBoolPipe)),
    __param(4, (0, common_1.Query)('artist', new common_1.DefaultValuePipe(true), common_1.ParseBoolPipe)),
    __param(5, (0, common_1.Query)('mainTop', new common_1.DefaultValuePipe(true), common_1.ParseBoolPipe)),
    __param(6, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('vote.start_at'))),
    __param(7, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.desc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Number, Object, Object, Object, Object, Object, String]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)('/main'),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    (0, swagger_1.ApiOperation)({ summary: '메인 페이지에 있는 투표 목록 API' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "getMainPageVotes", null);
__decorate([
    (0, common_1.Get)('/:id'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '투표 정보 API', description: '투표상세 정보를 얻는다.' }),
    (0, swagger_1.ApiParam)({ name: 'id', schema: { type: 'number' }, description: '투표 id' }),
    __param(0, (0, common_1.Param)('id', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", void 0)
], VoteController.prototype, "getVoteDetail", null);
__decorate([
    (0, common_1.Get)('/detail/list/:id'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '투표 현황 API', description: '투표상세 화면에서 투표 현황을 얻는다. (pagination 가능)' }),
    (0, swagger_1.ApiParam)({ name: 'id', schema: { type: 'number' }, description: '투표 id' }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: false, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, schema: { type: 'number', default: 100 } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: false, schema: { type: 'string', default: 'vote_total' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: false, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.desc } }),
    __param(0, (0, common_1.Param)('id', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(100), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('vote_total'))),
    __param(4, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.desc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Number, Number, Object, String]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "getVoteDetailList", null);
__decorate([
    (0, common_1.Get)('/reply/:id'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '투표 댓글 API', description: '투표 댓글 리스트를 얻는다. (pagination 가능)' }),
    (0, swagger_1.ApiParam)({ name: 'id', schema: { type: 'number' }, description: '투표 id' }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: false, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, schema: { type: 'number', default: 15 } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: false, schema: { type: 'string', default: 'vote_reply.created_at' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: false, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.desc } }),
    (0, swagger_1.ApiOkResponse)({ type: vote_reply_dto_1.VoteReplyMainDto }),
    __param(0, (0, common_1.Param)('id', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(15), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('vote_reply.created_at'))),
    __param(4, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.desc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Number, Number, Object, String]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "getVoteReplyList", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/:id/comment'),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiBody)({ type: create_vote_reply_dto_1.CreateVoteReplyDto }),
    (0, swagger_1.ApiOperation)({ summary: '투표 댓글 입력', description: '투표 댓글 입력' }),
    (0, swagger_1.ApiParam)({ name: 'id', schema: { type: 'number' }, description: '투표 id' }),
    __param(0, (0, common_1.Param)('id', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, create_vote_reply_dto_1.CreateVoteReplyDto, Object]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "postVoteReply", null);
__decorate([
    (0, swagger_1.ApiCreatedResponse)({ type: vote_pick_for_sst_vote_response_dto_1.VotePickForSstVoteResponseDto }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: 'SST으로 투표하기 API' }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/:voteId/by/sst'),
    __param(0, (0, common_1.Param)('voteId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, do_sst_vote_dto_1.DoSstVoteDto, Object]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "voteUsingSst", null);
__decorate([
    (0, swagger_1.ApiCreatedResponse)({ type: vote_pick_for_right_vote_response_dto_1.VotePickForRightVoteResponseDto }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '투표권으로 투표하기 API' }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/:voteId/by/right'),
    __param(0, (0, common_1.Param)('voteId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, do_right_vote_dto_1.DoRightVoteDto, Object]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "voteUsingRight", null);
__decorate([
    (0, swagger_1.ApiCreatedResponse)({ type: message_dto_1.MessageDto }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '투표 댓글 신고하기 API' }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/comments/:commentId/report'),
    __param(0, (0, common_1.Param)('commentId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object]),
    __metadata("design:returntype", Promise)
], VoteController.prototype, "reportVoteComment", null);
VoteController = __decorate([
    (0, common_1.Controller)('/vote'),
    (0, swagger_1.ApiTags)('Vote API'),
    __metadata("design:paramtypes", [vote_service_1.VoteService])
], VoteController);
exports.VoteController = VoteController;
//# sourceMappingURL=vote.controller.js.map