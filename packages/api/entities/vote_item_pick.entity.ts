import {Column, Entity, JoinColumn, ManyToOne, OneToMany} from 'typeorm';
import {VoteItemEntity} from './vote_item.entity';
import {VoteEntity} from './vote.entity';
import {BaseEntity} from "./base_entity";
import {PointHistoryEntity} from "./point_history.entity";

@Entity('vote_pick')
export class VoteItemPickEntity extends BaseEntity {
    @Column({name: 'vote_id'})
    voteId: number;

    @Column({name: 'vote_item_id'})
    voteItemId: number;

    @Column({name: 'users_id'})
    usersId: number;

    @Column({name: 'point_amount'})
    pointAmount: number;

    @ManyToOne((type) => VoteEntity, (vote) => vote.votePicks)
    @JoinColumn({name: 'vote_id'})
    vote!: VoteEntity;

    @ManyToOne((type) => VoteItemEntity, (voteItem) => voteItem.picks)
    @JoinColumn({name: 'vote_item_id'})
    voteItem!: VoteItemEntity;

    @OneToMany((type) => PointHistoryEntity, (pointHostory) => pointHostory.votePick)
    pointHistory!: PointHistoryEntity[];

    static pointVotePick(usersId: number, voteId: number, voteItemId: number, pointAmount: number) {
        const votePick = new VoteItemPickEntity();
        votePick.usersId = usersId;
        votePick.voteId = voteId;
        votePick.voteItemId = voteItemId;
        votePick.pointAmount = pointAmount;
        votePick.createdAt = new Date();
        votePick.updatedAt = new Date();

        return votePick;
    }
}
