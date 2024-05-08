import {Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany, OneToOne} from "typeorm";
import {BaseEntity} from "./base_entity";
import {UserCommentReportEntity} from "./user-comment-report.entity";
import {GalleryArticleImageEntity} from "./article_image.entity";
import {UserEntity} from "./user.entity";

@Entity("album")
export class AlbumEntity extends BaseEntity {

    @Column({name:'title'})
    title: string;

    @ManyToMany(() => GalleryArticleImageEntity, (image) => image.albums)
    @JoinTable({
        name: "album_image",
        joinColumn: {
            name: "album_id",
            referencedColumnName: "id",
        },
        inverseJoinColumn: {
            name: "image_id",
            referencedColumnName: "id",
        },
    })
    images: GalleryArticleImageEntity[];

    @OneToOne(() => UserEntity, (user) => user.album)
    @JoinColumn({name: "user_id"})
    user: UserEntity;
}

