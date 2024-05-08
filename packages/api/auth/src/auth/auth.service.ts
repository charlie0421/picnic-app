import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Injectable, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import type { JwtInputPayload } from '../../../common/dto/access-token-body.dto';
import { AccessAndRefreshTokenDto } from './dto/access-and-refresh-token.dto';
import { AccessTokenDto } from './dto/access-token.dto';
import type { BasicUserDto } from '../../../common/dto/basic-user.dto';
import { TokenType } from '../../../common/enums';
import * as bcrypt from 'bcrypt';
import { AuthLoginDto } from "./dto/auth-login.dto";
import {UserEntity} from "../../../entities/user.entity";

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @InjectRepository(UserEntity)
    private readonly userRepository: Repository<UserEntity>,
  ) {}

  async validateUser(email: string, pass: string) {
    const user = await this.userRepository.findOne({
      where: { email: email },
      withDeleted: true,
    });

    if (!user) {
      throw new NotFoundException(`There is no user where email : ${email}`);
    }

    if (user.deletedAt) {
      throw new NotFoundException(`This user is deleted`);
    }

    if (user && (await bcrypt.compare(pass, user.password))) {
      const { password, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user, loginDto?: AuthLoginDto) {
    const userInfo = {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      profileImage: user.profileImage,
      role: user.level === 100 ? 'admin' : 'user',
    };
    const accessTokenBody: JwtInputPayload = {
      ...userInfo,
      iss: this.configService.get('ISSUER'),
      type: TokenType.ACCESS_TOKEN,
    };
    const refreshTokenBody: JwtInputPayload = {
      ...userInfo,
      iss: this.configService.get('ISSUER'),
      type: TokenType.REFRESH_TOKEN,
    };

    await this.userRepository.update(user.id, { countryCode: loginDto?.countryCode, loginedAt: new Date() });

    const accessToken: string = await this.createAccessToken(accessTokenBody);
    const refreshToken: string =
      await this.createRefreshToken(refreshTokenBody);

    // TODO : Saving JWT Token to DynamoDB
    // await this.userSessionRepository.setUserSession(userInfo.id, refreshToken);

    return new AccessAndRefreshTokenDto(accessToken, refreshToken);
  }

  private async createAccessToken(accessTokenBody: JwtInputPayload) {
    return this.jwtService.sign(accessTokenBody, {
      expiresIn: this.configService.get('ACCESS_TOKEN_EXPIRES_IN'),
      secret: this.configService.get('JWT_SECRET'),
    });
  }

  private async createRefreshToken(refreshTokenBody: JwtInputPayload) {
    return this.jwtService.sign(refreshTokenBody, {
      expiresIn: this.configService.get('REFRESH_TOKEN_EXPIRES_IN'),
      secret: this.configService.get('JWT_SECRET'),
    });
  }

  isTokenExpired(refreshToken: string) {
    const decodedRefreshToken = this.jwtService.decode(refreshToken);

    return decodedRefreshToken['exp'] < new Date().valueOf() / 1000;
  }

  async isRefreshToken(refreshToken: string) {
    const decodedRefreshToken = this.jwtService.decode(refreshToken);

    return decodedRefreshToken['type'] === TokenType.REFRESH_TOKEN;
  }

  async refreshAccessToken(user: BasicUserDto) {
    const userInfo = {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      profileImage: user.profileImage,
    };
    const accessTokenBody = {
      ...userInfo,
      iss: this.configService.get('ISSUER'),
      type: TokenType.ACCESS_TOKEN,
    };

    const accessToken = await this.createAccessToken(accessTokenBody);

    return new AccessTokenDto(accessToken);
  }

  async refreshAccessAndRefreshToken(user: BasicUserDto) {
    const result = await this.login(user);
    return result;
  }


}
