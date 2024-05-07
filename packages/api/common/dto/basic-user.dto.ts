export class BasicUserDto {
  readonly id: number;
  readonly nickname: string;
  readonly email: string;
  readonly profileImage: string;

  constructor(
    id: number,
    nickname: string,
    email: string,
    profileImage: string,
  ) {
    this.id = id;
    this.nickname = nickname;
    this.email = email;
    this.profileImage = profileImage;
  }
}
