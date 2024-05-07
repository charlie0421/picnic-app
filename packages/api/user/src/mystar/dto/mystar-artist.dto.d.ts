import { IPaginationMeta } from 'nestjs-typeorm-paginate';
export declare class MystarArtistDto {
    id: number;
    memberName: string;
    engMemberName: string;
    memberImg: string;
    groupName: string;
    engGroupName: string;
}
export declare class MystarArtistMainDto {
    items: MystarArtistDto[];
    readonly meta: IPaginationMeta;
}
