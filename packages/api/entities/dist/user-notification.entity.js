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
exports.PaginatedUserNotification = exports.UserNotification = void 0;
const graphql_1 = require("@nestjs/graphql");
const typeorm_1 = require("typeorm");
const base_entitiy_1 = require("./base.entitiy");
const pagination_info_1 = require("./pagination-info");
let UserNotification = class UserNotification extends base_entitiy_1.BaseEntitiy {
};
exports.UserNotification = UserNotification;
__decorate([
    (0, typeorm_1.Column)({ name: 'uid' }),
    __metadata("design:type", Number)
], UserNotification.prototype, "uid", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'type' }),
    __metadata("design:type", String)
], UserNotification.prototype, "type", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'message' }),
    __metadata("design:type", String)
], UserNotification.prototype, "message", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'reference_id' }),
    __metadata("design:type", Number)
], UserNotification.prototype, "referenceId", void 0);
__decorate([
    (0, typeorm_1.Column)({ name: 'is_read' }),
    __metadata("design:type", Boolean)
], UserNotification.prototype, "isRead", void 0);
exports.UserNotification = UserNotification = __decorate([
    (0, typeorm_1.Entity)('user_notification'),
    (0, graphql_1.ObjectType)()
], UserNotification);
let PaginatedUserNotification = class PaginatedUserNotification {
};
exports.PaginatedUserNotification = PaginatedUserNotification;
__decorate([
    (0, graphql_1.Field)((type) => [UserNotification]),
    __metadata("design:type", Array)
], PaginatedUserNotification.prototype, "items", void 0);
__decorate([
    (0, graphql_1.Field)((type) => pagination_info_1.PaginationInfo),
    __metadata("design:type", pagination_info_1.PaginationInfo)
], PaginatedUserNotification.prototype, "meta", void 0);
exports.PaginatedUserNotification = PaginatedUserNotification = __decorate([
    (0, graphql_1.ObjectType)()
], PaginatedUserNotification);
//# sourceMappingURL=user-notification.entity.js.map