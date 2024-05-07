import {Module} from '@nestjs/common';
import {JwtService} from '@nestjs/jwt';
import {TypeOrmModule} from '@nestjs/typeorm';

import {UsersController} from './users.controller';
import {UsersService} from './users.service';
import {SesModule} from '../../../common/ses/ses.module';
import {S3Module} from "../../../common/s3/s3.module";
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {GalleryEntity} from "../../../entities/gallery.entity";

@Module({
    imports: [
        TypeOrmModule.forFeature([PrameUserEntity, GalleryEntity]),
        SesModule,
        S3Module,
    ],
    providers: [UsersService, JwtService],
    controllers: [UsersController],
})
export class UsersModule {
}
