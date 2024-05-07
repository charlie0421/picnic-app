import type { Provider, TokenType } from '../enums';
export declare class JwtInputPayload {
    readonly uid: number;
    readonly id: string;
    readonly email: string;
    readonly provider?: Provider;
    readonly iss: string;
    readonly type: TokenType;
}
