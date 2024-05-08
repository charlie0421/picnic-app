import {AfterLoad, Column, Entity, OneToMany} from "typeorm";
import {BaseEntity} from "./base_entity";
import {VoteItemEntity} from "./vote_item.entity";
import {VoteItemPickEntity} from "./vote_item_pick.entity";
import {VoteCommentEntity} from "./vote_comment.entity";

@Entity("vote")
export class VoteEntity extends BaseEntity {
    @Column({name: 'vote_title'})
    voteTitle: string;

    @Column({name: 'vote_category'})
    voteCategory: string;

    @Column({name: 'main_image'})
    mainImage: string;
    @Column({name: 'wait_image'})
    waitImage: string;
    @Column({name: 'result_image'})
    resultImage: string;
    @Column({name: 'vote_content'})
    voteContent: string;
    @Column({name: 'start_at', type: "datetime"})
    startAt: Date;
    @Column({name: 'stop_at', type: "datetime"})
    stopAt: Date;
    @Column({name: 'visible_at', type: "datetime"})
    visibleAt: Date;
    @OneToMany(() => VoteItemPickEntity, (votePick) => votePick.vote)
    votePicks!: VoteItemPickEntity[];
    @OneToMany(() => VoteCommentEntity, (comment) => comment.vote)
    comments!: VoteCommentEntity[];
    @OneToMany(() => VoteItemEntity, (item) => item.vote)
    voteItems!: VoteItemEntity[];

    @AfterLoad()
    getMainImagePath() {
        this.mainImage = `${process.env.CDN_URL}/vote/${this.id}/${this.mainImage}`;
    }

    @AfterLoad()
    getWaitImagePath() {
        this.waitImage = `${process.env.CDN_URL}/vote/${this.id}/${this.waitImage}`;
    }

    @AfterLoad()
    getResultImagePath() {
        this.resultImage = `${process.env.CDN_URL}/vote/${this.id}/${this.resultImage}`;
    }
}
