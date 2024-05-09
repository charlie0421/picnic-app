import {Module} from '@nestjs/common';
import {TypeOrmModule} from '@nestjs/typeorm';
import {VoteService} from './vote.service';
import {VoteController} from './vote.controller';
import {VoteEntity} from "../../../entities/vote.entity";
import {VoteItemEntity} from "../../../entities/vote-item.entity";
import {VoteCommentEntity} from "../../../entities/vote-comment.entity";
import {VoteItemPickEntity} from "../../../entities/vote-item-pick.entity";
import {UserEntity} from "../../../entities/user.entity";

@Module({
    imports: [TypeOrmModule.forFeature([VoteEntity, VoteItemEntity, VoteCommentEntity, UserEntity, VoteItemPickEntity,])],
    exports: [TypeOrmModule],
    controllers: [VoteController],
    providers: [VoteService],
})
export class VoteModule {
}
