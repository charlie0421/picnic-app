"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const swagger_1 = require("@nestjs/swagger");
const class_transformer_1 = require("class-transformer");
const nest_winston_1 = require("nest-winston");
const auth_service_1 = require("./auth.service");
const access_and_optional_refresh_token_dto_1 = require("./dto/access-and-optional-refresh-token.dto");
const access_and_refresh_token_dto_1 = require("./dto/access-and-refresh-token.dto");
const auth_login_dto_1 = require("./dto/auth-login.dto");
const login_dto_1 = require("./dto/login.dto");
const refresh_token_dto_1 = require("./dto/refresh-token.dto");
const jwt_auth_guard_1 = require("./jwt-auth.guard");
const local_auth_guard_1 = require("./local-auth.guard");
const message_dto_1 = require("../../../common/dto/message.dto");
const enums_1 = require("../../../common/enums");
const users_service_1 = require("../../../user/src/users/users.service");
let AuthController = exports.AuthController = class AuthController {
    logger;
    configService;
    authService;
    usersService;
    constructor(logger, configService, authService, usersService) {
        this.logger = logger;
        this.configService = configService;
        this.authService = authService;
        this.usersService = usersService;
    }
    async login(req) {
        const user = req.user;
        return this.authService.login(user);
    }
    fakeLogin(loginDto) {
        if (loginDto.userId === 'user' && loginDto.password === '1234')
            return new message_dto_1.MessageDto('Login Success');
        throw 'Error';
    }
    async getMyProfile(req) {
        const { uid: uid } = req.user;
        return this.usersService.findOne(+uid);
    }
    async snsLogin(provider, providerId, name, email, profileImage) {
        let user = await this.authService.getUserIncDeletedByProviderIdOrNull(providerId);
        if (user) {
            if (user.provider && user.provider !== provider) {
                return {
                    code: 204,
                    msg: `The user already signed up by ${user.provider}`,
                };
            }
            if (!user.provider) {
                return {
                    code: 204,
                    msg: 'The user already signed up by email & password',
                };
            }
        }
        if (!user) {
            user = await this.authService.signUpBySocial(provider, providerId, name, email, profileImage);
        }
        const tokens = await this.authService.loginViaWebview(user.uid);
        return tokens;
    }
    async refreshAccessToken(req) {
        const refreshToken = req.headers.refresh.substring(7);
        const user = await this.usersService.getUserByJwt(refreshToken);
        if (this.authService.isTokenExpired(refreshToken)) {
            throw new common_1.ForbiddenException('Token is expired');
        }
        if (!(await this.authService.isRefreshToken(refreshToken))) {
            throw new common_1.BadRequestException('Token is not refresh token');
        }
        const tokens = await this.authService.refreshAccessAndRefreshToken(user);
        return (0, class_transformer_1.plainToInstance)(access_and_refresh_token_dto_1.AccessAndRefreshTokenDto, tokens);
    }
};
__decorate([
    (0, common_1.UseGuards)(local_auth_guard_1.LocalAuthGuard),
    (0, common_1.Post)('/login'),
    (0, swagger_1.ApiOperation)({ summary: '기본 인증 API', description: 'JWT Token' }),
    (0, swagger_1.ApiBody)({ type: auth_login_dto_1.AuthLoginDto }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "login", null);
__decorate([
    (0, common_1.Post)('/fakeLogin'),
    (0, swagger_1.ApiOperation)({
        summary: '테스트용 로그인',
        description: 'ID : user, PWD : 1234',
    }),
    (0, swagger_1.ApiBody)({ type: login_dto_1.LocalLoginDto }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [login_dto_1.LocalLoginDto]),
    __metadata("design:returntype", void 0)
], AuthController.prototype, "fakeLogin", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('/profiles/me'),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: '마이프로필 API',
        description: '마이프로필 정보를 가져옵니다',
    }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getMyProfile", null);
__decorate([
    (0, swagger_1.ApiQuery)({ name: 'provider', enum: enums_1.Provider }),
    (0, swagger_1.ApiQuery)({ name: 'provider_id' }),
    (0, swagger_1.ApiQuery)({ name: 'name', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'email', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'profile_image', required: false }),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, common_1.Get)('/login/sns'),
    __param(0, (0, common_1.Query)('provider')),
    __param(1, (0, common_1.Query)('provider_id')),
    __param(2, (0, common_1.Query)('name')),
    __param(3, (0, common_1.Query)('email')),
    __param(4, (0, common_1.Query)('profile_image')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "snsLogin", null);
__decorate([
    (0, swagger_1.ApiBody)({ type: refresh_token_dto_1.RefreshTokenDto }),
    (0, swagger_1.ApiForbiddenResponse)({ description: 'Token is expired' }),
    (0, swagger_1.ApiBadRequestResponse)({ description: 'Token is not refresh token' }),
    (0, swagger_1.ApiOperation)({
        summary: 'Access Token (과 Refresh Token)을 갱신하는 API',
        description: 'Refresh Token은 3일 이하로 남았을 때만 Refresh Token도 함께 갱신되고 반환',
    }),
    (0, swagger_1.ApiCreatedResponse)({ type: access_and_optional_refresh_token_dto_1.AccessAndOptionalRefreshTokenDto }),
    (0, common_1.Post)('/refreshAccessToken'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "refreshAccessToken", null);
exports.AuthController = AuthController = __decorate([
    (0, common_1.Controller)('auth'),
    __param(0, (0, common_1.Inject)(nest_winston_1.WINSTON_MODULE_PROVIDER)),
    __metadata("design:paramtypes", [common_1.Logger,
        config_1.ConfigService,
        auth_service_1.AuthService,
        users_service_1.UsersService])
], AuthController);
//# sourceMappingURL=auth.controller.js.map