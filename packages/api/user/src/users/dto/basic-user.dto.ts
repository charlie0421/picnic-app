import { Provider } from '../enums';

export class BasicUserDto {
  readonly id: number;
  readonly nickname: string;
  readonly email: string;
  readonly imgPath: string;
  readonly provider?: Provider;

  constructor(id: number, nickname: string, email: string, imgPath: string, provider?: Provider) {
    this.id = id;
    this.nickname = nickname;
    this.email = email;
    this.imgPath = imgPath;
    this.provider = provider;
  }
}
