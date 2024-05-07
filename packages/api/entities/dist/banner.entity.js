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
exports.PaginatedEventBanner = exports.EventBanner = void 0;
const typeorm_1 = require("typeorm");
const base_entitiy_1 = require("./base.entitiy");
let EventBanner = class EventBanner extends base_entitiy_1.BaseEntitiy {
    getImageKo() {
        this.event_img_ko = `${process.env.CDN_URL}/banner/${this.id}/${this.event_img_ko}`;
    }
    getImageEn() {
        this.event_img_en = `${process.env.CDN_URL}/banner/${this.id}/${this.event_img_en}`;
    }
};
exports.EventBanner = EventBanner;
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "tag_ko", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "tag_en", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "title_ko", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "title_en", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "subtitle_ko", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "subtitle_en", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "event_img_ko", void 0);
__decorate([
    (0, typeorm_1.AfterLoad)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], EventBanner.prototype, "getImageKo", null);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], EventBanner.prototype, "event_img_en", void 0);
__decorate([
    (0, typeorm_1.AfterLoad)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], EventBanner.prototype, "getImageEn", null);
__decorate([
    (0, typeorm_1.Column)({ nullable: true }),
    __metadata("design:type", String)
], EventBanner.prototype, "url", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'datetime' }),
    __metadata("design:type", Date)
], EventBanner.prototype, "start_at", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'datetime' }),
    __metadata("design:type", Date)
], EventBanner.prototype, "end_at", void 0);
exports.EventBanner = EventBanner = __decorate([
    (0, typeorm_1.Entity)('event_banner')
], EventBanner);
class PaginatedEventBanner {
}
exports.PaginatedEventBanner = PaginatedEventBanner;
//# sourceMappingURL=banner.entity.js.map