import {Injectable, Logger} from "@nestjs/common";
import {S3Service} from "../s3/s3.service";
import {SendEmailCommand, SESClient} from "@aws-sdk/client-ses";
import {ConfigService} from "@nestjs/config";
import { GetObjectCommandOutput } from "@aws-sdk/client-s3";
import { Readable } from "stream";

@Injectable()
export class SesService {
    private readonly logger = new Logger(SesService.name);
    private readonly sesClient: SESClient;

    constructor(
        private readonly s3Service: S3Service,
        private readonly configService: ConfigService,
    ) {
        this.sesClient = new SESClient({
            credentials: {
                accessKeyId: this.configService.get<string>("AWS_ACCESS_KEY"),
                secretAccessKey: this.configService.get<string>("AWS_SECRET_ACCESS_KEY"),
            },
            region: this.configService.get<string>("AWS_REGION"),
        });
    }

    async getFileAsString(response: GetObjectCommandOutput) {

        const stream = response.Body as Readable; // 'ReadableStream'으로 타입 단언

        return new Promise((resolve, reject) => {
            const chunks = [];
            stream.on("data", (chunk) => chunks.push(chunk));
            stream.on("error", reject);
            stream.on("end", () => {
                const combined = Buffer.concat(chunks);
                resolve(combined.toString("utf-8"));
            });
        });
    }


    async sendVerificationEmail(email: string, emailVerificationToken: string) {

        const response = await this.s3Service.getFile(
            "email_template",
            "verification_email.html",

        );
        const bodyContents : string = await this.getFileAsString(response) as string;

        const customizedTemplate = bodyContents.replaceAll(
            "{{verificationCode}}",
            emailVerificationToken
        );

        const params = {
            Source: "noreply@1stype.io",
            Destination: {ToAddresses: [email]},
            Message: {
                Subject: {Data: "Verify Your Email"},
                Body: {
                    Html: {
                        Charset: "UTF-8",
                        Data: customizedTemplate,
                    },
                },
            },
        };

        try {
            const ret = await this.sesClient.send(new SendEmailCommand(params));
        } catch (error) {
            this.logger.error(error);
        }
    }
}
