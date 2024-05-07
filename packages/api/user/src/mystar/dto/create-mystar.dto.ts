import { IsInt } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateMystarDto {
  @ApiProperty({ type: Number })
  @IsInt()
  artistId: number;

  @ApiProperty({ type: Number })
  sort_id?: number;
}
