import { Exclude, Expose } from 'class-transformer';
import { UserGrade } from '../enums';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class UserBetaDto {
  @ApiProperty({ type: String })
  @Expose()
  readonly userid: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly email: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly name: string;

  constructor(userid: string, email: string, name: string) {
    this.userid = userid;
    this.email = email;
    this.name = name;
  }
}
