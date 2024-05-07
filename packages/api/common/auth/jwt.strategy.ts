import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import type { Request } from 'express';
import * as jwt from 'jsonwebtoken';
import { JsonWebTokenError, TokenExpiredError } from 'jsonwebtoken';
import { Strategy } from 'passport-custom';
import {TokenType} from "../enums";
import {BasicUserDto} from "../dto/basic-user.dto";


class JwtTypeError extends Error {
  constructor(message: string) {
    super(message);
  }
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(private readonly configService: ConfigService) {
    super();
  }

  async validate(req: Request) {
    const token = req.headers['authorization']?.slice(7);
    console.log(token);
    if (!token) {
      throw new BadRequestException('There is no access token in header');
    }

    try {
      jwt.verify(token, this.configService.get('JWT_SECRET'));
      const payload = jwt.decode(token);
      if (payload['type'] !== TokenType.ACCESS_TOKEN) {
        throw new JwtTypeError('Token is not access token');
      }

      return new BasicUserDto(
        payload['id'],
        payload['nickname'],
        payload['email'],
        payload['imgPath'],
      );
    } catch (e) {
      console.log(e);
      if (e instanceof SyntaxError) {
        // payload가 잘 못 되었을 때
        throw new BadRequestException('Invalid JSON object');
      }
      if (e instanceof TokenExpiredError) {
        throw new UnauthorizedException('Token is expired');
      }
      if (e instanceof JsonWebTokenError) {
        // JwtWebTokenError should be later than TokenExpiredError
        // invalid signature | invalid token (header 깨졌을 때)
        throw new BadRequestException(e.message);
      }
      if (e instanceof JwtTypeError) {
        throw new BadRequestException('Token is not access token');
      }
      throw e;
    }
  }
}
