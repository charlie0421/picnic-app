import {Controller, Get, Logger, Param, Query, Request, UseGuards} from "@nestjs/common";
import {GalleryService} from './gallery.service';
import {ApiBearerAuth, ApiOperation, ApiQuery, ApiTags} from '@nestjs/swagger';
import { JwtAuthGuard } from 'api-auth/dist/auth/src/auth/jwt-auth.guard';
import {BasicUserDto} from "../../../common/dto/basic-user.dto";

@ApiTags('Gallery API')
@Controller('user/gallery')
export class GalleryController {
    private readonly logger = new Logger(GalleryController.name);

    constructor(private readonly gelleryService: GalleryService) {
    }

    ////////////////////////////////////////////////
    // Gallery
    ////////////////////////////////////////////////
    @ApiOperation({
        summary: '전체 갤러리 리스트',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('')
    findAll() {
        return this.gelleryService.findAll();
    }

    @ApiOperation({
        summary: '샐럽별 갤러리 리스트',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('/celeb/:celebId')
    findGalleryByCeleb(@Param('celebId') celebId: number) {
        return this.gelleryService.findGalleryByCeleb(celebId);
    }

    ////////////////////////////////////////////////
    // Articles
    ////////////////////////////////////////////////

    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @ApiOperation({
        summary: '갤러리 아티클 API',
    })
    @ApiQuery({name: 'page', required: false, type: Number})
    @ApiQuery({name: 'limit', required: false, type: Number})
    @ApiQuery({name: 'sort', required: false, type: String})
    @ApiQuery({name: 'order', required: false, type: String})
    @Get('/articles/:galleryId')
    findArticles(@Request() req, @Param('galleryId') galleryId: number,
                 @Query('page') page: number = 1, @Query('limit') limit: number = 10
        , @Query('sort') sort: string = 'createdAt', @Query('order') order: 'ASC' | 'DESC' = 'DESC') {
        const {id: userId} = req.user as BasicUserDto;
        return this.gelleryService.findArticles(userId, galleryId, {page, limit}, sort, order);
    }

    ////////////////////////////////////////////////
    // Images
    ////////////////////////////////////////////////

    @ApiOperation({
        summary: '이미지 조회 API',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('/images/:articleId')
    findImages(@Param('galleryId') galleryId: number) {
        return this.gelleryService.findImages(galleryId);
    }

    @ApiOperation({
        summary: '소장 이미지 조회 API',
    })
    @ApiBearerAuth('access-token')
    @UseGuards(JwtAuthGuard)
    @Get('/myImages/:articleId')
    findImagesMine(@Request() req, @Param('galleryId') galleryId: number) {
        const {id} = req.user as BasicUserDto;
        return this.gelleryService.findImagesMine(id, galleryId);
    }


}