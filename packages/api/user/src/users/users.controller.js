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
exports.UsersController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const users_service_1 = require("./users.service");
const update_nickname_dto_1 = require("./dto/update-nickname.dto");
const reset_password_dto_1 = require("./dto/reset-password.dto");
const message_dto_1 = require("../auth/dto/message.dto");
const email_reset_password_response_dto_1 = require("./dto/email-reset-password-response.dto");
const user_id_dto_1 = require("./dto/user-id.dto");
const email_dto_1 = require("./dto/email.dto");
const update_password_dto_1 = require("./dto/update-password.dto");
const user_info_dto_1 = require("./dto/user-info.dto");
const platform_express_1 = require("@nestjs/platform-express");
const upload_profile_image_dto_1 = require("./dto/upload-profile-image.dto");
const reset_password_auth_guard_1 = require("../auth/reset-password-auth.guard");
const match_password_dto_1 = require("./dto/match-password.dto");
const user_ads_count_dto_1 = require("./dto/user-ads-count.dto");
const user_beta_dto_1 = require("./dto/user-beta.dto");
let UsersController = class UsersController {
    constructor(usersService) {
        this.usersService = usersService;
    }
    getSlotCount(req) {
        const { id: userId } = req.user;
        return this.usersService.getSlotCount(userId);
    }
    async openNewSlot(req) {
        const { id: userId } = req.user;
        const nextSlotPrice = await this.usersService.getNextSlotPrice(userId);
        if (!(await this.usersService.doesUserHaveEnoughSstToOpenNewSlot(userId, nextSlotPrice))) {
            throw new common_1.BadRequestException(`User doesn't have enough SST to open new slot`);
        }
        await this.usersService.openSlot(userId, nextSlotPrice);
        return new message_dto_1.MessageDto(`Successfully open new slot`);
    }
    findUserInfo(req) {
        const { id: userId } = req.user;
        return this.usersService.findUserInfo(userId);
    }
    async isMatchedMyEmail(req, email) {
        const { email: userEmail } = req.user;
        if (email !== userEmail) {
            throw new common_1.BadRequestException(`User email doesn't match`);
        }
        return new message_dto_1.MessageDto('User email matches');
    }
    async isMatchedMyPassword(req, { password }) {
        const user = req.user;
        if (!(await this.usersService.isMatchedPassword(user.id, password))) {
            throw new common_1.BadRequestException(`Password doesn't match`);
        }
        return new message_dto_1.MessageDto('User password matches');
    }
    async updateNickname(req, body) {
        const { id: userId } = req.user;
        const { nickname } = body;
        await this.usersService.updateNickname(userId, nickname);
        return new message_dto_1.MessageDto('Successfully updated nickname');
    }
    async emailResetPassword({ email }) {
        const userSocialProvider = await this.usersService.getUserSocialProvider(email);
        if (userSocialProvider) {
            throw new common_1.BadRequestException(`The user signed up via ${userSocialProvider}`);
        }
        const resetPasswordToken = await this.usersService.createResetPasswordToken(email);
        const response = await this.usersService.emailResetPassword(email, resetPasswordToken);
        if (response !== undefined) {
            return new email_reset_password_response_dto_1.EmailResetPasswordResponseDto('Successfully sent email');
        }
        return new email_reset_password_response_dto_1.EmailResetPasswordResponseDto('Fail to send email');
    }
    async resetPassword(req, newPassword) {
        const user = req.user;
        await this.usersService.updatePassword(user.id, newPassword.newPassword);
        return new message_dto_1.MessageDto('Successfully changed password');
    }
    async updatePassword(req, updatePasswordInfo) {
        const user = req.user;
        if (!(await this.usersService.isMatchedPassword(user.id, updatePasswordInfo.currentPassword))) {
            throw new common_1.BadRequestException('Current password is not same');
        }
        await this.usersService.updatePassword(user.id, updatePasswordInfo.newPassword);
        return new message_dto_1.MessageDto('Successfully changed password');
    }
    async findUserId(email) {
        const user = await this.usersService.getUserIdByEmail(email.email);
        return new user_id_dto_1.UserIdDto(user.userId);
    }
    async updateProfileImage(image, req) {
        const { id: userId } = req.user;
        await this.usersService.uploadProfileImage(userId, image);
        return new message_dto_1.MessageDto('Successfully saved profile image');
    }
    async deleteUser(req) {
        const { id: userId } = req.user;
        await this.usersService.deleteUser(userId);
        return new message_dto_1.MessageDto('Successfully deleted user');
    }
    checkAdsCountInHour(req) {
        const { id: userId } = req.user;
        return this.usersService.checkAdsCountInHour(userId);
    }
    checkBetaUser(req) {
        const { id: userId } = req.user;
        return this.usersService.checkBetaUser(userId);
    }
};
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Get)('/slotCount'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '사용자 슬롯 개수 API', description: '사용자의 슬롯 개수를 가져옵니다' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "getSlotCount", null);
__decorate([
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: 'SST으로 사용자 슬롯을 구매하는 API' }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/slots'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "openNewSlot", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Get)('/me'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '사용자 정보 API', description: '사용자의 정보를 가져옵니다' }),
    (0, swagger_1.ApiOkResponse)({ type: user_info_dto_1.UserInfoDto }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "findUserInfo", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Get)('/me/email'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '이메일 정보가 일치하는 지 확인합니다' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('email')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "isMatchedMyEmail", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Post)('/me/password'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: '비밀번호 정보가 일치하는 지 확인합니다',
        description: 'Android Native APP에서 GET에 Body를 보내는 게 허용되지 않아서 POST로 했습니다',
    }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, match_password_dto_1.MatchPasswordDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "isMatchedMyPassword", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Patch)('/nickname'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({ summary: '닉네임 업데이트 API', description: '사용자의 닉네임을 업데이트 합니다' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_nickname_dto_1.UpdateNicknameDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updateNickname", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '유저에게 비밀번호 변경 이메일을 보내는 API' }),
    (0, swagger_1.ApiOkResponse)({ type: email_reset_password_response_dto_1.EmailResetPasswordResponseDto }),
    (0, swagger_1.ApiBadRequestResponse)({ description: '유저가 소셜 로그인으로 가입했으면 400 에러가 발생합니다' }),
    (0, common_1.HttpCode)(200),
    (0, common_1.Post)('/sendEmail/resetPassword'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [email_dto_1.EmailDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "emailResetPassword", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '비밀번호 리셋 API (이메일을 통한 비밀번호 리셋 페이지에서 사용)' }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiBody)({ type: reset_password_dto_1.ResetPasswordDto }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, swagger_1.ApiUnauthorizedResponse)({ description: 'JWT 토큰이 만료되거나 유효하지 않으면 401 에러가 발생합니다' }),
    (0, swagger_1.ApiNotFoundResponse)({ description: 'JWT에 명시된 id에 해당하는 유저가 없으면 404 에러가 발생합니다' }),
    (0, common_1.UseGuards)(reset_password_auth_guard_1.ResetPasswordAuthGuard),
    (0, common_1.Patch)('/resetPassword'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, reset_password_dto_1.ResetPasswordDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "resetPassword", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '비밀번호 변경 API (현재 비밀번호를 아는 경우)' }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiBody)({ type: update_password_dto_1.UpdatePasswordDto }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, swagger_1.ApiBadRequestResponse)({ description: '입력한 비밀번호가 현재 비밀번호와 다르면 400 에러가 발생합니다' }),
    (0, swagger_1.ApiUnauthorizedResponse)({ description: 'JWT 토큰이 만료되거나 유효하지 않으면 401 에러가 발생합니다' }),
    (0, swagger_1.ApiNotFoundResponse)({ description: 'JWT에 명시된 id에 해당하는 유저가 없으면 404 에러가 발생합니다' }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Patch)('/password'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, update_password_dto_1.UpdatePasswordDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updatePassword", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '유저의 아이디 찾기 API' }),
    (0, swagger_1.ApiBody)({ type: email_dto_1.EmailDto }),
    (0, swagger_1.ApiOkResponse)({ type: user_id_dto_1.UserIdDto }),
    (0, swagger_1.ApiNotFoundResponse)({ description: '해당 이메일을 가진 유저가 없을 때 404 에러가 발생합니다' }),
    (0, common_1.HttpCode)(200),
    (0, common_1.Post)('/findId'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [email_dto_1.EmailDto]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "findUserId", null);
__decorate([
    (0, swagger_1.ApiOperation)({ summary: '유저 이미지 저장(변경) API' }),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiConsumes)('multipart/form-data'),
    (0, swagger_1.ApiBody)({
        description: 'user profile image',
        type: upload_profile_image_dto_1.UploadProfileImageDto,
    }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('/profileImage'),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('image')),
    __param(0, (0, common_1.UploadedFile)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updateProfileImage", null);
__decorate([
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, swagger_1.ApiOperation)({ summary: '회원탈퇴 API' }),
    (0, swagger_1.ApiBadRequestResponse)({ description: '비밀번호가 일치하지 않는 경우' }),
    (0, swagger_1.ApiOkResponse)({ type: message_dto_1.MessageDto }),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Delete)('/me'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "deleteUser", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Get)('/checkAdsCountInHour'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: '한 시간 이내 광고 조회 수',
        description: '사용자가 한 시간 내에 광고 시청하고 획득한 리워드 횟수',
    }),
    (0, swagger_1.ApiOkResponse)({ type: user_ads_count_dto_1.UserAdsCountDto }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "checkAdsCountInHour", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, swagger_1.ApiBearerAuth)('access-token'),
    (0, common_1.Get)('/checkBetaUser'),
    (0, common_1.Header)('Cache-Control', 'no-cache'),
    (0, swagger_1.ApiOperation)({
        summary: 'beta 사용자 인증',
        description: 'beta 사용자 인증 API',
    }),
    (0, swagger_1.ApiOkResponse)({ type: user_beta_dto_1.UserBetaDto }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "checkBetaUser", null);
UsersController = __decorate([
    (0, common_1.Controller)('/users'),
    (0, swagger_1.ApiTags)('Users API'),
    __metadata("design:paramtypes", [users_service_1.UsersService])
], UsersController);
exports.UsersController = UsersController;
//# sourceMappingURL=users.controller.js.map