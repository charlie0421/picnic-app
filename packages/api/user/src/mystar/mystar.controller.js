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
exports.MystarController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const constants_1 = require("../constants");
const mystar_follower_dto_1 = require("./dto/mystar-follower.dto");
const mystar_service_1 = require("./mystar.service");
const delete_mystar_pick_dto_1 = require("./dto/delete-mystar-pick.dto");
const create_mystar_dto_1 = require("./dto/create-mystar.dto");
const mystar_pick_dto_1 = require("./dto/mystar-pick.dto");
const mystar_pick_list_dto_1 = require("./dto/mystar-pick-list.dto");
const message_dto_1 = require("../auth/dto/message.dto");
const create_article_dto_1 = require("./dto/create-article.dto");
const update_article_dto_1 = require("./dto/update-article.dto");
const platform_express_1 = require("@nestjs/platform-express");
let MystarController = class MystarController {
    constructor(mystarService) {
        this.mystarService = mystarService;
    }
    findAll(name, page = 1, limit = 20, sort = 'Group.group_name', order = 'DESC') {
        if (name) {
            return this.mystarService.getGroupsByName({ page, limit }, name, sort, order);
        }
        return this.mystarService.findAll({ page, limit }, sort, order);
    }
    async getGroupsByName(name) {
        return this.mystarService.getGroupsByNameDeprecated(name);
    }
    getGroupMemberList(groupId) {
        return this.mystarService.getGroupMemberList(groupId);
    }
    getArtists(name, page = 1, limit = 20, gender = constants_1.GENDER.woman, sort = 'Member.memberName', order = 'DESC') {
        if (name) {
            return this.mystarService.getArtistsByName({ page, limit }, name, gender, sort, order);
        }
        return this.mystarService.getArtists({ page, limit }, gender, sort, order);
    }
    async getArtistsByName(gender = constants_1.GENDER.woman, name) {
        return this.mystarService.getArtistsByNameDeprecated(gender, name);
    }
    async getArtist(artistId) {
        return this.mystarService.getArtist(artistId);
    }
    getAllArticles(artistId, page = 1, limit = 10, sort = 'Follower.created_at', order = 'DESC') {
        return this.mystarService.getAllArticlesPagination(artistId, { page, limit }, sort, order);
    }
    getMyArticles(artistId, page = 1, limit = 10, sort = 'Follower.created_at', order = 'DESC', req) {
        const { id: userId } = req.user;
        return this.mystarService.getMyArticlesPagination(userId, artistId, { page, limit }, sort, order);
    }
    getFollowerDetail(articleId) {
        return this.mystarService.getFollowerDetail(articleId);
    }
    async getFollowerReplyList(articleId, page = 1, limit = 15, sort = 'Reply.created_at', order = 'DESC') {
        return this.mystarService.getFollowerReplyList(articleId, { page, limit }, sort, order);
    }
    async createArticleForArtist(artistId, image, createArticle, req) {
        const { id: userId } = req.user;
        const { title, contents, videoPath } = createArticle;
        let fileName;
        if (image) {
            fileName = await this.mystarService.uploadArticleImageByArtistId(image, artistId);
        }
        await this.mystarService.createArticle(userId, artistId, title, contents, fileName, videoPath);
        return new message_dto_1.MessageDto('successfully updated article');
    }
    async updateArticle(articleId, image, updateArticle, req) {
        const { id: userId } = req.user;
        if (!(await this.mystarService.isArticleMine(userId, articleId))) {
            throw new common_1.ForbiddenException('The article is not written by you');
        }
        const { title, contents, videoPath } = updateArticle;
        let fileName;
        if (image) {
            fileName = await this.mystarService.uploadArticleImageByArticleId(image, articleId);
        }
        await this.mystarService.updateArticle(articleId, title, contents, fileName, videoPath);
        return new message_dto_1.MessageDto('successfully updated article');
    }
    async deleteMyArticle(articleId, req) {
        const { id: userId } = req.user;
        if (!(await this.mystarService.isArticleMine(userId, articleId))) {
            throw new common_1.ForbiddenException('The article is not written by you');
        }
        await this.mystarService.deleteArticle(articleId);
        return new message_dto_1.MessageDto('successfully deleted');
    }
    async getFollowingArtists(req) {
        const { id: userId } = req.user;
        return this.mystarService.getMystarPickList(userId);
    }
    async followArtist(req, { artistId }) {
        const { id: userId } = req.user;
        if (await this.mystarService.isAlreadyPicked(userId, artistId)) {
            throw new common_1.BadRequestException('The artist already picked');
        }
        if (!(await this.mystarService.hasAvailableMystarSlot(userId))) {
            throw new common_1.BadRequestException('There is no available mystar slot');
        }
        return this.mystarService.followArtist(userId, artistId);
    }
    async unfollowArtists(req, { mystarPickIds }) {
        const { id: userId } = req.user;
        await this.mystarService.validateThereAreAllMystarPicks(mystarPickIds);
        await this.mystarService.validateUserOwnsMystarPicks(userId, mystarPickIds);
        await this.mystarService.unfollowArtists(mystarPickIds);
        return new message_dto_1.MessageDto('successfully deleted');
    }
};
__decorate([
    (0, common_1.Get)('/group'),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 그룹 목록 API', description: '마이스타 그룹 리스트(pagination 가능)' }),
    (0, swagger_1.ApiQuery)({ name: 'name', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: false, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, schema: { type: 'number', default: 20 } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: false, schema: { type: 'string', default: 'Group.group_name' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: false, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.asc } }),
    __param(0, (0, common_1.Query)('name')),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(20), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('Group.group_name'))),
    __param(4, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.asc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number, Number, Object, String]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "findAll", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '마이스타 그룹 검색 API', description: '%LIKE% 쿼리로 검색합니다' }),
    (0, swagger_1.ApiQuery)({ name: 'name', required: true, description: '그룹 이름' }),
    (0, common_1.Header)('Cache-Control', 'max-age=86400'),
    (0, common_1.Get)('/groups/byName'),
    __param(0, (0, common_1.Query)('name')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getGroupsByName", null);
__decorate([
    (0, common_1.Get)('/group/:groupId'),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 그룹 멤버 API', description: '마이스타 그룹 멤버 리스트' }),
    (0, swagger_1.ApiParam)({ name: 'groupId', schema: { type: 'number' }, description: '그룹 id' }),
    __param(0, (0, common_1.Param)('groupId', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", void 0)
], MystarController.prototype, "getGroupMemberList", null);
__decorate([
    (0, common_1.Get)('/artists'),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 가수 리스트 API', description: '마이스타 가수 리스트(pagination 가능)' }),
    (0, swagger_1.ApiQuery)({ name: 'name', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: false, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, schema: { type: 'number', default: 20 } }),
    (0, swagger_1.ApiQuery)({ name: 'gender', enum: constants_1.GENDER, required: false, schema: { type: 'string', default: constants_1.GENDER.woman } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: false, schema: { type: 'string', default: 'Member.memberName' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: false, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.asc } }),
    __param(0, (0, common_1.Query)('name')),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(20), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('gender', new common_1.DefaultValuePipe(constants_1.GENDER.woman))),
    __param(4, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('Member.memberName'))),
    __param(5, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.asc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Number, Number, Object, Object, String]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getArtists", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '아티스트 검색 API (그룹도 함께 검색합니다)', description: '%LIKE% 쿼리로 검색합니다' }),
    (0, swagger_1.ApiQuery)({ name: 'gender', enum: constants_1.GENDER, required: false, schema: { type: 'string', default: constants_1.GENDER.woman } }),
    (0, swagger_1.ApiQuery)({ name: 'name', required: true, description: '아티스트명 또는 그룹명' }),
    (0, common_1.Header)('Cache-Control', 'max-age=86400'),
    (0, common_1.Get)('/artists/byName'),
    __param(0, (0, common_1.Query)('gender', new common_1.DefaultValuePipe(constants_1.GENDER.woman))),
    __param(1, (0, common_1.Query)('name')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getArtistsByName", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '마이스타 가수 한 명 가져오는 API' }),
    (0, swagger_1.ApiParam)({ name: 'artistId' }),
    (0, common_1.Get)('/artists/:artistId'),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    __param(0, (0, common_1.Param)('artistId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getArtist", null);
__decorate([
    (0, common_1.Get)('/articles/artists/:artistId'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: '마이스타 공간 전체 글 목록 API',
        description: '마이스타 공간 전체 글 리스트 (pagination 가능)',
    }),
    (0, swagger_1.ApiOkResponse)({ type: mystar_follower_dto_1.MystarArticlesPaginationDto }),
    (0, swagger_1.ApiParam)({ name: 'artistId', schema: { type: 'number' }, description: '가수 id' }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: true, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: true, schema: { type: 'number', default: 10 } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: true, schema: { type: 'string', default: 'Follower.id' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: true, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.desc } }),
    __param(0, (0, common_1.Param)('artistId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(10), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('Follower.created_at'))),
    __param(4, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.desc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Number, Number, Object, String]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getAllArticles", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('/articles/artists/:artistId/writtenByMe'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: '마이스타 공간 내가 쓴 글 목록 API',
        description: '마이스타 공간 내가 쓴 글 목록 (pagination 가능)',
    }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOkResponse)({ type: mystar_follower_dto_1.MystarArticlesPaginationDto }),
    (0, swagger_1.ApiParam)({ name: 'artistId', schema: { type: 'number' }, description: '가수 id' }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: true, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: true, schema: { type: 'number', default: 10 } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: true, schema: { type: 'string', default: 'Follower.created_at' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: true, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.desc } }),
    __param(0, (0, common_1.Param)('artistId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(10), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('Follower.created_at'))),
    __param(4, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.desc))),
    __param(5, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Number, Number, Object, String, Object]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getMyArticles", null);
__decorate([
    (0, common_1.Get)('/articles/:articleId'),
    (0, common_1.Header)('Cache-Control', 'max-age=60'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 공간 글 상세 API', description: '마이스타 공간 글 상세 내용' }),
    (0, swagger_1.ApiParam)({ name: 'articleId', schema: { type: 'number' }, description: '작성 글 id' }),
    __param(0, (0, common_1.Param)('articleId', common_1.ParseIntPipe)),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number]),
    __metadata("design:returntype", void 0)
], MystarController.prototype, "getFollowerDetail", null);
__decorate([
    (0, common_1.Get)('/articles/:articleId/comments'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: '마이스타 공간 글의 댓글 목록 API',
        description: '마이스타 공간 글의 댓글 리스트 (pagination 가능)',
    }),
    (0, swagger_1.ApiParam)({ name: 'artistId', schema: { type: 'number' }, description: '가수 id' }),
    (0, swagger_1.ApiParam)({ name: 'followerId', schema: { type: 'number' }, description: '작성 글 id' }),
    (0, swagger_1.ApiQuery)({ name: 'page', required: false, schema: { type: 'number', default: 1 } }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, schema: { type: 'number', default: 15 } }),
    (0, swagger_1.ApiQuery)({ name: 'sort', required: false, schema: { type: 'string', default: 'Reply.created_at' } }),
    (0, swagger_1.ApiQuery)({ name: 'order', required: false, enum: constants_1.ORDER, schema: { type: 'string', default: constants_1.ORDER.desc } }),
    __param(0, (0, common_1.Param)('articleId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Query)('page', new common_1.DefaultValuePipe(1), common_1.ParseIntPipe)),
    __param(2, (0, common_1.Query)('limit', new common_1.DefaultValuePipe(15), common_1.ParseIntPipe)),
    __param(3, (0, common_1.Query)('sort', new common_1.DefaultValuePipe('Reply.created_at'))),
    __param(4, (0, common_1.Query)('order', new common_1.DefaultValuePipe(constants_1.ORDER.desc))),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Number, Number, Object, String]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getFollowerReplyList", null);
__decorate([
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 공간에 글쓰기 API' }),
    (0, swagger_1.ApiConsumes)('multipart/form-data'),
    (0, swagger_1.ApiCreatedResponse)({ type: message_dto_1.MessageDto }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/articles/artists/:artistId'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('image')),
    __param(0, (0, common_1.Param)('artistId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.UploadedFile)()),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, create_article_dto_1.CreateArticleDto, Object]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "createArticleForArtist", null);
__decorate([
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 공간에 글 수정하기 API', description: '수정할 필드만 넣어주세요' }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, swagger_1.ApiConsumes)('multipart/form-data'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.HttpCode)(200),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('image')),
    (0, common_1.Post)('/articles/:articleId'),
    __param(0, (0, common_1.Param)('articleId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.UploadedFile)()),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object, update_article_dto_1.UpdateArticleDto, Object]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "updateArticle", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 공간에 있는 나의 글 삭제하기 API' }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, common_1.Delete)('/articles/:articleId'),
    __param(0, (0, common_1.Param)('articleId', common_1.ParseIntPipe)),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Number, Object]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "deleteMyArticle", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '현재 마이스타 선택 정보 API', description: '사용자가 선택한 마이스타 목록을 가져옵니다' }),
    (0, swagger_1.ApiOkResponse)({ type: mystar_pick_list_dto_1.MystarPickListDto }),
    (0, common_1.Get)('/picks'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "getFollowingArtists", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 추가하기 API (아티스트 follow 하기)' }),
    (0, swagger_1.ApiCreatedResponse)({ type: mystar_pick_dto_1.MystarPickDto }),
    (0, swagger_1.ApiBody)({ type: create_mystar_dto_1.CreateMystarDto }),
    (0, common_1.Post)('/picks'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_mystar_dto_1.CreateMystarDto]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "followArtist", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '마이스타 여러명 삭제 API (아티스트 unfollow 하기)' }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, common_1.Delete)('/picks'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, delete_mystar_pick_dto_1.DeleteMystarPickDto]),
    __metadata("design:returntype", Promise)
], MystarController.prototype, "unfollowArtists", null);
MystarController = __decorate([
    (0, common_1.Controller)('/mystar'),
    (0, swagger_1.ApiTags)('Mystar API'),
    __metadata("design:paramtypes", [mystar_service_1.MystarService])
], MystarController);
exports.MystarController = MystarController;
//# sourceMappingURL=mystar.controller.js.map