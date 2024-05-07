import {Module} from '@nestjs/common';
import {TypeOrmModule} from '@nestjs/typeorm';
import {VoteService} from './vote.service';
import {VoteController} from './vote.controller';
import {VoteEntity} from "../../../entities/vote.entity";
import {VoteItemEntity} from "../../../entities/vote_item.entity";
import {VoteCommentEntity} from "../../../entities/vote_comment.entity";
import {VoteItemPickEntity} from "../../../entities/vote_item_pick.entity";
import {PrameUserEntity} from "../../../entities/prame-user.entity";

@Module({
    imports: [TypeOrmModule.forFeature([VoteEntity, VoteItemEntity, VoteCommentEntity, PrameUserEntity, VoteItemPickEntity,])],
    exports: [TypeOrmModule],
    controllers: [VoteController],
    providers: [VoteService],
})
export class VoteModule {
}
