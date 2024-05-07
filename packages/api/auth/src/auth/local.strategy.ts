import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import type { IVerifyOptions } from 'passport-local';
import { Strategy } from 'passport-local';
import {AuthService} from "./auth.service";


@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({ usernameField: 'email' });
  }

  async validate(
    email: string,
    password: string,
    done: (error: any, user?: any, options?: IVerifyOptions) => void,
  ): Promise<any> {
    const user = await this.authService.validateUser(email, password);
    if (!user) {
      throw new UnauthorizedException();
    }
    done(null, user, null);
  }
}
