import {ApiProperty} from "@nestjs/swagger";
import {IsNotEmpty, IsString} from "class-validator";

export class EmailVerificationDto {
    @ApiProperty({ type: String })
    @IsString()
    @IsNotEmpty()
    code: string;
}
