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
exports.PaginatedUser = exports.User = void 0;
const typeorm_1 = require("typeorm");
const base_entitiy_1 = require("./base.entitiy");
const episode_entity_1 = require("./episode.entity");
let User = class User extends base_entitiy_1.BaseEntitiy {
    getFullImagePath() {
        if (this.imgPath === null || this.imgPath.length === 0) {
            this.imgPath = '';
            return;
        }
        this.imgPath = `${process.env.CDN_PATH_PROFILE}/${this.id}/${this.imgPath}`;
    }
};
exports.User = User;
__decorate([
    (0, typeorm_1.Column)({ name: "user_id" }),
    __metadata("design:type", String)
], User.prototype, "userId", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], User.prototype, "nickname", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], User.prototype, "email", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "email_verified_at" }),
    __metadata("design:type", Date)
], User.prototype, "emailVerifiedAt", void 0);
__decorate([
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], User.prototype, "password", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "img_path" }),
    __metadata("design:type", String)
], User.prototype, "imgPath", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "logined_at" }),
    __metadata("design:type", Date)
], User.prototype, "loginedAt", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: "agreed_at" }),
    __metadata("design:type", Date)
], User.prototype, "agreedAt", void 0);
__decorate([
    (0, typeorm_1.AfterLoad)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], User.prototype, "getFullImagePath", null);
__decorate([
    (0, typeorm_1.ManyToMany)(() => episode_entity_1.Episode, (episode) => episode.user),
    __metadata("design:type", Array)
], User.prototype, "episodes", void 0);
exports.User = User = __decorate([
    (0, typeorm_1.Entity)("users")
], User);
class PaginatedUser {
}
exports.PaginatedUser = PaginatedUser;
//# sourceMappingURL=user.entity.js.map