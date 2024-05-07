import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class EmailDto {
  @ApiProperty({ type: String })
  @IsString()
  email: string;

  constructor(email: string) {
    this.email = email;
  }
}
