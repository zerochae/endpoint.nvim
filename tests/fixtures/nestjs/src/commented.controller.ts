import { Controller, Get, Post, Put, Delete, Patch } from '@nestjs/common';

@Controller('comments')
export class CommentedController {

  // Single line commented endpoints - should be filtered
  // @Get('/single-line-comment')
  // getSingleLineComment() { return 'filtered'; }

  // @Post('/another-single-line')
  // postAnotherSingleLine() { return 'filtered'; }

  /* Block commented endpoints - should be filtered */
  /* @Put('/block-comment') */
  /* putBlockComment() { return 'filtered'; } */

  /*
   * Multi-line block commented endpoints - should be filtered
   * @Delete('/multi-line-block')
   * deleteMultiLineBlock() { return 'filtered'; }
   */

  /**
   * JSDoc commented endpoints - should be filtered
   * @Patch('/jsdoc-comment')
   * patchJsdocComment() { return 'filtered'; }
   */

  // Active endpoints - should NOT be filtered
  @Get('/active')
  getActive() {
    return 'active';
  }

  @Post('/users')
  createUser() {
    return 'created';
  }

  // Mixed scenarios
  /*
  @Get('/mixed-block')
  getMixedBlock() {
    return 'filtered';
  }
  */

  // @Get('/commented-inline') // This should be filtered

  @Patch('/active-after-comment')
  patchActiveAfterComment() {
    return 'active'; // This should NOT be filtered
  }

  // GraphQL examples
  // @Query(() => String)
  // getCommentedQuery() { return 'filtered'; }

  @Query(() => String)
  getActiveQuery() {
    return 'active';
  }
}