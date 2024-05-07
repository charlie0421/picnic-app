import { ApiProperty } from '@nestjs/swagger';

export class UploadProfileImageDto {
  @ApiProperty({ type: 'string', format: 'binary' })
  image: any;
}
