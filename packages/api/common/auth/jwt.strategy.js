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
Object.defineProperty(exports, "__esModule", { value: true });
exports.JwtStrategy = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const passport_1 = require("@nestjs/passport");
const jwt = require("jsonwebtoken");
const jsonwebtoken_1 = require("jsonwebtoken");
const passport_custom_1 = require("passport-custom");
const basic_user_dto_1 = require("../dto/basic-user.dto");
const enums_1 = require("../enums");
class JwtTypeError extends Error {
    constructor(message) {
        super(message);
    }
}
let JwtStrategy = exports.JwtStrategy = class JwtStrategy extends (0, passport_1.PassportStrategy)(passport_custom_1.Strategy, 'jwt') {
    configService;
    constructor(configService) {
        super();
        this.configService = configService;
    }
    async validate(req) {
        const token = req.headers['authorization'].slice(7);
        if (!token) {
            throw new common_1.BadRequestException('There is no access token in header');
        }
        try {
            jwt.verify(token, this.configService.get('JWT_SECRET'));
            const payload = jwt.decode(token);
            if (payload['type'] !== enums_1.TokenType.ACCESS_TOKEN) {
                throw new JwtTypeError('Token is not access token');
            }
            return new basic_user_dto_1.BasicUserDto(payload['uid'], payload['id'], payload['nickname'], payload['email'], payload['imgPath'], payload['provider'], payload['role']);
        }
        catch (e) {
            if (e instanceof SyntaxError) {
                throw new common_1.BadRequestException('Invalid JSON object');
            }
            if (e instanceof jsonwebtoken_1.TokenExpiredError) {
                throw new common_1.UnauthorizedException('Token is expired');
            }
            if (e instanceof jsonwebtoken_1.JsonWebTokenError) {
                throw new common_1.BadRequestException(e.message);
            }
            if (e instanceof JwtTypeError) {
                throw new common_1.BadRequestException('Token is not access token');
            }
            throw e;
        }
    }
};
exports.JwtStrategy = JwtStrategy = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], JwtStrategy);
//# sourceMappingURL=jwt.strategy.js.map