import { Exclude, Expose } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class VotePickForRightVoteResponseDto {
  @ApiProperty({ type: Number })
  @Expose()
  voteId: number;

  @ApiProperty({ type: Number })
  @Expose()
  voteItemId: number;

  @ApiProperty({ type: Number })
  @Expose()
  rightAmount: number;
}
