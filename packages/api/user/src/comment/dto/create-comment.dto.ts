export class CreateCommentDto {
  userId: number;
  articleId: number;
  parentId: number;
  readonly content: string;
  userNickname: string;
  readonly imgPath: string;
}
