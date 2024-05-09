import {Module} from '@nestjs/common';
import {MystarService} from './mystar.service';
import {MystarController} from './mystar.controller';
import {TypeOrmModule} from '@nestjs/typeorm';
import {MystarGroupEntity} from "../../../entities/mystar-group.entity";
import {MystarMemberEntity} from "../../../entities/mystar-member.entity";
import {S3Service} from "../../../common/s3/s3.service";
import {UsersRepository} from "../users/users.repository";
import {VoteItemEntity} from "../../../entities/vote-item.entity";
import {VoteEntity} from "../../../entities/vote.entity";
import {VoteItemPickEntity} from "../../../entities/vote-item-pick.entity";
import {PointHistoryEntity} from "../../../entities/point_history.entity";
import {VoteCommentEntity} from "../../../entities/vote-comment.entity";

@Module({
    imports: [
        TypeOrmModule.forFeature([
            MystarGroupEntity,
            MystarMemberEntity,
            VoteEntity,
            VoteItemEntity,
            VoteItemPickEntity,
            PointHistoryEntity,
            VoteCommentEntity,

        ]),
    ],
    controllers: [MystarController],
    providers: [MystarService, UsersRepository, S3Service],
})
export class MyStarModule {
}
