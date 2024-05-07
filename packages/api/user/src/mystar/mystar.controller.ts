import {Controller, DefaultValuePipe, Get, Header, Param, ParseIntPipe, Query, Version} from "@nestjs/common";
import {ApiOperation, ApiParam, ApiQuery, ApiTags} from "@nestjs/swagger";
import {GENDER, ORDER} from "../constants";
import {MystarArtistMainDto} from "./dto/mystar-artist.dto";
import {MystarService} from "./mystar.service";

@Controller("/user/mystar")
@ApiTags("Mystar API")
export class MystarController {
    constructor(private readonly mystarService: MystarService) {
    }

    @Get("/group")
    @Header("Cache-Control", "max-age=60")
    @ApiOperation({summary: "마이스타 그룹 목록 API", description: "마이스타 그룹 리스트(pagination 가능)"})
    // @ApiQuery({name: "name", required: false})
    @ApiQuery({name: "page", required: false, schema: {type: "number", default: 1}})
    @ApiQuery({name: "limit", required: false, schema: {type: "number", default: 20}})
    @ApiQuery({name: "sort", required: false, schema: {type: "string", default: "name_ko"}})
    @ApiQuery({name: "order", required: false, enum: ORDER, schema: {type: "string", default: ORDER.asc}})
    findAll(
        // @Query("name") name?: string,
        @Query("page", new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query("limit", new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
        @Query("sort", new DefaultValuePipe("name_ko")) sort = "name_ko",
        @Query("order", new DefaultValuePipe(ORDER.asc)) order: "ASC" | "DESC" = "DESC"
    ) {
        // if (name) {
        //     return this.mystarService.getGroupsByName({page, limit}, name, sort, order);
        // }
        return this.mystarService.findAll({page, limit}, sort, order);
    }

    @Get("/group/:groupId")
    @Header("Cache-Control", "max-age=60")
    @ApiOperation({summary: "마이스타 그룹 멤버 API", description: "마이스타 그룹 멤버 리스트"})
    @ApiParam({name: "groupId", schema: {type: "number"}, description: "그룹 id"})
    getGroupMemberList(@Param("groupId", ParseIntPipe) groupId: number) {
        return this.mystarService.getGroupMemberList(groupId);
    }

    @Version("2")
    @Get("/group/:groupId")
    @Header("Cache-Control", "max-age=60")
    @ApiOperation({summary: "마이스타 그룹 멤버 API", description: "마이스타 그룹 멤버 리스트"})
    @ApiParam({name: "groupId", schema: {type: "number"}, description: "그룹 id"})
    getGroupMemberListV2(@Param("groupId", ParseIntPipe) groupId: number) {
        return this.mystarService.getGroupMemberListV2(groupId);
    }

    @Get("/artists")
    @Header("Cache-Control", "max-age=60")
    @ApiOperation({summary: "마이스타 가수 리스트 API", description: "마이스타 가수 리스트(pagination 가능)"})
    @ApiQuery({name: "name", required: false})
    @ApiQuery({name: "page", required: false, schema: {type: "number", default: 1}})
    @ApiQuery({name: "limit", required: false, schema: {type: "number", default: 20}})
    @ApiQuery({name: "gender", enum: GENDER, required: false, schema: {type: "string", default: GENDER.FEMAIL}})
    @ApiQuery({name: "sort", required: false, schema: {type: "string", default: "member.name_ko"}})
    @ApiQuery({name: "order", required: false, enum: ORDER, schema: {type: "string", default: ORDER.asc}})
    getArtists(
        @Query("name") name?: string,
        @Query("page", new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query("limit", new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
        @Query("gender", new DefaultValuePipe(GENDER.FEMAIL)) gender = GENDER.FEMAIL,
        @Query("sort", new DefaultValuePipe("Member.memberName")) sort = "name_ko",
        @Query("order", new DefaultValuePipe(ORDER.asc)) order: "ASC" | "DESC" = "DESC"
    ) {
        // if (name) {
        //     return this.mystarService.getArtistsByName({page, limit}, name, gender, sort, order);
        // }
        return this.mystarService.getArtists({page, limit}, gender, sort, order);
    }

    @Get("/artists/v2")
    @Header("Cache-Control", "max-age=60")
    @ApiOperation({summary: "마이스타 가수 리스트 API", description: "마이스타 가수 리스트(pagination 가능)"})
    @ApiQuery({name: "searchText", required: false})
    @ApiQuery({name: "page", required: false, schema: {type: "number", default: 1}})
    @ApiQuery({name: "limit", required: false, schema: {type: "number", default: 20}})
    @ApiQuery({name: "sort", required: false, schema: {type: "string", default: "Member.memberName"}})
    @ApiQuery({name: "order", required: false, enum: ORDER, schema: {type: "string", default: ORDER.asc}})
    getArtistsV2(
        @Query("searchText") searchText?: string,
        @Query("page", new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
        @Query("limit", new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
        @Query("sort", new DefaultValuePipe("Member.memberName")) sort = "Member.memberName",
        @Query("order", new DefaultValuePipe(ORDER.asc)) order: "ASC" | "DESC" = "DESC"
    ): Promise<MystarArtistMainDto> {
        return this.mystarService.getArtistsV2({page, limit}, searchText, sort, order);
    }

    @ApiOperation({summary: "아티스트 검색 API (그룹도 함께 검색합니다)", description: "%LIKE% 쿼리로 검색합니다"})
    @ApiQuery({name: "gender", enum: GENDER, required: false, schema: {type: "string", default: GENDER.FEMAIL}})
    @ApiQuery({name: "name", required: true, description: "아티스트명 또는 그룹명"})
    @Header("Cache-Control", "max-age=86400")
    @Get("/artists/byName")
    async getArtistsByName(
        @Query("gender", new DefaultValuePipe(GENDER.FEMAIL)) gender = GENDER.FEMAIL,
        @Query("name") name: string
    ) {
        return this.mystarService.getArtistsByNameDeprecated(gender, name);
    }

    @ApiOperation({summary: "마이스타 가수 한 명 가져오는 API"})
    @ApiParam({name: "artistId"})
    @Get("/artists/:artistId")
    @Header("Cache-Control", "max-age=60")
    async getArtist(@Param("artistId") artistId: number) {
        return this.mystarService.getArtist(artistId);
    }
}

