import {Module} from '@nestjs/common';
import {CelebService} from './celeb.service';
import {CelebController} from './celeb.controller';
import {TypeOrmModule} from '@nestjs/typeorm';
import {CelebEntity} from "../../../entities/celeb.entity";
import {UserEntity} from "../../../entities/user.entity";
import {BannerEntity} from "../../../entities/banner.entity";
import { JwtService } from '@nestjs/jwt';

@Module({
    imports: [TypeOrmModule.forFeature([CelebEntity,UserEntity,BannerEntity])],
    controllers: [CelebController],
    providers: [CelebService, JwtService],
})
export class CelebModule {
}
