import { BaseEntitiy } from "./base.entitiy";
import { PaginationInfo } from "./pagination-info";
import { Episode } from "./episode.entity";
export declare class User extends BaseEntitiy {
    userId: string;
    nickname: string;
    email: string;
    emailVerifiedAt: Date;
    password: string;
    imgPath: string;
    loginedAt: Date;
    agreedAt: Date;
    getFullImagePath(): void;
    episodes: Episode[];
}
export declare class PaginatedUser {
    items: User[];
    meta: PaginationInfo;
}
