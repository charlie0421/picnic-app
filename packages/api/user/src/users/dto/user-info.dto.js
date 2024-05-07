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
exports.UserInfoDto = void 0;
const class_transformer_1 = require("class-transformer");
const enums_1 = require("../enums");
const swagger_1 = require("@nestjs/swagger");
let UserInfoDto = class UserInfoDto {
    constructor(id, userImg, nickname, email, grade, pointGst, pointSst, pointRight) {
        this.id = id;
        this.userImg = userImg;
        this.nickname = nickname;
        this.email = email;
        this.grade = grade;
        this.pointGst = pointGst;
        this.pointSst = pointSst;
        this.pointRight = pointRight;
    }
};
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], UserInfoDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)({ name: 'imgPath' }),
    __metadata("design:type", String)
], UserInfoDto.prototype, "userImg", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], UserInfoDto.prototype, "nickname", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: String }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], UserInfoDto.prototype, "email", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ enum: enums_1.UserGrade }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], UserInfoDto.prototype, "grade", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], UserInfoDto.prototype, "pointGst", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], UserInfoDto.prototype, "pointSst", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: Number }),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], UserInfoDto.prototype, "pointRight", void 0);
UserInfoDto = __decorate([
    (0, class_transformer_1.Exclude)(),
    __metadata("design:paramtypes", [Number, String, String, String, String, Number, Number, Number])
], UserInfoDto);
exports.UserInfoDto = UserInfoDto;
//# sourceMappingURL=user-info.dto.js.map