import {Controller, Get, Logger, UseGuards, Request, Post, Delete, Param, Query} from "@nestjs/common";
import {CelebService} from './celeb.service';
import {ApiBearerAuth, ApiOperation, ApiTags} from '@nestjs/swagger';
import {BasicUserDto} from '../../../common/dto/basic-user.dto';
import { JwtAuthGuard } from '../../../common/auth/jwt-auth.guard';
@ApiTags('Celeb API')
@Controller('user/celeb')
export class CelebController {
    private readonly logger = new Logger(CelebController.name);

    constructor(private readonly celebService: CelebService) {
    }

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get()
    findAll(@Request() req) {
        const {id} = req.user as BasicUserDto;
        return this.celebService.findAll();
    }

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('/me')
    findMine(@Request() req) {
        const {id} = req.user as BasicUserDto;
        return this.celebService.findMine(id);
    }

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get("/search")
    search(@Query('q') q : string) {
        return this.celebService.search(q);
    }

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Post(':celebId/bookmark')
    addBookmark(@Param('celebId')celebId : number,@Request() req ) {
        const {id} = req.user as BasicUserDto;
        return this.celebService.addBookmark(celebId,id);
    }

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Delete(':celebId/bookmark')
    deleteBookmark(@Param('celebId')celebId : number,@Request() req) {
        const {id} = req.user as BasicUserDto;
        return this.celebService.deleteBookmark(celebId, id);
    }

    @ApiOperation({
        summary: '배너 조회 API',
    })
    @Get('/banner/:celebId')
    getBanner(@Param('celebId')celebId : number) {
        return this.celebService.getBanners(celebId);
    }
}