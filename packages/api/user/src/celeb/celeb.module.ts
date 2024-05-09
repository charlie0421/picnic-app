import {Module} from '@nestjs/common';
import {CelebService} from './celeb.service';
import {CelebController} from './celeb.controller';
import {TypeOrmModule} from '@nestjs/typeorm';
import {CelebEntity} from "../../../entities/celeb.entity";
import {UserEntity} from "../../../entities/user.entity";
import {CelebBannerEntity} from "../../../entities/celeb_banner.entity";
import { JwtService } from '@nestjs/jwt';

@Module({
    imports: [TypeOrmModule.forFeature([CelebEntity,UserEntity,CelebBannerEntity])],
    controllers: [CelebController],
    providers: [CelebService, JwtService],
})
export class CelebModule {
}
