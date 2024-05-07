import { ApiProperty } from '@nestjs/swagger';

export class EmailResetPasswordResponseDto {
  @ApiProperty({ type: String, description: 'Message about the mail sent or not' })
  message: string;

  constructor(message: string) {
    this.message = message;
  }
}
