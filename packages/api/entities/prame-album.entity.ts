import {Column, Entity, JoinColumn, JoinTable, ManyToMany, ManyToOne, OneToMany, OneToOne} from "typeorm";
import {BaseEntity} from "./base_entity";
import {PrameUserCommentReportEntity} from "./prame_user-comment-report.entity";
import {GalleryArticleImageEntity} from "./gallery_article_image.entity";
import {PrameUserEntity} from "./prame-user.entity";

@Entity("album")
export class PrameAlbumEntity extends BaseEntity {

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

    @OneToOne(() => PrameUserEntity, (user) => user.album)
    @JoinColumn({name: "user_id"})
    user: PrameUserEntity;
}

