import { UserGrade } from '../enums';
export declare class UserInfoDto {
    readonly id: number;
    readonly userImg: string;
    readonly nickname: string;
    readonly email: string;
    readonly grade: UserGrade;
    readonly pointGst: number;
    readonly pointSst: number;
    readonly pointRight: number;
    constructor(id: number, userImg: string, nickname: string, email: string, grade: UserGrade, pointGst: number, pointSst: number, pointRight: number);
}
