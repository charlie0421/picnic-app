import type { Provider } from '../enums';
export declare class BasicUserDto {
    readonly uid: number;
    readonly id: string;
    readonly nickname: string;
    readonly email: string;
    readonly imgPath: string;
    readonly provider?: Provider;
    readonly role: string;
    constructor(uid: number, id: string, nickname: string, email: string, imgPath: string, provider?: Provider, role?: string);
}
