import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Get,
  Header,
  Inject,
  Logger,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiOperation,
  ApiQuery, ApiTags,
} from '@nestjs/swagger';
import { plainToInstance } from 'class-transformer';
import { WINSTON_MODULE_PROVIDER } from 'nest-winston';

import { AuthService } from './auth.service';
import { AccessAndOptionalRefreshTokenDto } from './dto/access-and-optional-refresh-token.dto';
import { AccessAndRefreshTokenDto } from './dto/access-and-refresh-token.dto';
import { AuthLoginDto } from './dto/auth-login.dto';
import { LocalLoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import type { BasicUserDto } from '../../../common/dto/basic-user.dto';
import { MessageDto } from '../../../common/dto/message.dto';
import { ProfileMeDto } from "./dto/profile-me.dto";
import { UsersService } from '../../../user/src/users/users.service';
import { LocalAuthGuard } from '../../../common/auth/local-auth.guard';
import { JwtAuthGuard } from '../../../common/auth/jwt-auth.guard';

@Controller('auth')
@ApiTags('Auth API')
export class AuthController {
  constructor(
    @Inject(WINSTON_MODULE_PROVIDER) private readonly logger: Logger,
    private readonly configService: ConfigService,
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  @UseGuards(LocalAuthGuard)
  @Post('/login')
  @ApiOperation({ summary: '기본 인증 API', description: 'JWT Token' })
  @ApiBody({ type: AuthLoginDto })
  async login(@Request() req, @Body() loginDto: AuthLoginDto) {
    const user: BasicUserDto = req.user;
    return this.authService.login(user, loginDto);
  }

  @Post('/fakeLogin')
  @ApiOperation({
    summary: '테스트용 로그인',
    description: 'ID : user, PWD : 1234',
  })
  @ApiBody({ type: LocalLoginDto })
  fakeLogin(@Body() loginDto: LocalLoginDto) {
    if (loginDto.userId === 'user' && loginDto.password === '1234')
      return new MessageDto('Login Success');
    throw 'Error';
  }

  @UseGuards(JwtAuthGuard)
  @Get('/profiles/me')
  @ApiBearerAuth('access-token')
  @Header('Cache-Control', 'no-cache')
  @ApiOperation({
    summary: '마이프로필 API',
    description: '마이프로필 정보를 가져옵니다',
  })
  async getMyProfile(@Request() req) {
    const { id: id } = req.user as BasicUserDto;
    console.log(req.user);
    console.log('await this.usersService.findOne(id)', await this.usersService.findOne(id));
    console.log('plainToInstance(ProfileMeDto, await this.usersService.findOne(id), ', plainToInstance(ProfileMeDto, await this.usersService.findOne(id)));
    return plainToInstance(ProfileMeDto, await this.usersService.findOne(id));
  }


  // Todo: Use RefreshTokenGuard later (custom strategy)
  @ApiBody({ type: RefreshTokenDto })
  @ApiForbiddenResponse({ description: 'Token is expired' })
  @ApiBadRequestResponse({ description: 'Token is not refresh token' })
  @ApiOperation({
    summary: 'Access Token (과 Refresh Token)을 갱신하는 API',
    description:
      'Refresh Token은 3일 이하로 남았을 때만 Refresh Token도 함께 갱신되고 반환',
  })
  @ApiCreatedResponse({ type: AccessAndOptionalRefreshTokenDto })
  @Post('/refreshAccessToken')
  async refreshAccessToken(@Request() req) {
    const refreshToken = req.headers.refresh.substring(7);

    const user = await this.usersService.getUserByJwt(refreshToken);
    // if (await this.authService.isTokenDuplicated(user.id, refreshToken)) {
    //   throw new ForbiddenException('Token is duplicated');
    // }

    if (this.authService.isTokenExpired(refreshToken)) {
      throw new ForbiddenException('Token is expired');
    }

    if (!(await this.authService.isRefreshToken(refreshToken))) {
      throw new BadRequestException('Token is not refresh token');
    }

    const tokens = await this.authService.refreshAccessAndRefreshToken(user);
    return plainToInstance(AccessAndRefreshTokenDto, tokens);
  }
}
