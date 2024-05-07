import {
    Body,
    Controller,
    Delete,
    Get,
    Logger,
    Param,
    Patch,
    Post,
    Put,
    Request,
    UploadedFile,
    UseGuards,
    UseInterceptors
} from "@nestjs/common";
import {ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiParam, ApiTags,} from '@nestjs/swagger';

import {CreateUserDto} from './dto/create-user.dto';
import {UpdateUserDto} from './dto/update-user.dto';
import {UsersService} from './users.service';
import { JwtAuthGuard } from 'api-auth/dist/auth/src/auth/jwt-auth.guard';
import type {BasicUserDto} from '../../../common/dto/basic-user.dto';
import {FileInterceptor} from '@nestjs/platform-express';
import {UploadProfileImageDto} from './dto/upload-profile-image.dto';
import {MessageDto} from '../../../common/dto/message.dto';
import * as multer from 'multer';
import {UpdateNicknameDto} from "./dto/update-nickname.dto";
import {plainToInstance} from "class-transformer";
import {EmailVerificationDto} from "./dto/email-verification.dto";

@ApiTags('Users API')
@Controller('user/users')
export class UsersController {
    private readonly logger = new Logger(UsersController.name);

    constructor(private readonly usersService: UsersService) {
    }

    @ApiOperation({
        summary: '유저 상세 API',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('/me')
    async findOne(@Request() req) {
        const {id} = req.user as BasicUserDto;
        return this.usersService.findOne(id);
    }

    @ApiOperation({
        summary: '유저 추가 API',
    })
    @Post('/me')
    async create(@Request() req, @Body() createUserDto: CreateUserDto) {
        return this.usersService.create(createUserDto);
    }


    @ApiOperation({
        summary: '이메일 인증',
    })
    @ApiBody({
        description: 'email verification code',
        type: EmailVerificationDto,
    })
    @Post('/emailVerification')
    async emailVerification(@Body() body: { code: string }) {
        return this.usersService.emailVerification(body.code);
    }

    @ApiOperation({
        summary: '유저 정보 수정 API',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Put('/me')
    async update(@Request() req, @Body() updateUserDto: UpdateUserDto) {
        const {id} = req.user as BasicUserDto;

        return this.usersService.update({id, ...updateUserDto});
    }

    @ApiOperation({
        summary: '닉네임중복 확인  API',
    })
    @ApiParam({
        name: 'nickname',
        required: true,
        type: String,
    })
    @Get('/nickname/:nickname')
    async checkNickname(@Param('nickname') nickname: string) {
        return this.usersService.checkNickname(nickname);
    }

    @ApiOperation({
        summary: '닉네임 수정  API',
    })
    @ApiParam({
        name: 'nickname',
        required: true,
        type: String,
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Patch('/nickname')
    async changeNickname(@Request() req, @Body() updateNicknameDto: UpdateNicknameDto) {
        const {id} = req.user as BasicUserDto;
        return this.usersService.changeNickname(id, updateNicknameDto);
    }

    @ApiOperation({
        summary: '이메일 중복 확인 API',
    })
    @ApiParam({
        name: 'email',
        required: true,
        type: String,
    })
    @Get('/email/:email')
    async checkEmail(@Param('email') email: string) {
        return this.usersService.checkEmail(email);
    }

    @ApiOperation({summary: '유저 이미지 저장(변경) API'})
    @ApiBearerAuth('access-token')
    @ApiConsumes('multipart/form-data')
    @ApiBody({
        description: 'user profile image',
        type: UploadProfileImageDto,
    })
    @UseGuards(JwtAuthGuard)
    @Post('/profileImage')
    @UseInterceptors(
        FileInterceptor('profileImage', {storage: multer.memoryStorage()}),
    )
    async updateProfileImage(
        @UploadedFile() image: Express.Multer.File,
        @Request() req,
    ) {
        const {id: userId}: BasicUserDto = req.user;

        await this.usersService.uploadProfileImage(userId, image);

        return new MessageDto('Successfully saved profile image');
    }

    @ApiOperation({
        summary: '비밀번호 확인',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Post('/passwordCheck')
    async passwordCheck(@Request() req, @Body() body: { password: string }) {
        const {id} = req.user as BasicUserDto;
        const result = await this.usersService.passwordCheck(id, body.password);
        return plainToInstance(MessageDto, result);
    }

    @ApiOperation({
        summary: '유저 탈퇴 API',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Delete('/withdrawal')
    async withdraw(@Request() req) {
        const {id} = req.user as BasicUserDto;
        const result = await this.usersService.withdraw(id);
        return plainToInstance(MessageDto, result.affected === 1);
    }
}
