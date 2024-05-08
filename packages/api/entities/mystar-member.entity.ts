import {AfterLoad, Column, Entity, JoinColumn, ManyToOne, OneToOne} from "typeorm";
import {MystarGroup} from "./mystar-group.entity";
import {VoteItemEntity} from "./vote_item.entity";
import {BaseEntity} from "./base_entity";

@Entity("mystar_member")
export class MystarMemberEntity extends BaseEntity {
    @Column({name: "name_ko"})
    nameKo: string;

    @Column({name: "name_en"})
    nameEn: string;

    @Column({name: "image"})
    image: string;

    @Column()
    gender: string;

    @ManyToOne(() => MystarGroup, (group) => group.members)
    @JoinColumn({name: "group_id"})
    group: MystarGroup;

    @OneToOne(() => VoteItemEntity, (voteItem) => voteItem.myStarMember)
    voteItem: VoteItemEntity;

    @AfterLoad()
    getFullImagePath() {
        if (this.image === null) {
            this.image = `${process.env.CDN_PATH_IMAGE}/profile_base2.png`;
            return;
        }

        this.image = `${process.env.CDN_URL}/mystar/member/${this.id}/${this.image}`;
    }
}
