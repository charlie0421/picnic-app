/// <reference types="multer" />
import { UsersService } from './users.service';
import { UpdateNicknameDto } from './dto/update-nickname.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { MessageDto } from '../auth/dto/message.dto';
import { EmailResetPasswordResponseDto } from './dto/email-reset-password-response.dto';
import { UserIdDto } from './dto/user-id.dto';
import { EmailDto } from './dto/email.dto';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { UserInfoDto } from './dto/user-info.dto';
import { MatchPasswordDto } from './dto/match-password.dto';
import { UserAdsCountDto } from './dto/user-ads-count.dto';
import { UserBetaDto } from './dto/user-beta.dto';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    getSlotCount(req: any): Promise<import("./dto/user-slot-count.dto").UserSlotCountDto>;
    openNewSlot(req: any): Promise<MessageDto>;
    findUserInfo(req: any): Promise<UserInfoDto>;
    isMatchedMyEmail(req: any, email: string): Promise<MessageDto>;
    isMatchedMyPassword(req: any, { password }: MatchPasswordDto): Promise<MessageDto>;
    updateNickname(req: any, body: UpdateNicknameDto): Promise<MessageDto>;
    emailResetPassword({ email }: EmailDto): Promise<EmailResetPasswordResponseDto>;
    resetPassword(req: any, newPassword: ResetPasswordDto): Promise<MessageDto>;
    updatePassword(req: any, updatePasswordInfo: UpdatePasswordDto): Promise<MessageDto>;
    findUserId(email: EmailDto): Promise<UserIdDto>;
    updateProfileImage(image: Express.Multer.File, req: any): Promise<MessageDto>;
    deleteUser(req: any): Promise<MessageDto>;
    checkAdsCountInHour(req: any): Promise<UserAdsCountDto>;
    checkBetaUser(req: any): Promise<UserBetaDto>;
}
