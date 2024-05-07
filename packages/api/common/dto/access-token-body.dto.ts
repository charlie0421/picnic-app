import type { TokenType } from '../enums';

export class JwtInputPayload {
  readonly id: number;
  readonly email: string;
  readonly nickname: string;
  readonly profileImage: string;
  readonly iss: string;
  readonly type: TokenType;
}
