import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
  @ApiProperty({ type: String })
  @IsString()
  newPassword: string;

  constructor(newPassword: string) {
    this.newPassword = newPassword;
  }
}
