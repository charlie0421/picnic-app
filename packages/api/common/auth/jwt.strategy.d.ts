import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';
import { Strategy } from 'passport-custom';
import { BasicUserDto } from '../dto/basic-user.dto';
declare const JwtStrategy_base: new (...args: any[]) => Strategy;
export declare class JwtStrategy extends JwtStrategy_base {
    private readonly configService;
    constructor(configService: ConfigService);
    validate(req: Request): Promise<BasicUserDto>;
}
export {};
