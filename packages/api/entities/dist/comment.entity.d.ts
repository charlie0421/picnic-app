import { BaseEntitiy } from "./base.entitiy";
export declare class Comment extends BaseEntitiy {
    episodeId: number;
    userId: number;
    userNickname: string;
    userImgPath: string;
    parentId: number | null;
    parent: Comment;
    children: Comment[];
    likes: number;
    dislikes: number;
    content: string;
}
