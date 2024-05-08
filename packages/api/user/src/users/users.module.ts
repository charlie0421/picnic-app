import {Module} from '@nestjs/common';
import {JwtService} from '@nestjs/jwt';
import {TypeOrmModule} from '@nestjs/typeorm';

import {UsersController} from './users.controller';
import {UsersService} from './users.service';
import {SesModule} from '../../../common/ses/ses.module';
import {S3Module} from "../../../common/s3/s3.module";
import {UserEntity} from "../../../entities/user.entity";
import {GalleryEntity} from "../../../entities/gallery.entity";

@Module({
    imports: [
        TypeOrmModule.forFeature([UserEntity, GalleryEntity]),
        SesModule,
        S3Module,
    ],
    providers: [UsersService, JwtService],
    controllers: [UsersController],
})
export class UsersModule {
}
