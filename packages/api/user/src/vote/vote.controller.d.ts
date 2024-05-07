import { CreateVoteReplyDto } from './dto/create-vote-reply.dto';
import { VoteService } from './vote.service';
import { VoteDetailListMainDto } from './dto/vote-detail.dto';
import { VoteMainDto } from './dto/vote-list.dto';
import { DoSstVoteDto } from './dto/do-sst-vote.dto';
import { VotePickForSstVoteResponseDto } from './dto/vote-pick-for-sst-vote-response.dto';
import { VoteReplyMainDto } from './dto/vote-reply.dto';
import { VotePickForRightVoteResponseDto } from './dto/vote-pick-for-right-vote-response.dto';
import { DoRightVoteDto } from './dto/do-right-vote.dto';
import { MessageDto } from '../auth/dto/message.dto';
export declare class VoteController {
    private readonly voteService;
    constructor(voteService: VoteService);
    findAll(page?: number, limit?: number, category?: string, active?: boolean, artist?: boolean, mainTop?: boolean, sort?: string, order?: 'ASC' | 'DESC'): Promise<VoteMainDto>;
    getMainPageVotes(): Promise<import("./dto/vote-list.dto").VoteDto[]>;
    getVoteDetail(id: number): import("./dto/vote-detail.dto").VoteDetailtDto;
    getVoteDetailList(id: number, page?: number, limit?: number, sort?: string, order?: 'ASC' | 'DESC'): Promise<VoteDetailListMainDto>;
    getVoteReplyList(id: number, page?: number, limit?: number, sort?: string, order?: 'ASC' | 'DESC'): Promise<VoteReplyMainDto>;
    postVoteReply(voteId: number, body: CreateVoteReplyDto, req: any): Promise<{
        statusCode: number;
        message: string;
    }>;
    voteUsingSst(voteId: number, { sst, voteItemId }: DoSstVoteDto, req: any): Promise<VotePickForSstVoteResponseDto>;
    voteUsingRight(voteId: number, { right, voteItemId, voteType }: DoRightVoteDto, req: any): Promise<VotePickForRightVoteResponseDto>;
    reportVoteComment(commentId: number, req: any): Promise<MessageDto>;
}
