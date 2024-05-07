import {
    BadRequestException,
    Body,
    Controller,
    DefaultValuePipe,
    Get,
    Header,
    Logger,
    NotFoundException,
    Param,
    ParseBoolPipe,
    ParseIntPipe,
    Post,
    Query,
    Request,
    UseGuards,
    Version
} from "@nestjs/common";
import {ApiBearerAuth, ApiCreatedResponse, ApiOperation, ApiParam, ApiQuery, ApiTags} from "@nestjs/swagger";
import {ORDER} from "../constants";
import {VoteService} from "./vote.service";
import {VoteDetailListMainDto} from "./dto/vote-detail.dto";
import {BasicUserDto} from "../users/dto/basic-user.dto";
import {DoSstVoteDto} from "./dto/do-sst-vote.dto";
import {VotePickForSstVoteResponseDto} from "./dto/vote-pick-for-sst-vote-response.dto";
import {RankMainDto} from "./dto/rank.dto";
import { JwtAuthGuard } from '../../../common/auth/jwt-auth.guard';

@Controller('/user/vote')
@ApiTags('Vote API')
export class VoteController {
    private readonly logger = new Logger(VoteController.name);

    constructor(private readonly voteService: VoteService) {
    }

    @Get()
    @Header('Cache-Control', 'max-age=60')
    @ApiOperation({summary: '투표 목록 API', description: '투표 리스트(pagination 가능)'})
    @ApiQuery({name: 'page', required: false, schema: {type: 'number', default: 1}})
    @ApiQuery({name: 'limit', required: false, schema: {type: 'number', default: 10000}})
    @ApiQuery({name: 'category', required: false, schema: {type: 'string', default: 'birthday'}})
    @ApiQuery({name: 'active', required: false, schema: {type: 'boolean', default: true}})
    @ApiQuery({name: 'artist', required: false, schema: {type: 'boolean', default: true}})
    @ApiQuery({name: 'sort', required: false, schema: {type: 'string', default: 'vote.start_at'}})
    @ApiQuery({name: 'order', required: false, enum: ORDER, schema: {type: 'string', default: ORDER.desc}})
    async findAll(
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query('limit', new DefaultValuePipe(10000), ParseIntPipe) limit: number = 10000,
        @Query('category', new DefaultValuePipe('birthday')) category = 'birthday',
        @Query('active', new DefaultValuePipe(true), ParseBoolPipe) active = true,
        @Query('artist', new DefaultValuePipe(false), ParseBoolPipe) artist = false,
        @Query('sort', new DefaultValuePipe('vote.start_at')) sort = 'vote.start_at',
        @Query('order', new DefaultValuePipe(ORDER.desc)) order: 'ASC' | 'DESC' = 'DESC',
    ) {
        return this.voteService.findAll({page, limit}, category, active, artist, sort, order);
    }

    @Get('/main')
    @Header('Cache-Control', 'max-age=60')
    @ApiOperation({summary: '메인 페이지에 있는 투표 목록 API'})
    async getMainPageVotes() {
        // return this.voteService.getMainPageVotes();

    }

    @Get('/:id')
    @Header('Cache-Control', 'no-cache')
    @ApiOperation({summary: '투표 정보 API', description: '투표상세 정보를 얻는다.'})
    @ApiParam({name: 'id', schema: {type: 'number'}, description: '투표 id'})
    getVoteDetail(@Param('id', ParseIntPipe) id: number) {
        return this.voteService.getVoteDetail(id);
    }

    @Get('/detail/list/:id')
    @Header('Cache-Control', 'no-cache')
    @ApiOperation({summary: '투표 현황 API', description: '투표상세 화면에서 투표 현황을 얻는다. (pagination 가능)'})
    @ApiParam({name: 'id', schema: {type: 'number'}, description: '투표 id'})
    @ApiQuery({name: 'page', required: false, schema: {type: 'number', default: 1}})
    @ApiQuery({name: 'limit', required: false, schema: {type: 'number', default: 100}})
    @ApiQuery({name: 'sort', required: false, schema: {type: 'string', default: 'vote_total'}})
    @ApiQuery({name: 'order', required: false, enum: ORDER, schema: {type: 'string', default: ORDER.desc}})
    @ApiQuery({name: 'searchText', required: false, schema: {type: 'string', default: ''}})
    getVoteDetailList(
        @Param('id', ParseIntPipe) id: number,
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query('limit', new DefaultValuePipe(100), ParseIntPipe) limit: number = 100,
        @Query('sort', new DefaultValuePipe('vote_total')) sort = 'vote_total',
        @Query('order', new DefaultValuePipe(ORDER.desc)) order: 'ASC' | 'DESC' = 'DESC',
        @Query('searchText', new DefaultValuePipe('')) searchText = '',
    ): Promise<VoteDetailListMainDto> {
        return this.voteService.getVoteDetailList(id, {page, limit}, sort, order, searchText);
    }

    @Version('2')
    @Get('/detail/list/:id')
    @Header('Cache-Control', 'no-cache')
    @ApiOperation({summary: '투표 현황 API', description: '투표상세 화면에서 투표 현황을 얻는다. (pagination 가능)'})
    @ApiParam({name: 'id', schema: {type: 'number'}, description: '투표 id'})
    @ApiQuery({name: 'chart', required: false, schema: {type: 'boolean', default: false}})
    @ApiQuery({name: 'page', required: false, schema: {type: 'number', default: 1}})
    @ApiQuery({name: 'limit', required: false, schema: {type: 'number', default: 100}})
    @ApiQuery({name: 'sort', required: false, schema: {type: 'string', default: 'vote_total'}})
    @ApiQuery({name: 'order', required: false, enum: ORDER, schema: {type: 'string', default: ORDER.desc}})
    @ApiQuery({name: 'searchText', required: false, schema: {type: 'string', default: ''}})
    getVoteDetailListV2(
        @Param('id', ParseIntPipe) id: number,
        @Query('chart', new DefaultValuePipe(false), ParseBoolPipe) chart = false,
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query('limit', new DefaultValuePipe(100), ParseIntPipe) limit: number = 100,
        @Query('sort', new DefaultValuePipe('vote_total')) sort = 'vote_total',
        @Query('order', new DefaultValuePipe(ORDER.desc)) order: 'ASC' | 'DESC' = 'DESC',
        @Query('searchText', new DefaultValuePipe('')) searchText = '',
    ): Promise<VoteDetailListMainDto> {

        return this.voteService.getVoteDetailList(id, {
            page,
            limit
        }, sort, order, searchText);
        // return chart
        //     ? this.voteService.getVoteChartDetailList(id, {page, limit}, sort, order, searchText)
        //     : id === 681 ? this.voteService.getVoteRankDetailList(id, {
        //         page,
        //         limit
        //     }, sort, order, searchText) : this.voteService.getVoteDetailList(id, {
        //         page,
        //         limit
        //     }, sort, order, searchText);
    }

    @Version('3')
    @Get('/detail/list/:id')
    @Header('Cache-Control', 'no-cache')
    @ApiOperation({summary: '투표 현황 API', description: '투표상세 화면에서 투표 현황을 얻는다. (pagination 가능)'})
    @ApiParam({name: 'id', schema: {type: 'number'}, description: '투표 id'})
    @ApiQuery({name: 'type', required: false, schema: {type: 'string', default: 'play'}})
    @ApiQuery({name: 'page', required: false, schema: {type: 'number', default: 1}})
    @ApiQuery({name: 'limit', required: false, schema: {type: 'number', default: 100}})
    @ApiQuery({name: 'sort', required: false, schema: {type: 'string', default: 'vote_total'}})
    @ApiQuery({name: 'order', required: false, enum: ORDER, schema: {type: 'string', default: ORDER.desc}})
    @ApiQuery({name: 'searchText', required: false, schema: {type: 'string', default: ''}})
    getVoteDetailListV3(
        @Param('id', ParseIntPipe) id: number,
        @Query('type', new DefaultValuePipe('play'),) type = 'play',
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query('limit', new DefaultValuePipe(100), ParseIntPipe) limit: number = 100,
        @Query('sort', new DefaultValuePipe('vote_total')) sort = 'vote_total',
        @Query('order', new DefaultValuePipe(ORDER.desc)) order: 'ASC' | 'DESC' = 'DESC',
        @Query('searchText', new DefaultValuePipe('')) searchText = '',
    ): Promise<VoteDetailListMainDto> {
        return this.voteService.getVoteDetailList(id, {page, limit}, sort, order, searchText);
        // if (type === 'chart') {
        //     return this.voteService.getVoteChartDetailList(id, {page, limit}, sort, order, searchText)
        // } else if (type === 'play') {
        //     return this.voteService.getVoteDetailList(id, {page, limit}, sort, order, searchText);
        // } else if (type === 'ranking')
        //     return this.voteService.getVoteRankDetailList(id, {page, limit}, sort, order, searchText)
    }

    /*
        @Version('2')
        @Header('Cache-Control', 'no-cache')
        @Get('/chart/home')
        @ApiOperation({
            summary: '최근 CHART 순위 ',
            description: '최근 K-PLAY CHART 의 1-3 순위를 가져오고 직전 차트의 순위 증감도 가져온다.',
        })
        getLastChart(): Promise<ChartMainDto> {
            return this.voteService.getChartMain();
        }
    */
    @Header('Cache-Control', 'no-cache')
    @Get('/rank/home')
    @ApiOperation({summary: '최근 랭킹투표 정보', description: '최근 랭킹투표 정보'})
    getLastRank(): Promise<RankMainDto> {
        return this.voteService.getRankMain();
    }

    @Get('/detail/list/:id/vote_total')
    @Header('Cache-Control', 'no-cache')
    @ApiOperation({summary: '투표수 API', description: '해당 투표의 총 투표수'})
    @ApiParam({name: 'id', schema: {type: 'number'}, description: '투표 id'})
    getVoteTotalVote(@Param('id', ParseIntPipe) id: number): Promise<VoteDetailListMainDto> {
        return this.voteService.getVoteTotal(id);
    }


    @ApiCreatedResponse({type: VotePickForSstVoteResponseDto})
    @ApiBearerAuth('access-token')
    @ApiOperation({summary: 'SST으로 투표하기 API'})
    @UseGuards(JwtAuthGuard)
    @Post('/:voteId/by/sst')
    async voteUsingSst(
        @Param('voteId', ParseIntPipe) voteId: number,
        @Body() {sst, voteItemId}: DoSstVoteDto,
        @Request() req,
    ) {
        const {id: userId}: BasicUserDto = req.user;

        if (await this.voteService.isNotStart(voteId)) {
            throw new BadRequestException('The vote is not started');
        }
        if (await this.voteService.isVoteOver(voteId)) {
            throw new BadRequestException('The vote is over');
        }
        if (!(await this.voteService.isThereVote(voteId))) {
            throw new NotFoundException(`There is no vote where id: ${voteId}`);
        }
        if (!(await this.voteService.isThereVoteItem(voteId, voteItemId))) {
            throw new NotFoundException(`There is no vote item(${voteItemId}) in vote(${voteId})`);
        }
        if (await this.voteService.isUserSstLessThan(userId, Math.abs(sst))) {
            throw new BadRequestException(`User silver star token is less than ${sst}`);
        }

        return await this.voteService.voteUsingSst(userId, voteId, voteItemId, sst);
    }

}
