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
exports.MystarArtistMainDto = exports.MystarArtistDto = void 0;
const class_transformer_1 = require("class-transformer");
let MystarArtistDto = class MystarArtistDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Number)
], MystarArtistDto.prototype, "id", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArtistDto.prototype, "memberName", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArtistDto.prototype, "engMemberName", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArtistDto.prototype, "memberImg", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.group.groupName),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArtistDto.prototype, "groupName", void 0);
__decorate([
    (0, class_transformer_1.Transform)(({ obj }) => obj.group.engGroupName),
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", String)
], MystarArtistDto.prototype, "engGroupName", void 0);
MystarArtistDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarArtistDto);
exports.MystarArtistDto = MystarArtistDto;
let MystarArtistMainDto = class MystarArtistMainDto {
};
__decorate([
    (0, class_transformer_1.Expose)(),
    (0, class_transformer_1.Type)(() => MystarArtistDto),
    __metadata("design:type", Array)
], MystarArtistMainDto.prototype, "items", void 0);
__decorate([
    (0, class_transformer_1.Expose)(),
    __metadata("design:type", Object)
], MystarArtistMainDto.prototype, "meta", void 0);
MystarArtistMainDto = __decorate([
    (0, class_transformer_1.Exclude)()
], MystarArtistMainDto);
exports.MystarArtistMainDto = MystarArtistMainDto;
//# sourceMappingURL=mystar-artist.dto.js.map