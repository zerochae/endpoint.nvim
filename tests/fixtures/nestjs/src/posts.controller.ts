import { Controller, Get, Post, Put, Delete, Param, Body, Query, Patch } from '@nestjs/common';

@Controller('posts')
export class PostsController {
  @Get()
  findAll(@Query('page') page?: number, @Query('limit') limit?: number): string {
    return `All posts (page: ${page || 1}, limit: ${limit || 10})`;
  }

  @Get('trending')
  getTrendingPosts(): string {
    return 'Trending posts';
  }

  @Get('recent')
  getRecentPosts(): string {
    return 'Recent posts';
  }

  @Get('categories/:category')
  getPostsByCategory(@Param('category') category: string): string {
    return `Posts in category: ${category}`;
  }

  @Get('search')
  searchPosts(@Query('q') query: string): string {
    return `Search posts for: ${query}`;
  }

  @Get(':id')
  findOne(@Param('id') id: string): string {
    return `Post #${id}`;
  }

  @Get(':id/comments')
  getPostComments(@Param('id') id: string): string {
    return `Comments for post #${id}`;
  }

  @Get(':id/likes')
  getPostLikes(@Param('id') id: string): string {
    return `Likes for post #${id}`;
  }

  @Get(':id/shares')
  getPostShares(@Param('id') id: string): string {
    return `Shares for post #${id}`;
  }

  @Post()
  create(@Body() createPostDto: any): string {
    return 'Post created';
  }

  @Post(':id/like')
  likePost(@Param('id') id: string): string {
    return `Liked post #${id}`;
  }

  @Post(':id/share')
  sharePost(@Param('id') id: string): string {
    return `Shared post #${id}`;
  }

  @Post(':id/comments')
  addComment(@Param('id') id: string, @Body() commentDto: any): string {
    return `Comment added to post #${id}`;
  }

  @Post(':id/report')
  reportPost(@Param('id') id: string): string {
    return `Post #${id} reported`;
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updatePostDto: any): string {
    return `Post #${id} updated`;
  }

  @Put(':id/publish')
  publishPost(@Param('id') id: string): string {
    return `Post #${id} published`;
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() statusDto: any): string {
    return `Status updated for post #${id}`;
  }

  @Delete(':id')
  remove(@Param('id') id: string): string {
    return `Post #${id} deleted`;
  }

  @Delete(':id/like')
  unlikePost(@Param('id') id: string): string {
    return `Unliked post #${id}`;
  }

  @Delete(':id/comments/:commentId')
  removeComment(@Param('id') id: string, @Param('commentId') commentId: string): string {
    return `Comment #${commentId} removed from post #${id}`;
  }
}