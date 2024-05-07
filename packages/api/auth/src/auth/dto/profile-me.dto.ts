import { Exclude, Expose } from "class-transformer";

@Exclude()
export class ProfileMeDto {
  @Expose()
  readonly id: number;
  @Expose()
  readonly nickname: string;
  @Expose()
  readonly email: string;
  @Expose()
  readonly profileImage: string;
  @Expose()
  readonly userAgreement: {
    terms: Date;
    privacy: Date;
  };

  constructor(
    id: number,
    nickname: string,
    email: string,
    profileImage: string,
    userAgreement: {
      terms: Date;
      privacy: Date;
    }
  ) {
    this.id = id;
    this.nickname = nickname;
    this.email = email;
    this.profileImage = profileImage;
    this.userAgreement = {
      terms: userAgreement?.terms,
      privacy: userAgreement?.privacy,
    }
  }
}
