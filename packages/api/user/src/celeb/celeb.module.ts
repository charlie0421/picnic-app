import {Module} from '@nestjs/common';
import {CelebService} from './celeb.service';
import {CelebController} from './celeb.controller';
import {TypeOrmModule} from '@nestjs/typeorm';
import {JwtStrategy} from '../../../common/auth/jwt.strategy';
import {Celeb} from "../../../entities/celeb.entity";
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {CelebBanner} from "../../../entities/celeb_banner.entity";

@Module({
    imports: [TypeOrmModule.forFeature([Celeb,PrameUserEntity,CelebBanner])],
    controllers: [CelebController],
    providers: [CelebService, JwtStrategy],
})
export class CelebModule {
}
