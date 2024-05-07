import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsString } from 'class-validator';

export class UpdateNicknameDto {
  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly nickname: string;

}
