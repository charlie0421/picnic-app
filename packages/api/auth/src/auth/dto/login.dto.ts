import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class LocalLoginDto {
  @IsString()
  @ApiProperty({ type: String, description: 'user id' })
  readonly userId: string;

  @IsString()
  @ApiProperty({ type: String, description: 'user password' })
  readonly password: string;
}
