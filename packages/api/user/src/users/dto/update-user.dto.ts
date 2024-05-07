import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsString } from 'class-validator';

export class UpdateUserDto {
  @ApiProperty({ type: Number })
  @IsInt()
  @IsNotEmpty()
  readonly id: number;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly address1: string;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly address2: string;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly postcode: string;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly cellNumber: string;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly nickname: string;

  @ApiProperty({ type: String })
  @IsString()
  @IsNotEmpty()
  readonly name: string;
}
