import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class MatchPasswordDto {
  @ApiProperty({ type: String })
  @IsString()
  password: string;
}
