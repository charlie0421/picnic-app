import { IPaginationMeta } from 'nestjs-typeorm-paginate';
export declare class VoteItemDto {
    id: number;
    item_img: string;
}
export declare class VoteDto {
    id: number;
    vote_title: string;
    eng_vote_title: string;
    vote_category: string;
    main_img: string;
    result_img: string;
    vote_content: string;
    eng_vote_content: string;
    vote_episode: string;
    eng_vote_episode: string;
    start_at: Date;
    stop_at: Date;
    visible_at: Date;
    replycount: number;
    items: VoteItemDto[];
}
export declare class VoteMainDto {
    items: VoteDto[];
    readonly meta: IPaginationMeta;
}
