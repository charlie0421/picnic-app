import { Exclude, Expose, Transform, TransformFnParams, Type } from 'class-transformer';
import { IPaginationMeta } from 'nestjs-typeorm-paginate';
import { ApiProperty } from '@nestjs/swagger';
import { PaginationMetaDto } from './pagination-meta.dto';

@Exclude()
export class MystarArticleForRawQueryDto {
  @ApiProperty({ type: Number })
  @Expose()
  id: number;

  @ApiProperty({ type: Number })
  @Expose({ name: 'user_id' })
  usersId: number;

  @Exclude()
  mystarMemberId: number;

  @ApiProperty({ type: String })
  @Expose()
  title: string;

  @ApiProperty({ type: String })
  @Expose()
  contents: string;

  @ApiProperty({ type: String })
  @Expose({ name: 'img_path' })
  @Transform(({ obj }: TransformFnParams) => {
    if (obj.video_path) {
      const path = obj.video_path.replace('https://youtu.be/', '');
      return `http://img.youtube.com/vi/${path}/1.jpg`;
    }
    if (obj.img_path) {
      return `${process.env.CDN_PATH_FOLLOWER}/${obj.member_id}/${obj.img_path}`;
    }
    return null;
  })
  imgPath: string;

  @ApiProperty({ type: Date })
  @Expose({ name: 'created_at' })
  createdAt: Date;
}

@Exclude()
export class MystarArticleDto {
  @ApiProperty({ type: Number })
  @Expose()
  id: number;

  @ApiProperty({ type: Number })
  @Expose()
  usersId: number;

  @ApiProperty({ type: String })
  @Expose()
  title: string;

  @ApiProperty({ type: String })
  @Expose()
  contents: string;

  @ApiProperty({ type: String })
  @Transform(({ obj }) => (obj.videoPath ? obj.videoImgPath : obj.imgPath))
  @Expose()
  imgPath: string;

  @ApiProperty({ type: Date })
  @Expose({ name: 'created_at' })
  createdAt: Date;
}

@Exclude()
export class MystarFollowerReplyDto {
  @Expose()
  readonly id: number;

  @Transform(({ obj }) => obj.user.imgPath)
  @Expose()
  readonly userProfileImgPath: string;

  @Transform(({ obj }) => obj.user.nickname)
  @Expose()
  readonly userNickname: string;

  @Expose()
  readonly replyText: string;

  @Expose()
  readonly createdAt: Date;

  @Expose()
  readonly isReported: boolean;
}

@Exclude()
export class MystarFollowerDetailDto {
  @Expose()
  readonly id: number;

  @Transform(({ obj }) => obj.member.memberImg)
  @Expose()
  readonly memberProfileImgPath: string;

  @Expose()
  readonly title: string;

  @Expose({ name: 'created_at' })
  readonly createdAt: Date;

  @Transform(({ obj }) => obj.user.nickname)
  @Expose()
  readonly userNickname: string;

  @Transform(({ obj }) => obj.user.imgPath)
  @Expose()
  readonly userProfileImgPath: string;

  @Expose()
  readonly videoPath: string;

  @Expose()
  readonly imgPath: string;

  @Expose()
  readonly contents: string;

  @Expose()
  readonly replyCount: number;
}

@Exclude()
export class MystarArticlesPaginationForRawQueryDto {
  @Expose()
  @Type(() => MystarArticleForRawQueryDto)
  @ApiProperty({ type: [MystarArticleForRawQueryDto] })
  items: MystarArticleForRawQueryDto[];

  @Expose()
  @ApiProperty({ type: PaginationMetaDto })
  readonly meta: IPaginationMeta;
}

@Exclude()
export class MystarArticlesPaginationDto {
  @Expose()
  @Type(() => MystarArticleDto)
  @ApiProperty({ type: [MystarArticleDto] })
  items: MystarArticleDto[];

  @Expose()
  @ApiProperty({ type: PaginationMetaDto })
  readonly meta: IPaginationMeta;
}

@Exclude()
export class MystarArticlesListDto {
  @Expose()
  @Type(() => MystarArticleDto)
  @ApiProperty({ type: [MystarArticleDto] })
  items: MystarArticleDto[];
}

@Exclude()
export class MystarFollowerReplyMainDto {
  @Expose()
  @Type(() => MystarFollowerReplyDto)
  items: MystarFollowerReplyDto[];

  @Expose()
  readonly meta: IPaginationMeta;
}
