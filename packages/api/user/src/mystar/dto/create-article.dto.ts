import { Contains, IsOptional, IsString, Length } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateArticleDto {
  @ApiProperty({ type: String })
  @IsString()
  title: string;

  @ApiProperty({ type: String })
  @IsString()
  contents: string;

  @ApiProperty({ type: String, required: false })
  @IsOptional()
  @Contains('https://youtu.be')
  @Length(28, 28, { message: 'videoPath length should be 28' })
  videoPath?: string;

  @ApiProperty({ type: String, format: 'binary', required: false })
  @IsOptional()
  image?: any;
}
