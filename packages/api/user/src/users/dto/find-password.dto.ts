import { EmailType } from '../enums';

export class FindPasswordDto {
  emailType: EmailType;
  email: string;
  jwt: string;

  constructor(emailType: EmailType, email: string, jwt: string) {
    this.emailType = emailType;
    this.email = email;
    this.jwt = jwt;
  }
}
