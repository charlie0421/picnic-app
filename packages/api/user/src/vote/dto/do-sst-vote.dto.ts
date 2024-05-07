import { IsInt, IsPositive } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class DoSstVoteDto {
  @ApiProperty({ type: Number })
  // @IsPositive({ message: 'SST should be positive number' })
  // @IsInt({ message: 'SST should be integer not float or double' })
  sst: number;

  @ApiProperty({ type: Number })
  // @IsPositive({ message: 'VoteItemId should be positive number' })
  voteItemId: number;

  constructor(sst: number, voteItemId: number) {
    this.sst = sst;
    this.voteItemId = voteItemId;
  }
}
