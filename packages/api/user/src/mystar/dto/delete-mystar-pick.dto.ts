import { ApiProperty } from '@nestjs/swagger';

export class DeleteMystarPickDto {
  @ApiProperty({ type: [Number] })
  mystarPickIds: number[];
}
