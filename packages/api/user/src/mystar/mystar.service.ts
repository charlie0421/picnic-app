import {Injectable, NotFoundException} from '@nestjs/common';
import {InjectRepository} from '@nestjs/typeorm';
import {plainToInstance} from 'class-transformer';
import {IPaginationOptions, paginate} from 'nestjs-typeorm-paginate';
import {Brackets, Repository} from 'typeorm';
import {MystarMemberDto} from './dto/mystar-member.dto';
import {MystarArtistDto, MystarArtistMainDto} from './dto/mystar-artist.dto';
import {MystarGroup} from "../../../entities/mystar-group.entity";
import {MystarMemberEntity} from "../../../entities/mystar-member.entity";

@Injectable()
export class MystarService {
    constructor(
        @InjectRepository(MystarGroup)
        private mystarGroupRepository: Repository<MystarGroup>,
        @InjectRepository(MystarMemberEntity)
        private mystarMemberRepository: Repository<MystarMemberEntity>,
    ) {
    }

    async findAll(options: IPaginationOptions, sort: string, order: 'ASC' | 'DESC') {
        const queryBuilder = this.mystarGroupRepository
            .createQueryBuilder('mystarGroup')
            .orderBy(sort, order);

        return await paginate<MystarGroup>(queryBuilder, options);
    }

    async getGroupsByName(options: IPaginationOptions, name: string, sort: string, order: 'ASC' | 'DESC') {
        const queryBuilder = this.mystarGroupRepository
            .createQueryBuilder('mystarGroup');

        // .where(new Brackets((qb) => {
        //     qb.where('REGEXP_REPLACE(Group.group_name, :regex, \'\') like REGEXP_REPLACE(:name, :regex_like, \'\')')
        //         .andWhere('REGEXP_REPLACE(Group.group_name, :regex_word, \'\') like REGEXP_REPLACE(:name, :regex_word, \'\')')
        //         .orWhere('REGEXP_REPLACE(Group.eng_group_name, :regex, \'\') like REGEXP_REPLACE(:name, :regex_like, \'\')')
        //         .andWhere('REGEXP_REPLACE(Group.eng_group_name, :regex_word, \'\') like REGEXP_REPLACE(:name, :regex_word, \'\')');
        // }))
        // .setParameters({
        //     name: `%${name.trim()}%`,
        //     regex: '[^0-9a-zA-Z가-힣]',
        //     regex_like: '[^0-9a-zA-Z가-힣%]',
        //     regex_word: '[0-9a-zA-Z가-힣]',
        // })
        // .orderBy(sort, order);

        return await paginate<MystarGroup>(queryBuilder, options);
    }

    getGroupMemberList(id: number) {
        const member_info = this.mystarMemberRepository
            .createQueryBuilder('Member')
            .where('Member.deleted_at is null')
            .andWhere(`mystar_group_id = ${id}`)
            .getMany();

        return plainToInstance(MystarMemberDto, member_info);
    }

    async getGroupMemberListV2(id: number) {
        const queryBuilder = this.mystarMemberRepository.createQueryBuilder('member');
        queryBuilder.leftJoinAndSelect('member.group', 'group');

        return paginate(queryBuilder, {limit: 20, page: 1})
    }

    async getArtists(
        options: IPaginationOptions,
        gender: string,
        sort: string,
        order: 'ASC' | 'DESC',
    ) {
        const queryBuilder = this.mystarMemberRepository
            .createQueryBuilder('member')
            .leftJoinAndSelect('member.group', 'mystarGroup')
            .where('member.gender = :gender', {gender})
            .orderBy(sort, order);

        return await paginate<MystarMemberEntity>(queryBuilder, options);
    }

    async getArtistsV2(
        options: IPaginationOptions,
        searchText: string,
        sort: string,
        order: 'ASC' | 'DESC',
    ): Promise<MystarArtistMainDto> {
        const queryBuilder = this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .andWhere('Member.deleted_at is null');
        if (searchText)
            queryBuilder.andWhere(
                new Brackets((qb) => {
                    qb.where('REGEXP_REPLACE(Member.memberName, :regex, \'\') like REGEXP_REPLACE(:searchText, :regex_like, \'\')')
                        .andWhere('REGEXP_REPLACE(Member.memberName, :regex_word, \'\') like REGEXP_REPLACE(:searchText, :regex_word, \'\')')
                        .orWhere('REGEXP_REPLACE(Member.engMemberName, :regex, \'\') like REGEXP_REPLACE(:searchText, :regex_like, \'\')')
                        .andWhere('REGEXP_REPLACE(Member.engMemberName, :regex_word, \'\') like REGEXP_REPLACE(:searchText, :regex_word, \'\')')
                        .orWhere('REGEXP_REPLACE(group.groupName, :regex, \'\') like REGEXP_REPLACE(:searchText, :regex_like, \'\')')
                        .andWhere('REGEXP_REPLACE(group.groupName, :regex_word, \'\') like REGEXP_REPLACE(:searchText, :regex_word, \'\')')
                        .orWhere('REGEXP_REPLACE(group.engGroupName, :regex, \'\') like REGEXP_REPLACE(:searchText, :regex_like, \'\')')
                        .andWhere('REGEXP_REPLACE(group.engGroupName, :regex_word, \'\') like REGEXP_REPLACE(:searchText, :regex_word, \'\')');
                }),
            ).setParameters({
                searchText: `%${searchText.trim()}%`,
                regex: '[^0-9a-zA-Z가-힣]',
                regex_like: '[^0-9a-zA-Z가-힣%]',
                regex_word: '[0-9a-zA-Z가-힣]',
            });
        queryBuilder.orderBy(sort, order);

        const artists = await paginate<MystarMemberEntity>(queryBuilder, options);

        return plainToInstance(MystarArtistMainDto, artists);
    }

    async getArtistsByName(
        options: IPaginationOptions,
        name: string,
        gender: string,
        sort: string,
        order: 'ASC' | 'DESC',
    ): Promise<MystarArtistMainDto> {
        const queryBuilder = this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where('Member.gender = :gender', {gender})
            .andWhere('Member.deleted_at is null')
            .andWhere(
                new Brackets((qb) => {
                    qb.where(`Member.memberName like '%${name}%'`)
                        .orWhere(`Member.engMemberName like '%${name}%'`)
                        .orWhere(`group.groupName like '%${name}%'`)
                        .orWhere(`group.engGroupName like '%${name}%'`);
                }),
            )
            .orderBy(sort, order);

        const artists = await paginate<MystarMemberEntity>(queryBuilder, options);

        return plainToInstance(MystarArtistMainDto, artists);
    }

    async getArtist(artistId: number) {
        const artist = await this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where(`Member.id = ${artistId}`)
            .getOne();

        if (artist === undefined) {
            throw new NotFoundException(`There is no artist where id: ${artistId}`);
        }

        return plainToInstance(MystarArtistDto, artist);
    }

    async getArtistsByNameDeprecated(gender: string, name: string) {
        const mystarMembers = await this.mystarMemberRepository
            .createQueryBuilder('Member')
            .leftJoinAndSelect('Member.group', 'group')
            .where(`Member.gender = '${gender}'`)
            .andWhere('Member.deleted_at is null')
            .andWhere(
                new Brackets((qb) => {
                    qb.where(`Member.memberName like '%${name}%'`)
                        .orWhere(`Member.engMemberName like '%${name}%'`)
                        .orWhere(`group.groupName like '%${name}%'`)
                        .orWhere(`group.engGroupName like '%${name}%'`);
                }),
            )
            .orderBy('Member.id', 'ASC')
            .getMany();

        return plainToInstance(MystarArtistDto, mystarMembers);
    }
}