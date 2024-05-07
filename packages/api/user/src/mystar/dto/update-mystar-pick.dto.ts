import { ApiProperty } from '@nestjs/swagger';

export class UpdateMystarPickDto {
  @ApiProperty({ type: [Number] })
  artistIds: number[];
}
