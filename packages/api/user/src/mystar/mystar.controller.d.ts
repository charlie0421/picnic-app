/// <reference types="multer" />
import { MystarArticlesPaginationDto } from './dto/mystar-follower.dto';
import { MystarArtistMainDto } from './dto/mystar-artist.dto';
import { MystarService } from './mystar.service';
import { DeleteMystarPickDto } from './dto/delete-mystar-pick.dto';
import { CreateMystarDto } from './dto/create-mystar.dto';
import { MystarPickDto } from './dto/mystar-pick.dto';
import { MystarPickListDto } from './dto/mystar-pick-list.dto';
import { MessageDto } from '../auth/dto/message.dto';
import { CreateArticleDto } from './dto/create-article.dto';
import { UpdateArticleDto } from './dto/update-article.dto';
import { MystarGroupMainDto } from './dto/mystar-group.dto';
export declare class MystarController {
    private readonly mystarService;
    constructor(mystarService: MystarService);
    findAll(name?: string, page?: number, limit?: number, sort?: string, order?: 'ASC' | 'DESC'): Promise<MystarGroupMainDto>;
    getGroupsByName(name: string): Promise<import("./dto/mystar-group.dto").MystarGroupDto[]>;
    getGroupMemberList(groupId: number): import("./dto/mystar-member.dto").MystarMemberDto;
    getArtists(name?: string, page?: number, limit?: number, gender?: "W", sort?: string, order?: 'ASC' | 'DESC'): Promise<MystarArtistMainDto>;
    getArtistsByName(gender: "W", name: string): Promise<import("./dto/mystar-artist.dto").MystarArtistDto[]>;
    getArtist(artistId: number): Promise<import("./dto/mystar-artist.dto").MystarArtistDto>;
    getAllArticles(artistId: number, page?: number, limit?: number, sort?: string, order?: 'ASC' | 'DESC'): Promise<MystarArticlesPaginationDto>;
    getMyArticles(artistId: number, page: number, limit: number, sort: string, order: 'ASC' | 'DESC', req: any): Promise<MystarArticlesPaginationDto>;
    getFollowerDetail(articleId: number): Promise<import("./dto/mystar-follower.dto").MystarFollowerDetailDto>;
    getFollowerReplyList(articleId: number, page?: number, limit?: number, sort?: string, order?: 'ASC' | 'DESC'): Promise<import("./dto/mystar-follower.dto").MystarFollowerReplyMainDto>;
    createArticleForArtist(artistId: number, image: Express.Multer.File, createArticle: CreateArticleDto, req: any): Promise<MessageDto>;
    updateArticle(articleId: number, image: Express.Multer.File, updateArticle: UpdateArticleDto, req: any): Promise<MessageDto>;
    deleteMyArticle(articleId: number, req: any): Promise<MessageDto>;
    getFollowingArtists(req: any): Promise<MystarPickListDto[]>;
    followArtist(req: any, { artistId }: CreateMystarDto): Promise<MystarPickDto>;
    unfollowArtists(req: any, { mystarPickIds }: DeleteMystarPickDto): Promise<MessageDto>;
}
