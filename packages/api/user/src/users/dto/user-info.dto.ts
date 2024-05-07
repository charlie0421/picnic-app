import { Exclude, Expose } from 'class-transformer';
import { UserGrade } from '../enums';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class UserInfoDto {
  @ApiProperty({ type: Number })
  @Expose()
  readonly id: number;

  @ApiProperty({ type: String })
  @Expose({ name: 'imgPath' })
  readonly userImg: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly nickname: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly email: string;

  @ApiProperty({ enum: UserGrade })
  @Expose()
  readonly grade: UserGrade;

  @ApiProperty({ type: Number })
  @Expose()
  readonly pointGst: number;

  @ApiProperty({ type: Number })
  @Expose()
  readonly pointSst: number;

  @ApiProperty({ type: Number })
  @Expose()
  readonly pointRight: number;

  @ApiProperty({ type: String })
  @Expose()
  readonly provider: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly providerId: string;

  @ApiProperty({ type: Date })
  @Expose()
  readonly agreedAt: Date;

  constructor(
    id: number,
    userImg: string,
    nickname: string,
    email: string,
    grade: UserGrade,
    pointGst: number,
    pointSst: number,
    pointRight: number,
    provider: string,
    providerId: string,
    agreedAt: Date,
  ) {
    this.id = id;
    this.userImg = userImg;
    this.nickname = nickname;
    this.email = email;
    this.grade = grade;
    this.pointGst = pointGst;
    this.pointSst = pointSst;
    this.pointRight = pointRight;
    this.provider = provider;
    this.providerId = providerId;
    this.agreedAt = agreedAt;
  }
}
