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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MystarFollowerReplyMainDto = exports.MystarArticlesPaginationDto = exports.MystarArticlesPaginationForRawQueryDto = exports.MystarFollowerDetailDto = exports.MystarFollowerReplyDto = exports.MystarArticleDto = exports.MystarArticleForRawQueryDto = void 0;
const class_transformer_1 = require("class-transformer");
const swagger_1 = require("@nestjs/swagger");
const pagination_meta_dto_1 = require("./pagination-meta.dto");
let MystarArticleForRawQueryDto = class MystarArticleForRawQueryDto {
};
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarArticleForRawQueryDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)({ name: 'user_id' }),
    __metadata("design:type", Number)
], MystarArticleForRawQueryDto.prototype, "usersId", void 0);
__decorate([
    (0, class_transformer_1.Exclude)(),
    __metadata("design:type", Number)
], MystarArticleForRawQueryDto.prototype, "mystarMemberId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArticleForRawQueryDto.prototype, "title", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArticleForRawQueryDto.prototype, "contents", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)({ name: 'img_path' }),
    (0, class_transformer_1.Transform)(({ obj }) => {
        if (obj.video_path) {
            const path = obj.video_path.replace('https://youtu.be/', '');
            return `http://img.youtube.com/vi/${path}/1.jpg`;
        }
        if (obj.img_path) {
            return `${process.env.CDN_PATH_FOLLOWER}/${obj.member_id}/${obj.img_path}`;
        }
        return null;
    }),
    __metadata("design:type", String)
], MystarArticleForRawQueryDto.prototype, "imgPath", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Date }),
    (0, class_transformer_1.Expose)({ name: 'created_at' }),
    __metadata("design:type", Date)
], MystarArticleForRawQueryDto.prototype, "createdAt", void 0);
MystarArticleForRawQueryDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarArticleForRawQueryDto);
exports.MystarArticleForRawQueryDto = MystarArticleForRawQueryDto;
let MystarArticleDto = class MystarArticleDto {
};
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarArticleDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarArticleDto.prototype, "usersId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArticleDto.prototype, "title", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArticleDto.prototype, "contents", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Transform)(({ obj }) => (obj.videoPath ? obj.videoImgPath : obj.imgPath)),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArticleDto.prototype, "imgPath", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Date }),
    (0, class_transformer_1.Expose)({ name: 'created_at' }),
    __metadata("design:type", Date)
], MystarArticleDto.prototype, "createdAt", void 0);
MystarArticleDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarArticleDto);
exports.MystarArticleDto = MystarArticleDto;
let MystarFollowerReplyDto = class MystarFollowerReplyDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarFollowerReplyDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.user.imgPath),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerReplyDto.prototype, "userProfileImgPath", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.user.nickname),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerReplyDto.prototype, "userNickname", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerReplyDto.prototype, "replyText", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Date)
], MystarFollowerReplyDto.prototype, "createdAt", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Boolean)
], MystarFollowerReplyDto.prototype, "isReported", void 0);
MystarFollowerReplyDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarFollowerReplyDto);
exports.MystarFollowerReplyDto = MystarFollowerReplyDto;
let MystarFollowerDetailDto = class MystarFollowerDetailDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarFollowerDetailDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.member.memberImg),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "memberProfileImgPath", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "title", void 0);
__decorate([
    (0, class_transformer_1.Expose)({ name: 'created_at' }),
    __metadata("design:type", Date)
], MystarFollowerDetailDto.prototype, "createdAt", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.user.nickname),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "userNickname", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.user.imgPath),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "userProfileImgPath", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "videoPath", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "imgPath", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarFollowerDetailDto.prototype, "contents", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarFollowerDetailDto.prototype, "replyCount", void 0);
MystarFollowerDetailDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarFollowerDetailDto);
exports.MystarFollowerDetailDto = MystarFollowerDetailDto;
let MystarArticlesPaginationForRawQueryDto = class MystarArticlesPaginationForRawQueryDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => MystarArticleForRawQueryDto),
    (0, swagger_1.ApiProperty)({ type: [MystarArticleForRawQueryDto] }),
    __metadata("design:type", Array)
], MystarArticlesPaginationForRawQueryDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, swagger_1.ApiProperty)({ type: pagination_meta_dto_1.PaginationMetaDto }),
    __metadata("design:type", Object)
], MystarArticlesPaginationForRawQueryDto.prototype, "meta", void 0);
MystarArticlesPaginationForRawQueryDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarArticlesPaginationForRawQueryDto);
exports.MystarArticlesPaginationForRawQueryDto = MystarArticlesPaginationForRawQueryDto;
let MystarArticlesPaginationDto = class MystarArticlesPaginationDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => MystarArticleDto),
    (0, swagger_1.ApiProperty)({ type: [MystarArticleDto] }),
    __metadata("design:type", Array)
], MystarArticlesPaginationDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, swagger_1.ApiProperty)({ type: pagination_meta_dto_1.PaginationMetaDto }),
    __metadata("design:type", Object)
], MystarArticlesPaginationDto.prototype, "meta", void 0);
MystarArticlesPaginationDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarArticlesPaginationDto);
exports.MystarArticlesPaginationDto = MystarArticlesPaginationDto;
let MystarFollowerReplyMainDto = class MystarFollowerReplyMainDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => MystarFollowerReplyDto),
    __metadata("design:type", Array)
], MystarFollowerReplyMainDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Object)
], MystarFollowerReplyMainDto.prototype, "meta", void 0);
MystarFollowerReplyMainDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarFollowerReplyMainDto);
exports.MystarFollowerReplyMainDto = MystarFollowerReplyMainDto;
//# sourceMappingURL=mystar-follower.dto.js.map