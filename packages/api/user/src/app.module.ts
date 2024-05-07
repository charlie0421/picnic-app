import {Module} from '@nestjs/common';
import {ConfigModule, ConfigService} from "@nestjs/config";
import {TypeOrmModule} from '@nestjs/typeorm';
import {utilities as nestWinstonModuleUtilities, WinstonModule,} from 'nest-winston';
import * as winston from 'winston';

import {AppController} from './app.controller';
import {AppService} from './app.service';
import {MulterModule} from '@nestjs/platform-express';
import {CelebModule} from "./celeb/celeb.module";
import {UsersModule} from "./users/users.module";
import {GalleryModule} from "./gallery/gallery.module";
import {CommentModule} from "./comment/comment.module";
import {AlbumModule} from "./album/albumModule";
import {MyStarModule} from "./mystar/mystar.module";
import {VoteModule} from "./vote/vote.module";
@Module({
    imports: [
        ConfigModule.forRoot({
            isGlobal: true,
        }),
        MulterModule.register({
            dest: './uploads',
        }),
        TypeOrmModule.forRootAsync({
            imports: [ConfigModule],
            inject: [ConfigService],
            useFactory: async (configService: ConfigService) => {
                return {
                    type: 'mysql',
                    replication: {
                        master: {
                            host: configService.get<string>('DATABASE_HOST_RW'),
                            port: Number(configService.get<string>('DATABASE_PORT')),
                            username: configService.get<string>('DATABASE_ADMIN_USER'),
                            password: configService.get<string>('DATABASE_ADMIN_PASSWORD'),
                            database: configService.get<string>('DATABASE_DATABASE_NAME')
                        },
                        slaves: [
                            {
                                host: configService.get<string>('DATABASE_HOST_RO'),
                                port: Number(configService.get<string>('DATABASE_PORT')),
                                username: configService.get<string>('DATABASE_ADMIN_USER'),
                                password: configService.get<string>('DATABASE_ADMIN_PASSWORD'),
                                database: configService.get<string>('DATABASE_DATABASE_NAME')
                            },
                        ],
                    },
                    entities: [__dirname + '/**/*.entity{.ts,.js}'],
                    autoLoadEntities: true,
                    synchronize: configService.get<string>('DATABASE_SYNCHRONIZE') === 'true',
                    logging: configService.get<string>('DATABASE_LOGGING') === 'true',
                    extra: {
                        connectionLimit: configService.get<string>('DATABASE_CONNECTION_LIMIT')
                            ?? 10,
                    },
                    supportBigNumbers: configService.get<string>('DATABASE_SUPPORT_BIG_NUMBERS') === 'true',
                    bigNumberStrings: configService.get<string>('DATABASE_BIG_NUMBER_STRINGS') === 'true',
                    timezone: 'Z',
                };
            },
        }),
        WinstonModule.forRoot({
            transports: [
                new winston.transports.Console({
                    level: process.env.NODE_ENV === 'production' ? 'info' : 'silly',
                    format: winston.format.combine(
                        winston.format.colorize(),
                        winston.format.timestamp(),
                        nestWinstonModuleUtilities.format.nestLike('MyApp', {
                            prettyPrint: true,
                        }),
                    ),
                }),
            ],
        }),
        CelebModule,
        UsersModule,
        GalleryModule,
        CommentModule,
        AlbumModule,
        MyStarModule,
        VoteModule
    ],
    controllers: [AppController],
    providers: [AppService],
})
export class AppModule {
}
