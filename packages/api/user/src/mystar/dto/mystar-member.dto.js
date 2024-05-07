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
exports.MystarMemberDto = void 0;
const class_transformer_1 = require("class-transformer");
const swagger_1 = require("@nestjs/swagger");
let MystarMemberDto = class MystarMemberDto {
};
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarMemberDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarMemberDto.prototype, "memberName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarMemberDto.prototype, "engMemberName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarMemberDto.prototype, "memberImg", void 0);
MystarMemberDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarMemberDto);
exports.MystarMemberDto = MystarMemberDto;
//# sourceMappingURL=mystar-member.dto.js.map