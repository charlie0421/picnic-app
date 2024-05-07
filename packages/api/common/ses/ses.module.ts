import { Module, Session } from "@nestjs/common";
import { S3Module } from "../s3/s3.module";
import { SesService } from "./ses.service";

@Module({
  imports: [S3Module],
  providers: [SesService],
  exports: [SesService],
})
export class SesModule {}
