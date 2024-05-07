// same as `interface IPaginationMeta`
import { ApiProperty } from '@nestjs/swagger';

export class PaginationMetaDto {
  /**
   * the amount of items on this specific page
   */
  @ApiProperty({ type: Number })
  itemCount: number;

  /**
   * the total amount of items
   */
  @ApiProperty({ type: Number })
  totalItems: number;

  /**
   * the amount of items that were requested per page
   */
  @ApiProperty({ type: Number })
  itemsPerPage: number;

  /**
   * the total amount of pages in this paginator
   */
  @ApiProperty({ type: Number })
  totalPages: number;

  /**
   * the current page this paginator "points" to
   */
  @ApiProperty({ type: Number })
  currentPage: number;
}
