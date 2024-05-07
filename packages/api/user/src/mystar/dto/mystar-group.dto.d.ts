import { IPaginationMeta } from 'nestjs-typeorm-paginate';
export declare class MystarGroupDto {
    id: number;
    groupName: string;
    engGroupName: string;
    groupImg: string;
}
export declare class MystarGroupMainDto {
    items: MystarGroupDto[];
    readonly meta: IPaginationMeta;
}
