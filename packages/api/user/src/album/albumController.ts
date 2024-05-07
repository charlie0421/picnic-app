import {Controller, Get, Logger, UseGuards, Request, Post, Delete, Param, Query, Body} from "@nestjs/common";
import {AlbumService} from './album.service';
import {ApiBearerAuth, ApiOperation, ApiTags} from '@nestjs/swagger';
import { JwtAuthGuard } from 'api-auth/dist/auth/src/auth/jwt-auth.guard';
import { BasicUserDto } from 'api-common/dto/basic-user.dto';

@ApiTags('Library API')
@Controller('user/library')
export class AlbumController {
    private readonly logger = new Logger(AlbumController.name);

    constructor(private readonly libraryService: AlbumService) {
    }

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('/me')
    findMine(@Request() req) {
        const {id} = req.user as BasicUserDto;
        return this.libraryService.findMine(id);
    }


    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Post()
    addImageToLibrary(@Request() req, @Query('libraryId') libraryId: number, @Query('imageId') imageId: number) {
        const {id: userId  } = req.user as BasicUserDto;
        this.logger.log('addImageToLibrary userId: ' + userId + ' libraryId: ' + libraryId + ' imageId: ' + imageId);
        return this.libraryService.addImageToLibrary(userId, libraryId, imageId);
    }

}