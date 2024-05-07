import * as path from "path";
import { Injectable, Logger } from "@nestjs/common";
import { v4 } from "uuid";
import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";

@Injectable()
export class S3Service {
  private readonly logger = new Logger(S3Service.name);
  private s3Client: S3Client;

  constructor() {
    this.s3Client = new S3Client({
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      },
      region: process.env.AWS_REGION,
    });
  }

  async getFile(folder: string, filename: string) {

    return this.s3Client.send(
      new GetObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        Key: `${folder}/${filename}`,
      }),
    );
  }

  async uploadFile(folder: string, filename : string, file: Express.Multer.File) {

    const uploadParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: `${folder}/${filename}${path.extname(file.originalname)}`,
      Body: file.buffer,
    };

    return this.s3Client.send(new PutObjectCommand(uploadParams));
  }

  deleteFile(folder: string, filename: string) {
    return this.s3Client.send(
      new DeleteObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        Key: `${folder}/${filename}`,
      }),
    );
  }
}
