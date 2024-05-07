import {
  Body,
  Controller,
  Delete,
  Get,
  Logger,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { CommentService } from './comment.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { UpdateCommentDto } from './dto/update-comment.dto';
import { JwtAuthGuard } from '../../../common/auth/jwt-auth.guard';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiQuery, ApiTags } from "@nestjs/swagger";
import { BasicUserDto } from '../../../common/dto/basic-user.dto';

@ApiTags('Comment API')
@Controller('user/comment')
export class CommentController {
  private readonly logger = new Logger(CommentController.name);

  constructor(private readonly commentService: CommentService) {}

  @ApiOperation({
    summary: '인기 코맨트 조회 API',
  })
  @Get('/popular/:articleId')
  findPopular(
    @Param('articleId') articleId: number,
    @Query('page') page: number,
    @Query('limit') limit: number = 10,
  ) {
    return this.commentService.findPopular(articleId);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Post('/article/:articleId')
  createComment(
    @Request() req,
    @Param('articleId') articleId: number,
    @Body() createCommentDto: CreateCommentDto,
  ) {
    const { id: userId } = req.user as BasicUserDto;
    createCommentDto.userId = userId;
    createCommentDto.userNickname = req.user.nickname;

    return this.commentService.createComment(createCommentDto);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Post('/article/:articleId/comment/:parentId')
  createCommentReply(
    @Request() req,
    @Param('articleId') articleId: number,
    @Param('parentId') parentId: number,
    @Body() createCommentDto: CreateCommentDto,
  ) {
    const { id: userId } = req.user as BasicUserDto;
    createCommentDto.articleId = articleId;
    createCommentDto.userId = userId;
    createCommentDto.userNickname = req.user.nickname;
    createCommentDto.parentId = parentId;

    return this.commentService.createComment(createCommentDto);
  }

  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Get('/article/:articleId')
  findAll(
    @Request() req,
    @Param('articleId') articleId: number,
    @Query('page') page : number = 1,
    @Query('limit') limit: number = 10,
    @Query('sort') sort: string = 'comment.created_at',
    @Query('order') order: string = 'DESC',
  ) {
    const { id: userId } = req.user as BasicUserDto;
    return this.commentService.findAll(userId, articleId, page, limit, sort, order);
  }

  @ApiOperation({
    summary: '코멘트 좋아요 추가 API',
    description: '코멘트 좋아요 추가 API',
  })
  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Post('/:commentId/like')
  async addLike(@Request() req, @Param('commentId') commentId: number) {
    const { id } = req.user as BasicUserDto;
    return this.commentService.addLike(id, commentId);
  }

  @ApiOperation({
    summary: '코멘트 좋아요 취소 API',
    description: '코멘트 좋아요 취소 API',
  })
  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Delete('/:commentId/like')
  async removeLike(
    @Request() req,
    @Param('commentId') commentId: number,
  ) {
    const { id } = req.user as BasicUserDto;
    return this.commentService.removeLike(id, commentId);
  }
  //
  @ApiOperation({
    summary: '신고 추가 API',
    description: '신고 추가 API',
  })
  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  @Post('/:commentId/report')
  async addReport(@Request() req, @Param('commentId') commentId: number) {
    const { id } = req.user as BasicUserDto;
    return this.commentService.addReport(id, commentId);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateCommentDto: UpdateCommentDto) {
    return this.commentService.update(+id, updateCommentDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.commentService.remove(+id);
  }
}
