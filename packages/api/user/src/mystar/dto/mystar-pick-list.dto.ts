import { Exclude, Expose, Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class MystarPickListDto {
  @ApiProperty({ type: Number })
  @Expose()
  id: number;

  @ApiProperty({ type: Number })
  @Transform(({ obj }) => obj.member?.id)
  @Expose()
  memberId: number;

  @ApiProperty({ type: String })
  @Transform(({ obj }) => obj.member?.memberName)
  @Expose()
  memberName: string;

  @ApiProperty({ type: String })
  @Transform(({ obj }) => obj.member?.engMemberName)
  @Expose()
  engMemberName: string;

  @ApiProperty({ type: String })
  @Transform(({ obj }) => obj.member?.memberImg)
  @Expose()
  memberImg: string;
}
