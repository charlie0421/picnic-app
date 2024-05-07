import {Column, Entity, JoinColumn, ManyToOne, OneToMany, OneToOne} from "typeorm";
import {VoteEntity} from "./vote.entity";
import {VoteItemPickEntity} from "./vote_item_pick.entity";
import {MystarMemberEntity} from "./mystar-member.entity";
import {BaseEntity} from "./base_entity";

@Entity("vote_item")
export class VoteItemEntity extends BaseEntity {

    @Column({name: "vote_total"})
    voteTotal: number;

    @ManyToOne(() => VoteEntity, (vote) => vote.id)
    @JoinColumn({name: "vote_id"})
    vote: VoteEntity;
    @Column()
    voteId: number;

    @OneToMany(() => VoteItemPickEntity, (pick) => pick.voteItem)
    picks!: VoteItemPickEntity[];

    @OneToOne(() => MystarMemberEntity, (mystar_member) => mystar_member.voteItem,
    )
    @JoinColumn({name: "member_id"})
    myStarMember: MystarMemberEntity;

    @Column()
    memberId: number;

}
