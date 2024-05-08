import {Module} from '@nestjs/common';
import {CelebService} from './celeb.service';
import {CelebController} from './celeb.controller';
import {TypeOrmModule} from '@nestjs/typeorm';
import {Celeb} from "../../../entities/celeb.entity";
import {UserEntity} from "../../../entities/user.entity";
import {CelebBanner} from "../../../entities/celeb_banner.entity";
import { JwtService } from '@nestjs/jwt';

@Module({
    imports: [TypeOrmModule.forFeature([Celeb,UserEntity,CelebBanner])],
    controllers: [CelebController],
    providers: [CelebService, JwtService],
})
export class CelebModule {
}
