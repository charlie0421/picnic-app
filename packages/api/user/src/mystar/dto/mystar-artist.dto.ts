import { Exclude, Expose, Transform, Type } from 'class-transformer';
import { IPaginationMeta } from 'nestjs-typeorm-paginate';

@Exclude()
export class MystarArtistDto {
  @Expose()
  id: number;

  @Expose()
  memberName: string;

  @Expose()
  engMemberName: string;

  @Expose()
  memberImg: string;

  @Transform(({ obj }) => obj.group.groupName)
  @Expose()
  groupName: string;

  @Transform(({ obj }) => obj.group.engGroupName)
  @Expose()
  engGroupName: string;
}

@Exclude()
export class MystarArtistMainDto {
  @Expose()
  @Type(() => MystarArtistDto)
  items: MystarArtistDto[];

  @Expose()
  readonly meta: IPaginationMeta;
}
