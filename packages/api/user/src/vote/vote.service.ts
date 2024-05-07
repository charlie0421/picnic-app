import {Injectable, Logger, NotFoundException} from "@nestjs/common";
import {InjectRepository} from "@nestjs/typeorm";
import {IPaginationOptions, paginate} from "nestjs-typeorm-paginate";
import {Brackets, DataSource, Repository} from "typeorm";
import {VoteDetailListMainDto, VoteDetailtDto} from "./dto/vote-detail.dto";
import {VotePickForSstVoteResponseDto} from "./dto/vote-pick-for-sst-vote-response.dto";
import {plainToInstance} from "class-transformer";
import {RankMainDto} from "./dto/rank.dto";
import {VoteEntity} from "../../../entities/vote.entity";
import {VoteItemEntity} from "../../../entities/vote_item.entity";
import {VoteCommentEntity} from "../../../entities/vote_comment.entity";
import {PointHistoryEntity, PointHistoryType} from "../../../entities/point_history.entity";
import {PrameUserEntity} from "../../../entities/prame-user.entity";
import {VoteItemPickEntity} from "../../../entities/vote_item_pick.entity";

@Injectable()
export class VoteService {
    private readonly logger = new Logger(VoteService.name);

    constructor(
        @InjectRepository(VoteEntity)
        private voteRepository: Repository<VoteEntity>,
        @InjectRepository(VoteItemEntity)
        private voteItemRepository: Repository<VoteItemEntity>,
        @InjectRepository(VoteCommentEntity)
        private voteCommentRepository: Repository<VoteCommentEntity>,
        @InjectRepository(PrameUserEntity)
        private userRepository: Repository<PrameUserEntity>,
        @InjectRepository(VoteItemPickEntity)
        private votePickRepository: Repository<VoteItemPickEntity>,
        private connection: DataSource,
    ) {
    }

    async findAll(
        options: IPaginationOptions,
        category: string,
        activeOnly: boolean,
        includeArtists: boolean,
        sort: string,
        order: 'ASC' | 'DESC',
    ) {
        // const current = moment().format();
        const current = Date.now();

        const queryBuilder = this.voteRepository
            .createQueryBuilder('vote')
            .leftJoinAndSelect('vote.voteItems', 'voteItems').andWhere('voteItems.deleted_at is null')
            .leftJoinAndSelect('voteItems.myStarMember', 'myStarMember')
            .andWhere(`vote.vote_category = '${category}'`);

        return paginate(queryBuilder, options);
    }

    /*
        async getMainPageVotes() {
            const current = Date.now();

            const voteQuery = `select *
                               from ((select 1 as status, a.*
                                      from (select *
                                            from vote
                                            where visible_at = start_at
                                              and visible_at <= '${current}'
                                              and stop_at >= '${current}'
                                              and deleted_at is null
                                            order by start_at desc) a)
                                     UNION ALL
                                     (select 2 as status, b.*
                                      from (select *
                                            from vote
                                            where visible_at <> start_at
                                              and visible_at <= '${current}'
                                              and stop_at >= '${current}'
                                              and deleted_at is null) b)) c
                               order by c.main_top desc, c.status, c.start_at desc;`;
            const votes: VoteEntity[] = await this.connection.query(voteQuery);

            const voteIds = votes.map((it) => it.id).join(',');

            const replyCountQuery = `
                select vote_id, count(*) as cnt
                from vote_reply
                where vote_id in (${voteIds})
                  and deleted_at is null
                group by vote_id;
            `;
            const voteCommentCounts: VoteCommentCount[] = await this.connection.query(replyCountQuery);

            const voteItemQuery = `
                select *
                from vote_item
                where vote_id in (${voteIds})
                  and deleted_at is null
                order by id;
            `;
            const voteItems: VoteItemEntity[] = await this.connection.query(voteItemQuery);

            return this.toVoteMainDto(votes, voteCommentCounts, voteItems);
        }
    */
    async getVoteDetail(id: number) {
        const vote_info = await this.voteRepository
            .createQueryBuilder('vote')
            .loadRelationCountAndMap('vote.replycount', 'vote.replies')
            .where('vote.deleted_at is null')
            .andWhere(`vote.id = ${id}`)
            .getOne();

        return plainToInstance(VoteDetailtDto, vote_info);
    }

    async getVoteDetailList(
        id: number,
        options: IPaginationOptions,
        sort: string,
        order: 'ASC' | 'DESC',
        searchText: string,
    ): Promise<VoteDetailListMainDto> {
        const queryBuilder = this.voteItemRepository
            .createQueryBuilder('vote_item')
            .where('vote_item.deleted_at is null')
            .andWhere(`vote_item.vote_id = ${id}`);

        searchText &&
        queryBuilder.andWhere(
            new Brackets((qb) => {
                qb.where('vote_item.item_name like :item_name', {item_name: `%${searchText}%`})
                    .orWhere('vote_item.eng_item_name like :eng_item_name', {eng_item_name: `%${searchText}%`})
                    .orWhere('vote_item.item_text like :item_text', {item_text: `%${searchText}%`})
                    .orWhere('vote_item.eng_item_text like :eng_item_text', {eng_item_text: `%${searchText}%`});
            }),
        );
        queryBuilder.orderBy(sort, order);

        const voteItem = await paginate<VoteItemEntity>(queryBuilder, options);
        const total_vote = await this.getVoteTotal(id);

        return plainToInstance(VoteDetailListMainDto, {...voteItem, total_vote});
    }

    async getVoteRankDetailList(
        id: number,
        options: IPaginationOptions,
        sort: string,
        order: 'ASC' | 'DESC',
        searchText: string,
    ): Promise<VoteDetailListMainDto> {

        const queryBuilder = this.voteItemRepository
            .createQueryBuilder('vote_item')
            .leftJoinAndSelect('vote_item.mystarMember', 'mystarMember')
            .where('vote_item.deleted_at is null')
            .andWhere(`vote_item.vote_id = ${id}`)
            .select(['vote_item', 'mystarMember'])


        searchText &&
        queryBuilder.andWhere(
            new Brackets((qb) => {
                qb.where('vote_item.item_name like :item_name', {item_name: `%${searchText}%`})
                    .orWhere('vote_item.eng_item_name like :eng_item_name', {eng_item_name: `%${searchText}%`})
                    .orWhere('vote_item.item_text like :item_text', {item_text: `%${searchText}%`})
                    .orWhere('vote_item.eng_item_text like :eng_item_text', {eng_item_text: `%${searchText}%`});
            }),
        );
        queryBuilder.orderBy(sort, order);

        const voteItem = await paginate<VoteItemEntity>(queryBuilder, options);
        const total_vote = await this.getVoteTotal(id);

        // voteItem['items'].forEach((value, index) => {
        //     voteItem['items'][index].item_img = voteItem['items'][index]?.mystarMember?.image;
        // })

        return plainToInstance(VoteDetailListMainDto, {...voteItem, total_vote});

    }

    /*
        async getVoteChartDetailList(
            id: number,
            options: IPaginationOptions,
            sort: string,
            order: 'ASC' | 'DESC',
            searchText: string,
        ): Promise<VoteDetailListMainDto> {
            const current = Date.now();

            const lastTwoChartId = await this.voteRepository
                .createQueryBuilder('vote')
                .select('vote.id')
                .where(`vote.vote_category='kplay'`)
                .andWhere(`vote.start_at <= '${current}'`)
                .andWhere(`vote.id <= ${id}`)
                .orderBy('vote.id', 'DESC')
                .limit(2)
                .getMany();

            const ids = lastTwoChartId.map((e) => e.id);
            const queryBuilder = this.voteItemRepository
                .createQueryBuilder('vote_item')
                .where('vote_item.deleted_at is null')
                .andWhere(`vote_item.vote_id = (${ids[0]})`);

            searchText &&
            queryBuilder.andWhere(
                new Brackets((qb) => {
                    qb.where('vote_item.item_name like :item_name', {item_name: `%${searchText}%`})
                        .orWhere('vote_item.eng_item_name like :eng_item_name', {eng_item_name: `%${searchText}%`})
                        .orWhere('vote_item.item_text like :item_text', {item_text: `%${searchText}%`})
                        .orWhere('vote_item.eng_item_text like :eng_item_text', {eng_item_text: `%${searchText}%`});
                }),
            );
            queryBuilder.orderBy(sort, order);

            // const thisWeekInfo = queryBuilder.getMany();
            const total_vote = await this.getVoteTotal(ids[0]);

            if (ids.length === 1) {
                const thisWeekInfo = await paginate<VoteItemEntity>(queryBuilder, options);
                const instance = plainToInstance(VoteDetailListMainDto, {...thisWeekInfo, total_vote});

                thisWeekInfo['items'].forEach((value, index) => {
                    instance.items[index].week_of_week = -9999;
                });
                return instance;
            }

            //////////////////
            // last week
            //////////////////
            const lastWeekInfo = await this.voteItemRepository
                .createQueryBuilder('vote_item')
                .where('vote_item.deleted_at is null')
                .andWhere(`vote_id=${ids[1]}`)
                .orderBy('vote_item.vote_total', 'DESC')
                .getMany();

            const thisWeekInfo = await paginate<VoteItemEntity>(queryBuilder, options);
            const instance = plainToInstance(VoteDetailListMainDto, {...thisWeekInfo, total_vote});

            thisWeekInfo['items'].forEach((value, index) => {
                const thisRanking = index + 1;
                const lastRanking = lastWeekInfo.findIndex((item) => item.item_name === value.item_name) + 1;
                lastRanking > 0
                    ? (instance.items[index].week_of_week = thisRanking - lastRanking)
                    : (instance.items[index].week_of_week = -9999);
            });

            // return plainToInstance(VoteDetailListMainDto, {...voteItem,total_vote});
            return instance;
        }


     */
    async getRankMain() {
        const current = Date();
        const rankInfo = await this.voteRepository
            .createQueryBuilder('vote')
            .where(`vote.vote_category='ranking'`)
            .andWhere(`vote.start_at <= '${current}'`)
            .andWhere(`vote.stop_at >= '${current}'`)
            .orderBy('vote.id', 'DESC')
            .limit(1)
            .getOne();

        return plainToInstance(RankMainDto, {info: {...rankInfo}});
    }

    /*
        async getChartMain() {
            // const current = moment().format();
            const current = Date();

            const lastTwoChartId = await this.voteRepository
                .createQueryBuilder('vote')
                .where(`vote.vote_category='kplay'`)
                .andWhere(`vote.start_at <= '${current}'`)
                .orderBy('vote.id', 'DESC')
                .limit(2)
                .getMany();

            const ids = lastTwoChartId.map((e) => e.id);

            //////////////////
            // this week
            //////////////////
            const thisWeekInfo = await this.voteItemRepository
                .createQueryBuilder('vote_item')
                .where('vote_item.deleted_at is null')
                .andWhere(`vote_item.vote_id=${ids[0]}`)
                .orderBy('vote_item.vote_total', 'DESC')
                .limit(3)
                .getMany();

            if (ids.length === 1) {
                const instance = plainToInstance(ChartMainDto, {info: {...lastTwoChartId[0]}, items: thisWeekInfo});
                thisWeekInfo.forEach((value, index) => {
                    instance.items[index].week_of_week = -9999;
                });
                return instance;
            }

            //////////////////
            // last week
            //////////////////
            const lastWeekInfo = await this.voteItemRepository
                .createQueryBuilder('vote_item')
                .where('vote_item.deleted_at is null')
                .andWhere(`vote_id=${ids[1]}`)
                .orderBy('vote_item.vote_total', 'DESC')
                .getMany();

            const instance = plainToInstance(ChartMainDto, {info: {...lastTwoChartId[0]}, items: thisWeekInfo});

            thisWeekInfo.forEach((value, index) => {
                const thisRanking = index + 1;
                const lastRanking = lastWeekInfo.findIndex((item) => item.item_name === value.item_name) + 1;
                lastRanking > 0
                    ? (instance.items[index].week_of_week = thisRanking - lastRanking)
                    : (instance.items[index].week_of_week = -9999);
            });

            return instance;
        }
    */
    async getVoteTotal(id: number) {
        const total_vote = await this.voteItemRepository
            .createQueryBuilder('vote_item')
            .select('SUM(vote_item.vote_total)', 'vote_total')
            .where('vote_item.deleted_at is null')
            .andWhere(`vote_item.vote_id = ${id}`)
            .getRawOne();

        return total_vote;
    }

    async isNotStart(voteId: number) {
        const vote = await this.voteRepository.findOne({where: {id: voteId}});

        return vote.startAt > new Date();
    }

    async isVoteOver(voteId: number) {
        const vote = await this.voteRepository.findOne({where: {id: voteId}});

        return vote.stopAt <= new Date();
    }

    async isThereVote(voteId: number) {
        const vote = await this.voteRepository.findOne({where: {id: voteId}});

        return vote !== undefined;
    }

    async isThereVoteItem(voteId: number, voteItemId: number) {
        const voteItem = await this.voteItemRepository.findOne({
            where: {id: voteItemId, voteId: voteId},
        });

        return voteItem !== undefined;
    }

    async isUserSstLessThan(userId: number, point: number) {
        const user = await this.userRepository.findOne({where: {id: userId}});
        if (user === undefined) {
            throw new NotFoundException(`There is no user where id: ${userId}`);
        }

        return user.point < point;
    }

    async voteUsingSst(userId: number, voteId: number, voteItemId: number, point: number) {
        const queryRunner = this.connection.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        const em = queryRunner.manager;

        try {
            // 유저 포인트 차감
            const user = await this.userRepository.findOne({
                where: {id: userId},
            });
            if (user === undefined) {
                throw new NotFoundException(`There is no user where id: ${userId}`);
            }
            user.point -= Math.abs(point);
            user.updatedAt = new Date();

            await em.save(user);

            // 투표이력 추가
            const votePick = VoteItemPickEntity.pointVotePick(userId, voteId, voteItemId, Math.abs(point));
            await em.save(votePick);

            // SST 히스토리 추가
            const pointHistory = new PointHistoryEntity();
            pointHistory.usersId = userId;
            pointHistory.amount = Math.abs(point);
            pointHistory.type = PointHistoryType.VOTE;
            pointHistory.votePickId = votePick.id;
            pointHistory.createdAt = new Date();
            pointHistory.updatedAt = new Date();

            await em.save(pointHistory);

            // vote item 업데이트
            const voteItem = await this.voteItemRepository.findOne({
                where: {id: voteItemId, voteId: voteId},
            });
            if (!voteItem) {
                throw new NotFoundException(`There is no vote item where id: ${voteItemId}`);
            }
            voteItem.voteTotal += Math.abs(point);
            voteItem.updatedAt = new Date();
            await em.save(voteItem);

            await queryRunner.commitTransaction();

            return plainToInstance(VotePickForSstVoteResponseDto, votePick);
        } catch (err) {
            await queryRunner.rollbackTransaction();
            throw err;
        } finally {
            await queryRunner.release();
        }
    }

    /*
        private toVoteMainDto(votes: VoteEntity[], voteCommentCounts: VoteCommentCount[], voteItems: VoteItemEntity[]): VoteDto[] {
            return votes.map((it) => {
                const vote = new VoteDto();
                vote.id = it.id;
                vote.vote_title = it.vote_title;
                vote.vote_category = it.vote_category;
                vote.main_img = it.main_img;
                vote.vote_content = it.vote_content;
                vote.start_at = it.start_at;
                vote.stop_at = it.stop_at;
                vote.visible_at = it.visible_at;
                vote.replycount = voteCommentCounts.find((voteCommentCount) => voteCommentCount.vote_id === it.id)?.cnt || 0;
                vote.items = voteItems
                    .filter((voteItem) => voteItem.vote_id === it.id)
                    .map((value) => {
                        const voteItem = new VoteItemDto();
                        voteItem.id = value.id;
                        voteItem.item_img = this.toFullImagePath(value);

                        return voteItem;
                    });

                return vote;
            });
        }
    */
    private toFullImagePath(value: VoteItemEntity) {
        // if (value.item_img === null) {
        //     return `${process.env.CDN_PATH_IMAGE}/profile_base2.png`;
        // } else {
        //     return `${process.env.CDN_PATH_VOTE_ITEM}/${value.id}/${value.item_img}`;
        // }
    }
}

class VoteCommentCount {
    vote_id: number;
    cnt: number;
}
