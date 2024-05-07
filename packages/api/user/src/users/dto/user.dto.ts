import { Exclude, Expose, Type } from 'class-transformer';
import { IPaginationMeta } from 'nestjs-typeorm-paginate';

@Exclude()
export class UserListDto {
  @Expose()
  @Type(() => UserDto)
  items: UserDto[];

  @Expose()
  readonly meta: IPaginationMeta;
}

@Exclude()
export class UserDto {

  @Expose()
  id: string;

  @Expose()
  nickName: string;

  @Expose()
  imgPath: string;

  @Expose()
  email: string;

}
