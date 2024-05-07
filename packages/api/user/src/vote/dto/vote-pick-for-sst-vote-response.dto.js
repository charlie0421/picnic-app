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
exports.VotePickForSstVoteResponseDto = void 0;
const class_transformer_1 = require("class-transformer");
const swagger_1 = require("@nestjs/swagger");
let VotePickForSstVoteResponseDto = class VotePickForSstVoteResponseDto {
};
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VotePickForSstVoteResponseDto.prototype, "voteId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], VotePickForSstVoteResponseDto.prototype, "voteItemId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)({ name: 'pointAmount' }),
    __metadata("design:type", Number)
], VotePickForSstVoteResponseDto.prototype, "sstAmount", void 0);
VotePickForSstVoteResponseDto = __decorate([
    (0, class_transformer_1.Exclude)()
], VotePickForSstVoteResponseDto);
exports.VotePickForSstVoteResponseDto = VotePickForSstVoteResponseDto;
//# sourceMappingURL=vote-pick-for-sst-vote-response.dto.js.map