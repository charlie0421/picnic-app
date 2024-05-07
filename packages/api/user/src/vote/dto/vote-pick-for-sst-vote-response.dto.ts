import { Exclude, Expose } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class VotePickForSstVoteResponseDto {
  @ApiProperty({ type: Number })
  @Expose()
  voteId: number;

  @ApiProperty({ type: Number })
  @Expose()
  voteItemId: number;

  @ApiProperty({ type: Number })
  @Expose({ name: 'pointAmount' })
  sstAmount: number;
}
