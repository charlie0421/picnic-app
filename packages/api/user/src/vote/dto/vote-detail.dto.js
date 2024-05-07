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
exports.VoteDetailListMainDto = exports.VoteDetailtDto = exports.VoteDetailListDto = void 0;
const class_transformer_1 = require("class-transformer");
let VoteDetailListDto = class VoteDetailListDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteDetailListDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailListDto.prototype, "item_img", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailListDto.prototype, "item_name", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteDetailListDto.prototype, "vote_total", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailListDto.prototype, "eng_item_name", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailListDto.prototype, "item_text", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailListDto.prototype, "eng_item_text", void 0);
VoteDetailListDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VoteDetailListDto);
exports.VoteDetailListDto = VoteDetailListDto;
let VoteDetailtDto = class VoteDetailtDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteDetailtDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "vote_title", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "eng_vote_title", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "vote_category", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "main_img", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "result_img", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "vote_content", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "eng_vote_content", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "vote_episode", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], VoteDetailtDto.prototype, "eng_vote_episode", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Date)
], VoteDetailtDto.prototype, "start_at", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Date)
], VoteDetailtDto.prototype, "stop_at", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VoteDetailtDto.prototype, "replycount", void 0);
VoteDetailtDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VoteDetailtDto);
exports.VoteDetailtDto = VoteDetailtDto;
let VoteDetailListMainDto = class VoteDetailListMainDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => VoteDetailListDto),
    __metadata("design:type", Array)
], VoteDetailListMainDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Object)
], VoteDetailListMainDto.prototype, "meta", void 0);
VoteDetailListMainDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VoteDetailListMainDto);
exports.VoteDetailListMainDto = VoteDetailListMainDto;
//# sourceMappingURL=vote-detail.dto.js.map