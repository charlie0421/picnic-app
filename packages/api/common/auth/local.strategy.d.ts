import type { IVerifyOptions } from 'passport-local';
import { AuthService } from '../../auth/src/auth/auth.service';
declare const LocalStrategy_base: new (...args: any[]) => any;
export declare class LocalStrategy extends LocalStrategy_base {
    private authService;
    constructor(authService: AuthService);
    validate(userId: string, password: string, done: (error: any, user?: any, options?: IVerifyOptions) => void): Promise<any>;
}
export {};
