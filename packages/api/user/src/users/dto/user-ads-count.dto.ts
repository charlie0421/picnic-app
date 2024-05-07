import { Exclude, Expose } from 'class-transformer';
import { UserGrade } from '../enums';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class UserAdsCountDto {
  @ApiProperty({ type: Number })
  @Expose()
  readonly count: number;

  constructor(count: number) {
    this.count = count;
  }
}
