import {plainToInstance} from 'class-transformer';
import {DataSource, Repository} from 'typeorm';

import {Injectable, Logger, NotFoundException} from '@nestjs/common';
import {JwtService} from '@nestjs/jwt';
import {InjectDataSource, InjectRepository} from '@nestjs/typeorm';

import type {CreateUserDto} from './dto/create-user.dto';
import type {UpdateUserDto} from './dto/update-user.dto';
import {BasicUserDto} from '../../../common/dto/basic-user.dto';
import {getDefinedValues} from '../../../common/util';
import * as bcrypt from 'bcrypt';
import {S3Service} from '../../../common/s3/s3.service';
import {SesService} from '../../../common/ses/ses.service';
import {UpdateNicknameDto} from './dto/update-nickname.dto';
import {TokenType} from "../../../common/enums";
import {ConfigService} from "@nestjs/config";
import {JwtInputPayload} from "../../../common/dto/access-token-body.dto";
import {PutObjectCommandOutput} from '@aws-sdk/client-s3';
import {v4} from 'uuid';
import path from 'path';
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {IPaginationOptions, paginate} from "nestjs-typeorm-paginate";

@Injectable()
export class UsersService {
    private readonly logger = new Logger(UsersService.name);

    constructor(
        private readonly configService: ConfigService,
        private readonly sesService: SesService,
        private readonly s3Service: S3Service,
        @InjectRepository(PrameUserEntity) private usersRepository: Repository<PrameUserEntity>,
        private readonly jwtService: JwtService,
        @InjectDataSource() private readonly dataSource: DataSource) {
    }


    generateEmailVerificationToken(user: PrameUserEntity) {
        const secretKey = this.configService.get('JWT_SECRET');
        const expiresIn = '24h'; // 토큰 유효 기간

        const tokenBody: JwtInputPayload = {
            ...user,
            iss: this.configService.get('ISSUER'),
            type: TokenType.EMAIL_VERIFICATION_TOKEN,
        }

        const token = this.jwtService.sign(
            tokenBody
            , {
                expiresIn: expiresIn,
                secret: secretKey,
            },
        );
        return token;
    }

    async create(createUserDto: CreateUserDto): Promise<PrameUserEntity> {
        const soltRound = 10;
        createUserDto.password = await bcrypt.hash(createUserDto.password, soltRound);

        const user = await this.usersRepository.findOne({where: {email: createUserDto.email}});
        let newUser: PrameUserEntity;
        if (user) {
            newUser = this.usersRepository.merge(user, createUserDto);
            newUser = await this.usersRepository.save(newUser);
        } else {
            newUser = this.usersRepository.create(createUserDto);
            newUser = await this.usersRepository.save(newUser);
        }

        const emailVerificationToken = this.generateEmailVerificationToken(newUser);
        await this.sesService.sendVerificationEmail(
            newUser.email,
            emailVerificationToken,
        );

        return newUser;
    }

    async emailVerification(code: string) {
        const decodedToken = this.jwtService.decode(code);

        const queryBuilder = this.usersRepository.createQueryBuilder('user')
            .leftJoinAndSelect('user.userAgreement', 'userAgreement')
        queryBuilder.where('user.email = :email', {email: decodedToken['email']});

        const user = await queryBuilder.getOne();
        if (!user) {
            throw new NotFoundException(
                `User not found where id: ${decodedToken['id']}`,
            );
        }
        user.emailVerifiedAt = new Date();
        return this.usersRepository.save(user);
    }

    async findAll(paginationOptions: IPaginationOptions) {

        const queryBuilder = this.usersRepository.createQueryBuilder('user')
            .leftJoinAndSelect('user.userProfile', 'userProfile')
        ;
        return paginate(queryBuilder, {limit: paginationOptions.limit, page: paginationOptions.page});
    }

    async findOne(id: number) {
        const queryBuilder = this.usersRepository.createQueryBuilder('user')
            .leftJoinAndSelect('user.userAgreement', 'userAgreement')
            .where('user.id = :id', {id: id})
            .andWhere('user.emailVerifiedAt is not null').withDeleted();
        const user = await queryBuilder.getOne();

        return plainToInstance(PrameUserEntity, user);
    }

    async update(updateUserDto: Partial<UpdateUserDto>): Promise<PrameUserEntity> {
        const user = await this.usersRepository.findOne({where: {id: updateUserDto.id}});
        const definedValues = getDefinedValues(updateUserDto);

        Object.assign(user, definedValues);

        if (definedValues.nickname) {
            user.nickname = definedValues.nickname;
        }

        return this.usersRepository.save(user);
    }

    async remove(id: number): Promise<PrameUserEntity> {
        const user = await this.usersRepository.findOne({where: {id: id}});
        const removedUser = await this.usersRepository.remove(user);
        removedUser.id = id;
        return removedUser;
    }

    async getUserByJwt(jwt: string) {
        const decodedToken = this.jwtService.decode(jwt);

        const user = await this.usersRepository.findOne({
            where: {id: decodedToken['id']},
        });

        if (user === undefined) {
            throw new NotFoundException(
                `User not found where id: ${decodedToken['id']}`,
            );
        }

        return plainToInstance(BasicUserDto, user);
    }

    async checkNickname(nickname: string) {
        console.log(nickname);
        const user = await this.usersRepository.findOne({
            where: {nickname: nickname},
        });
        if (!user) {
            throw new NotFoundException(`User not found where nickname: ${nickname}`);
        }
        return user;
    }

    async changeNickname(id: number, updateNicknameDto: UpdateNicknameDto) {
        const user = await this.usersRepository.findOne({
            where: {id},
        });
        if (!user) {
            throw new NotFoundException(
                `User not found where nickname: ${updateNicknameDto.nickname}`,
            );
        }
        user.nickname = updateNicknameDto.nickname;
        return this.usersRepository.save(user);
    }

    async checkEmail(email: string) {
        console.log(email);
        const queryBuilder = this.usersRepository.createQueryBuilder('user')
            .where('user.email = :email', {email: email})
            .andWhere('user.emailVerifiedAt is not null').withDeleted();
        const user = await queryBuilder.getOne();
        if (!user) {
            throw new NotFoundException(`User not found where email: ${email}`);
        }
        return user;
    }

    async uploadProfileImage(userId: number, image: Express.Multer.File) {
        const filename = v4();

        const uploadedFile: PutObjectCommandOutput = await this.s3Service.uploadFile(`user/${userId}`, filename, image);
        const user = await this.usersRepository.findOne({where: {id: userId}});
        if (!user) {
            throw new NotFoundException(`There is no user where id: ${userId}`);
        }
        user.profileImage = `${filename}${path.extname(image.originalname)}`;
        user.updatedAt = new Date();
        return this.usersRepository.save(user);
    }

    async passwordCheck(userId: number, password: string) {
        const user = await this.usersRepository.findOne({where: {id: userId}});
        if (!user) {
            throw new NotFoundException(`There is no user where id: ${userId}`);
        }
        if (user && (await bcrypt.compare(password, user.password))) {
            return true;
        }
        return false;
    }

    async withdraw(userId: number) {
        const user = await this.usersRepository.findOne({where: {id: userId}});
        if (!user) {
            throw new NotFoundException(`There is no user where id: ${userId}`);
        }
        return this.usersRepository.softDelete({id: userId});
    }
}
