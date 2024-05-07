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
exports.MystarPickListDto = void 0;
const class_transformer_1 = require("class-transformer");
const swagger_1 = require("@nestjs/swagger");
let MystarPickListDto = class MystarPickListDto {
};
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarPickListDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Transform)(({ obj }) => { var _a; return (_a = obj.member) === null || _a === void 0 ? void 0 : _a.id; }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarPickListDto.prototype, "memberId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Transform)(({ obj }) => { var _a; return (_a = obj.member) === null || _a === void 0 ? void 0 : _a.memberName; }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarPickListDto.prototype, "memberName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Transform)(({ obj }) => { var _a; return (_a = obj.member) === null || _a === void 0 ? void 0 : _a.memberImg; }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarPickListDto.prototype, "memberImg", void 0);
MystarPickListDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarPickListDto);
exports.MystarPickListDto = MystarPickListDto;
//# sourceMappingURL=mystar-pick-list.dto.js.map