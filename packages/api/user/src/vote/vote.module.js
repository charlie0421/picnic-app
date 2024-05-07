"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.VoteModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const vote_service_1 = require("./vote.service");
const vote_controller_1 = require("./vote.controller");
const vote_entity_1 = require("../../../libs/entities/src/entities/vote.entity");
const vote_item_entity_1 = require("../../../libs/entities/src/entities/vote-item.entity");
const vote_item_point_entity_1 = require("../../../libs/entities/src/entities/vote-item-point.entity");
const user_entity_1 = require("../../../libs/entities/src/entities/user.entity");
const vote_reply_entity_1 = require("../../../libs/entities/src/entities/vote-reply.entity");
const vote_pick_entity_1 = require("../../../libs/entities/src/entities/vote-pick.entity");
const point_sst_entity_1 = require("../../../libs/entities/src/entities/point-sst.entity");
const sub_sst_entity_1 = require("../../../libs/entities/src/entities/sub-sst.entity");
let VoteModule = class VoteModule {
};
VoteModule = __decorate([
    (0, common_1.Module)({
        imports: [typeorm_1.TypeOrmModule.forFeature([vote_entity_1.Vote, vote_item_entity_1.VoteItem, vote_item_point_entity_1.VoteItemPoint, vote_reply_entity_1.VoteReply, user_entity_1.User, vote_pick_entity_1.VotePick, point_sst_entity_1.PointSst, sub_sst_entity_1.SubSst])],
        exports: [typeorm_1.TypeOrmModule],
        controllers: [vote_controller_1.VoteController],
        providers: [vote_service_1.VoteService],
    })
], VoteModule);
exports.VoteModule = VoteModule;
//# sourceMappingURL=vote.module.js.map