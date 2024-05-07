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
exports.MystarGroupMainDto = exports.MystarGroupDto = void 0;
const class_transformer_1 = require("class-transformer");
let MystarGroupDto = class MystarGroupDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarGroupDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarGroupDto.prototype, "groupName", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarGroupDto.prototype, "engGroupName", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarGroupDto.prototype, "groupImg", void 0);
MystarGroupDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarGroupDto);
exports.MystarGroupDto = MystarGroupDto;
let MystarGroupMainDto = class MystarGroupMainDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => MystarGroupDto),
    __metadata("design:type", Array)
], MystarGroupMainDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Object)
], MystarGroupMainDto.prototype, "meta", void 0);
MystarGroupMainDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarGroupMainDto);
exports.MystarGroupMainDto = MystarGroupMainDto;
//# sourceMappingURL=mystar-group.dto.js.map