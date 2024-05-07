import {AfterLoad, Column, Entity, OneToMany} from "typeorm";
import {MystarMemberEntity} from "./mystar-member.entity";
import {BaseEntity} from "./base_entity";

@Entity("mystar_group")
export class MystarGroup extends BaseEntity {
    @Column({name: "name_ko"})
    nameKo: string;

    @Column({name: "name_en"})
    nameEn: string;

    @Column({name: "image"})
    image: string;

    @OneToMany(() => MystarMemberEntity, (members) => members.group)
    members!: MystarMemberEntity[];

    @AfterLoad()
    getFullImagePath() {
        if (this.image === null) {
            this.image = `${process.env.CDN_PATH_IMAGE}/profile_base2.png`;
            return;
        }

        this.image = `${process.env.CDN_PATH_MYSTAR_GROUP}/${this.id}/${this.image}`;
    }
}
