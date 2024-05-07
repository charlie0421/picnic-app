import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Transform, TransformFnParams } from 'class-transformer';

export class CreateVoteReplyDto {
  @IsString()
  @IsNotEmpty({ message: 'text should not be blank or null or space(s)' })
  @Transform(({ value }: TransformFnParams) => value.trim())
  @ApiProperty({ type: String, description: 'comment' })
  reply_text: string;
}
