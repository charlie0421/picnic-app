import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class AuthLoginDto {
  @IsString()
  @ApiProperty({ type: String, description: 'user email' })
  readonly email: string;

  @IsString()
  @ApiProperty({ type: String, description: 'user password' })
  readonly password: string;

  @IsString()
  @ApiProperty({ type: String, description: 'country code' })
  readonly countryCode: string;
}
