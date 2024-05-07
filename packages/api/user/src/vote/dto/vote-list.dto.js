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
exports.VoteMainDto = exports.VoteDto = exports.VoteItemDto = void 0;
const class_transformer_1 = require("class-transformer");
const class_validator_1 = require("class-validator");
let VoteItemDto = class VoteItemDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteItemDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteItemDto.prototype, "item_img", void 0);
VoteItemDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VoteItemDto);
exports.VoteItemDto = VoteItemDto;
let VoteDto = class VoteDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "vote_title", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "eng_vote_title", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "vote_category", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "main_img", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "result_img", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "vote_content", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "eng_vote_content", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "vote_episode", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDto.prototype, "eng_vote_episode", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Date)
], VoteDto.prototype, "start_at", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Date)
], VoteDto.prototype, "stop_at", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Date)
], VoteDto.prototype, "visible_at", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteDto.prototype, "replycount", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_validator_1.ValidateNested)({ each: true }),
    (0, class_transformer_1.Type)(() => VoteItemDto),
    __metadata("design:type", Array)
], VoteDto.prototype, "items", void 0);
VoteDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VoteDto);
exports.VoteDto = VoteDto;
let VoteMainDto = class VoteMainDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => VoteDto),
    __metadata("design:type", Array)
], VoteMainDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Object)
], VoteMainDto.prototype, "meta", void 0);
VoteMainDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VoteMainDto);
exports.VoteMainDto = VoteMainDto;
//# sourceMappingURL=vote-list.dto.js.map