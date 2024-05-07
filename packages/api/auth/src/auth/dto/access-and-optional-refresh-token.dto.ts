import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class AccessAndOptionalRefreshTokenDto {
  @IsString()
  @ApiProperty({ type: String, description: 'access token' })
  readonly accessToken: string;
  @IsString()
  @ApiProperty({
    type: String,
    description: 'refresh token. 3일 이하로 남았을 때만 함께 갱신되고 반환',
    required: false,
  })
  readonly refreshToken: string;

  constructor(accessToken: string, refreshToken: string) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}
