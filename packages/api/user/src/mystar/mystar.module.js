"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MystarModule = void 0;
const common_1 = require("@nestjs/common");
const mystar_service_1 = require("./mystar.service");
const mystar_controller_1 = require("./mystar.controller");
const typeorm_1 = require("@nestjs/typeorm");
const mystar_group_entity_1 = require("../../../libs/entities/src/entities/mystar-group.entity");
const mystar_member_entity_1 = require("../../../libs/entities/src/entities/mystar-member.entity");
const mystar_follower_entity_1 = require("../../../libs/entities/src/entities/mystar-follower.entity");
const mystar_reply_entity_1 = require("../../../libs/entities/src/entities/mystar-reply.entity");
const mystar_reply_report_user_entity_1 = require("../../../libs/entities/src/entities/mystar-reply-report-user.entity");
const mystar_pick_entity_1 = require("../../../libs/entities/src/entities/mystar-pick.entity");
const users_repository_1 = require("../users/users.repository");
const user_entity_1 = require("../../../libs/entities/src/entities/user.entity");
const s3_service_1 = require("../s3/s3.service");
let MystarModule = class MystarModule {
};
MystarModule = __decorate([
    (0, common_1.Module)({
        imports: [
            typeorm_1.TypeOrmModule.forFeature([
                mystar_group_entity_1.MystarGroup,
                mystar_member_entity_1.MystarMember,
                mystar_follower_entity_1.MystarFollower,
                mystar_reply_entity_1.MystarReply,
                mystar_reply_report_user_entity_1.MystarReplyReportUser,
                mystar_pick_entity_1.MystarPick,
                user_entity_1.User,
            ]),
        ],
        controllers: [mystar_controller_1.MystarController],
        providers: [mystar_service_1.MystarService, users_repository_1.UsersRepository, s3_service_1.S3Service],
    })
], MystarModule);
exports.MystarModule = MystarModule;
//# sourceMappingURL=mystar.module.js.map