import { Provider } from '../enums';
export declare class BasicUserDto {
    readonly id: number;
    readonly nickname: string;
    readonly email: string;
    readonly imgPath: string;
    readonly provider?: Provider;
    constructor(id: number, nickname: string, email: string, imgPath: string, provider?: Provider);
}
