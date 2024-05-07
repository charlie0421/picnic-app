import { Exclude, Expose, Type } from 'class-transformer';

@Exclude()
export class RankDetailDto {
  @Expose()
  id: number;

  @Expose()
  vote_title: string;

  @Expose()
  eng_vote_title: string;

  @Expose()
  vote_category: string;

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
  replycount: number;
}

@Exclude()
export class RankMainDto {
  @Expose()
  @Type(() => RankDetailDto)
  info: RankDetailDto;
}
