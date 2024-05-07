import { IPaginationMeta } from 'nestjs-typeorm-paginate';
export declare class VoteDetailListDto {
    id: number;
    item_img: string;
    item_name: string;
    vote_total: number;
    eng_item_name: string;
    item_text: string;
    eng_item_text: string;
}
export declare class VoteDetailtDto {
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
    replycount: number;
}
export declare class VoteDetailListMainDto {
    items: VoteDetailListDto[];
    readonly meta: IPaginationMeta;
}
