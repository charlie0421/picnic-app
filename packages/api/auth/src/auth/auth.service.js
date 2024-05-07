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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const access_and_refresh_token_dto_1 = require("./dto/access-and-refresh-token.dto");
const access_token_dto_1 = require("./dto/access-token.dto");
const apple_user_dto_1 = require("./dto/apple-user.dto");
const facebook_user_dto_1 = require("./dto/facebook-user.dto");
const google_user_dto_1 = require("./dto/google-user.dto");
const kakao_user_dto_1 = require("./dto/kakao-user.dto");
const enums_1 = require("../../../common/enums");
const user_entity_1 = require("../../../schema/user.entity");
const user_profile_entity_1 = require("../../../schema/user_profile.entity");
const crypto = require('crypto');
let AuthService = exports.AuthService = class AuthService {
    jwtService;
    configService;
    userRepository;
    userProfileRepository;
    constructor(jwtService, configService, userRepository, userProfileRepository) {
        this.jwtService = jwtService;
        this.configService = configService;
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
    }
    async validateUser(userId, pass) {
        const user = await this.userRepository.findOne({
            where: { id: userId },
        });
        if (!user) {
            throw new common_1.NotFoundException(`There is no user where id: ${userId}`);
        }
        const encryptedPW = crypto.createHash('md5').update(pass).digest('hex');
        if (user.password === encryptedPW) {
            const { password, ...result } = user;
            return result;
        }
        return null;
    }
    async login(user) {
        const userInfo = {
            uid: user.uid,
            id: user.id,
            email: user.email,
            provider: user.provider,
            role: user.level === 100 ? 'admin' : 'user',
        };
        const accessTokenBody = {
            ...userInfo,
            iss: this.configService.get('ISSUER'),
            type: enums_1.TokenType.ACCESS_TOKEN,
        };
        const refreshTokenBody = {
            ...userInfo,
            iss: this.configService.get('ISSUER'),
            type: enums_1.TokenType.REFRESH_TOKEN,
        };
        const accessToken = await this.createAccessToken(accessTokenBody);
        const refreshToken = await this.createRefreshToken(refreshTokenBody);
        return new access_and_refresh_token_dto_1.AccessAndRefreshTokenDto(accessToken, refreshToken);
    }
    async createAccessToken(accessTokenBody) {
        return this.jwtService.sign(accessTokenBody, {
            expiresIn: this.configService.get('ACCESS_TOKEN_EXPIRES_IN'),
            secret: this.configService.get('JWT_SECRET'),
        });
    }
    async createRefreshToken(refreshTokenBody) {
        return this.jwtService.sign(refreshTokenBody, {
            expiresIn: this.configService.get('REFRESH_TOKEN_EXPIRES_IN'),
            secret: this.configService.get('JWT_SECRET'),
        });
    }
    async signUpBySocial(provider, providerId, name, email, profileImage) {
        switch (provider) {
            case enums_1.Provider.GOOGLE: {
                const nickname = email.split('@')[0];
                const googleUser = new google_user_dto_1.GoogleUserDto(providerId, nickname, email, profileImage);
                return this.signUpByGoogle(googleUser);
            }
            case enums_1.Provider.APPLE: {
                const appleUser = new apple_user_dto_1.AppleUserDto(providerId, name, email, profileImage);
                return this.signUpByApple(appleUser);
            }
            case enums_1.Provider.KAKAOTALK: {
                const kakaoUser = new kakao_user_dto_1.KakaoUserDto(providerId, name, email, profileImage);
                return this.signUpByKakao(kakaoUser);
            }
            case enums_1.Provider.FACEBOOK: {
                const facebookUser = new facebook_user_dto_1.FacebookUserDto(providerId, name, email, profileImage);
                return this.signUpByFacebook(facebookUser);
            }
        }
    }
    async signUpByGoogle(googleUser) {
        const user = await this.userRepository.save(user_entity_1.User.googleUser(googleUser));
        const userProfile = new user_profile_entity_1.UserProfile();
        userProfile.uid = user.uid;
        userProfile.profileImage = googleUser.profileImage;
        await this.userProfileRepository.save(userProfile);
        return user;
    }
    async signUpByKakao(kakaoUser) {
        const user = await this.userRepository.save(user_entity_1.User.kakaoUser(kakaoUser));
        const userProfile = new user_profile_entity_1.UserProfile();
        userProfile.uid = user.uid;
        userProfile.profileImage = kakaoUser.profileImage;
        await this.userProfileRepository.save(userProfile);
        return user;
    }
    async signUpByFacebook(facebookUser) {
        const user = await this.userRepository.save(user_entity_1.User.facebookUser(facebookUser));
        const userProfile = new user_profile_entity_1.UserProfile();
        userProfile.uid = user.uid;
        userProfile.profileImage = facebookUser.profileImage;
        await this.userProfileRepository.save(userProfile);
        return user;
    }
    async signUpByApple(appleUser) {
        const user = await this.userRepository.save(user_entity_1.User.appleUser(appleUser));
        const userProfile = new user_profile_entity_1.UserProfile();
        userProfile.uid = user.uid;
        userProfile.profileImage = appleUser.profileImage;
        await this.userProfileRepository.save(userProfile);
        return user;
    }
    async getUserIncDeletedByProviderIdOrNull(providerId) {
        return this.userRepository.findOne({
            where: { providerId },
            withDeleted: true,
        });
    }
    async loginViaWebview(userId) {
        const user = await this.userRepository.findOne({ where: { uid: userId } });
        if (!user) {
            throw new common_1.NotFoundException(`There is no user where userId: ${userId}`);
        }
        user.lastLogin = BigInt(new Date().getTime());
        await this.userRepository.save(user);
        return this.login({
            uid: user.uid,
            id: user.id,
            email: user.email,
            provider: user.provider,
        });
    }
    isTokenExpired(refreshToken) {
        const decodedRefreshToken = this.jwtService.decode(refreshToken);
        return decodedRefreshToken['exp'] < new Date().valueOf() / 1000;
    }
    async isRefreshToken(refreshToken) {
        const decodedRefreshToken = this.jwtService.decode(refreshToken);
        return decodedRefreshToken['type'] === enums_1.TokenType.REFRESH_TOKEN;
    }
    async refreshAccessToken(user) {
        const userInfo = {
            uid: user.uid,
            id: user.id,
            email: user.email,
            nickname: user.nickname,
            imgPath: user.imgPath,
            provider: user.provider,
        };
        const accessTokenBody = {
            ...userInfo,
            iss: this.configService.get('ISSUER'),
            type: enums_1.TokenType.ACCESS_TOKEN,
        };
        const accessToken = await this.createAccessToken(accessTokenBody);
        return new access_token_dto_1.AccessTokenDto(accessToken);
    }
    async refreshAccessAndRefreshToken(user) {
        const result = await this.login(user);
        return result;
    }
};
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(3, (0, typeorm_1.InjectRepository)(user_profile_entity_1.UserProfile)),
    __metadata("design:paramtypes", [jwt_1.JwtService,
        config_1.ConfigService,
        typeorm_2.Repository,
        typeorm_2.Repository])
], AuthService);
//# sourceMappingURL=auth.service.js.map