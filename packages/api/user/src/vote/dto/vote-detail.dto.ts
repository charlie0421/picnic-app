import {Exclude, Expose, Type} from "class-transformer";
import {IPaginationMeta} from "nestjs-typeorm-paginate";
import {MystarMemberEntity} from "../../../../entities/mystar-member.entity";

@Exclude()
export class VoteDetailListDto {
    @Expose()
    id: number;

    @Expose()
    vote_id: number;

    @Expose()
    item_img: string;

    @Expose()
    item_name: string;

    @Expose()
    vote_total: number;

    @Expose()
    eng_item_name: string;

    @Expose()
    item_text: string;

    @Expose()
    eng_item_text: string;

    @Expose()
    week_of_week: number;

    @Expose()
    mystarMember: MystarMemberEntity;
}

@Exclude()
export class VoteDetailtDto {
    @Expose()
    id: number;

    @Expose()
    vote_title: string;

    @Expose()
    eng_vote_title: string;

    @Expose()
    vote_category: string;

    @Expose()
    main_img: string;

    @Expose()
    result_img: string;

    @Expose()
    vote_content: string;

    @Expose()
    eng_vote_content: string;

    @Expose()
    vote_episode: string;

    @Expose()
    eng_vote_episode: string;

    @Expose()
    start_at: Date;

    @Expose()
    stop_at: Date;

    @Expose()
    replycount: number;

}

@Exclude()
export class VoteDetailListMainDto {
    @Expose()
    @Type(() => VoteDetailListDto)
    items: VoteDetailListDto[];

    @Expose()
    readonly meta: IPaginationMeta;

    @Expose()
    total_vote: number;
}
