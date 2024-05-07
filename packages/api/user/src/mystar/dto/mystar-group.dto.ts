import { Exclude, Expose, Type } from 'class-transformer';
import { IPaginationMeta } from 'nestjs-typeorm-paginate';

@Exclude()
export class MystarGroupDto {
  @Expose()
  id: number;

  @Expose()
  groupName: string;

  @Expose()
  engGroupName: string;

  @Expose()
  groupImg: string;
}

@Exclude()
export class MystarGroupMainDto {
  @Expose()
  @Type(() => MystarGroupDto)
  items: MystarGroupDto[];

  @Expose()
  readonly meta: IPaginationMeta;
}
