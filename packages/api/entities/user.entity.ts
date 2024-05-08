import {AfterLoad, Column, Entity, JoinTable, ManyToMany, OneToMany, OneToOne, Unique} from "typeorm";
import {BaseEntity} from "./base_entity";
import {Celeb} from "./celeb.entity";
import {GalleryEntity} from "./gallery.entity";
import {ArticleCommentEntity} from "./article_comment.entity";
import {UserCommentReportEntity} from "./user-comment-report.entity";
import {GalleryArticleImageEntity} from "./article_image.entity";
import {AlbumEntity} from "./album.entity";

@Entity("prame-users")
@Unique(["id", "email"])
export class UserEntity extends BaseEntity {

    @Column()
    nickname: string;

    @Column()
    email: string;

    @Column({name: "email_verified_at", nullable: true})
    emailVerifiedAt: Date;

    @Column()
    password: string;

    @Column({name: "point", default: 0})
    point: number;

    @Column({name: "profile_image", nullable: true})
    profileImage: string;

    @Column({name: "logined_at", nullable: true})
    loginedAt: Date;
    @Column({name: "country_code", nullable: true})
    countryCode: string;
    @ManyToMany(() => Celeb, (celeb) => celeb.users)
    @JoinTable({name: "celeb_user", joinColumn: {name: "user_id"}, inverseJoinColumn: {name: "celeb_id"}})
    celebs: Celeb[];
    @ManyToMany(() => GalleryEntity, (gallery) => gallery.users)
    @JoinTable({name: "gallery_user", joinColumn: {name: "user_id"}, inverseJoinColumn: {name: "gallery_id"}})
    galleries: GalleryEntity[];
    @ManyToMany(() => ArticleCommentEntity, (comment) => comment.likedUsers)
    @JoinTable({name: "article_comment_like", joinColumn: {name: "user_id"}, inverseJoinColumn: {name: "comment_id"}})
    likedComments: ArticleCommentEntity[];
    @ManyToMany(() => ArticleCommentEntity, (comment) => comment.reportedUsers)
    @JoinTable({name: "article_comment_report", joinColumn: {name: "user_id"}, inverseJoinColumn: {name: "comment_id"}})
    reportedComments: ArticleCommentEntity[];
    @OneToMany(() => UserCommentReportEntity, (comment) => comment.user)
    userCommentReports: UserCommentReportEntity[]; // 댓글 신고 목록
    @ManyToMany(() => GalleryArticleImageEntity, (image) => image.bookmarkUsers)
    @JoinTable({
        name: "album_image_user",
        joinColumn: {
            name: "image_id",
        },
        inverseJoinColumn: {
            name: "user_id",
        },
    })
    bookmarks: GalleryArticleImageEntity[];
    @OneToOne(() => AlbumEntity, (library) => library.user)
    album: AlbumEntity;

    @AfterLoad()
    getFullImagePath() {
        if (this.profileImage === null || this.profileImage === '') {
            this.profileImage = '';
            return;
        }

        this.profileImage = `${process.env.CDN_URL}/user/${this.id}/${this.profileImage}`;
    }


}

