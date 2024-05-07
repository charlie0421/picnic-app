import { ApiProperty } from '@nestjs/swagger';
import { Exclude, Expose } from 'class-transformer';

@Exclude()
export class MystarPickDto {
  @ApiProperty({ type: Number })
  @Expose()
  usersId: number;

  @ApiProperty({ type: Number })
  @Expose({ name: 'mystarMemberId' })
  artistId: number;

  constructor(usersId: number, artistId: number) {
    this.usersId = usersId;
    this.artistId = artistId;
  }
}
