import { ApiProperty } from '@nestjs/swagger';
import { Contains, IsNotEmpty, IsOptional, IsString, Length, ValidateIf } from 'class-validator';

// refer: https://github.com/typestack/class-validator/issues/579
export class UpdateArticleDto {
  @ApiProperty({ type: String, required: false })
  @ValidateIf((object, value) => value !== undefined)
  @IsNotEmpty({ message: 'title should not be blank or null' })
  @IsString()
  title?: string;

  @ApiProperty({ type: String, required: false })
  @ValidateIf((object, value) => value !== undefined)
  @IsNotEmpty({ message: 'contents should not be blank or null' })
  @IsString()
  contents?: string;

  @ApiProperty({ type: String, required: false })
  @IsOptional()
  @Contains('https://youtu.be')
  @Length(28, 28, { message: 'videoPath length should be 28' })
  videoPath?: string;

  @ApiProperty({ type: String, format: 'binary', required: false })
  @IsOptional()
  image?: any;
}
