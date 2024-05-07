import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AccessAndRefreshTokenDto } from './dto/access-and-refresh-token.dto';
import { LocalLoginDto } from './dto/login.dto';
import { MessageDto } from '../../../common/dto/message.dto';
import { Provider } from '../../../common/enums';
import { UsersService } from '../../../user/src/users/users.service';
export declare class AuthController {
    private readonly logger;
    private readonly configService;
    private readonly authService;
    private readonly usersService;
    constructor(logger: Logger, configService: ConfigService, authService: AuthService, usersService: UsersService);
    login(req: any): Promise<AccessAndRefreshTokenDto>;
    fakeLogin(loginDto: LocalLoginDto): MessageDto;
    getMyProfile(req: any): Promise<import("../../../schema/user.entity").User>;
    snsLogin(provider: Provider, providerId: string, name?: string, email?: string, profileImage?: string): Promise<AccessAndRefreshTokenDto | {
        code: number;
        msg: string;
    }>;
    refreshAccessToken(req: any): Promise<AccessAndRefreshTokenDto>;
}
