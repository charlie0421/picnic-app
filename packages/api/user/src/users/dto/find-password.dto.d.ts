import { EmailType } from '../enums';
export declare class FindPasswordDto {
    emailType: EmailType;
    email: string;
    jwt: string;
    constructor(emailType: EmailType, email: string, jwt: string);
}
