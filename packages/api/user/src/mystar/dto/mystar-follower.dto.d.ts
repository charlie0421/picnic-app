import { IPaginationMeta } from 'nestjs-typeorm-paginate';
export declare class MystarArticleForRawQueryDto {
    id: number;
    usersId: number;
    mystarMemberId: number;
    title: string;
    contents: string;
    imgPath: string;
    createdAt: Date;
}
export declare class MystarArticleDto {
    id: number;
    usersId: number;
    title: string;
    contents: string;
    imgPath: string;
    createdAt: Date;
}
export declare class MystarFollowerReplyDto {
    readonly id: number;
    readonly userProfileImgPath: string;
    readonly userNickname: string;
    readonly replyText: string;
    readonly createdAt: Date;
    readonly isReported: boolean;
}
export declare class MystarFollowerDetailDto {
    readonly id: number;
    readonly memberProfileImgPath: string;
    readonly title: string;
    readonly createdAt: Date;
    readonly userNickname: string;
    readonly userProfileImgPath: string;
    readonly videoPath: string;
    readonly imgPath: string;
    readonly contents: string;
    readonly replyCount: number;
}
export declare class MystarArticlesPaginationForRawQueryDto {
    items: MystarArticleForRawQueryDto[];
    readonly meta: IPaginationMeta;
}
export declare class MystarArticlesPaginationDto {
    items: MystarArticleDto[];
    readonly meta: IPaginationMeta;
}
export declare class MystarFollowerReplyMainDto {
    items: MystarFollowerReplyDto[];
    readonly meta: IPaginationMeta;
}
