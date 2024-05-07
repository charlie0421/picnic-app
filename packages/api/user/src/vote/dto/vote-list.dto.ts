import { Exclude, Expose, Type } from 'class-transformer';
import { ValidateNested } from 'class-validator';
import { IPaginationMeta } from 'nestjs-typeorm-paginate';

@Exclude()
export class VoteItemDto {
  @Expose()
  id: number;

  @Expose()
  item_img: string;
}

@Exclude()
export class VoteDto {
  @Expose()
  id: number;

  @Expose()
  vote_title: string;

  @Expose()
  eng_vote_title: string;

  @Expose()
  vote_category: string;

  @Expose()
  wait_img: string;

  @Expose()
  main_img: string;

  @Expose()
  result_img: string;

  @Expose()
  vote_content: string;

  @Expose()
  eng_vote_content: string;

  @Expose()
  vote_episode: string;

  @Expose()
  eng_vote_episode: string;

  @Expose()
  start_at: Date;

  @Expose()
  stop_at: Date;

  @Expose()
  visible_at: Date;

  @Expose()
  replycount: number;

  @Expose()
  @ValidateNested({ each: true })
  @Type(() => VoteItemDto)
  items: VoteItemDto[];
}

@Exclude()
export class VoteMainDto {
  @Expose()
  // @ValidateNested({ each: true })
  @Type(() => VoteDto)
  items: VoteDto[];

  @Expose()
  readonly meta: IPaginationMeta;
}
