import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class MessageDto {
  @IsString()
  @ApiProperty({ type: String })
  message: string;

  constructor(message: string) {
    this.message = message;
  }
}
