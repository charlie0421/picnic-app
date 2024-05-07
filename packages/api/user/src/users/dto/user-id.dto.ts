import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UserIdDto {
  @ApiProperty({ type: String })
  @IsString()
  userId: string;

  constructor(userId: string) {
    this.userId = userId;
  }
}
