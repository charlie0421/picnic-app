import {Column, Entity, JoinColumn, ManyToOne} from 'typeorm';
import {VoteItemPickEntity} from "./vote_item_pick.entity";
import {BaseEntity} from "./base_entity";

export enum PointHistoryType {
    BUY = 'buy',
    BUY_RIGHT = 'buy_right',
    VOTE = 'vote',
    MISSION = 'mission',
    ADVERTISE = 'advertise',
    SLOT = 'slot',
    BONUS = 'bonus',
    SEND = 'send',
    IN_APP_SUB = 'inappSub',
    IN_APP_SUB_BONUS = 'inappSubBonus',
    REFUND = 'refund',
    REWARD = 'reward',
}

@Entity('point_history')
export class PointHistoryEntity extends BaseEntity {
    @Column({name: 'users_id'})
    usersId: number;

    @Column()
    amount: number;

    @Column({type: 'enum', enum: PointHistoryType})
    type: PointHistoryType;

    @Column({name: 'buy_info'})
    buyInfo?: string;

    @Column({name: 'point_sst_item_id'})
    pointSstItemId?: number;

    @Column({name: 'point_right_id'})
    pointRightId?: number;

    @Column({name: 'vote_pick_id'})
    votePickId?: number;

    @ManyToOne((type) => VoteItemPickEntity, (voteItemPick) => voteItemPick.pointHistory)
    @JoinColumn({name: 'vote_pick_id'})
    votePick?: VoteItemPickEntity;


}
