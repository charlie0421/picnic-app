import { Exclude, Expose } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

@Exclude()
export class MystarMemberDto {
  @ApiProperty({ type: Number })
  @Expose()
  readonly id: number;

  @ApiProperty({ type: String })
  @Expose()
  readonly memberName: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly engMemberName: string;

  @ApiProperty({ type: String })
  @Expose()
  readonly memberImg: string;
}

@Exclude()
export class MystarMemberListDto {
    @ApiProperty({ type: MystarMemberDto })
    @Expose()
    readonly items: MystarMemberDto[];

}
