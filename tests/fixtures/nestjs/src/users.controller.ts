import { Controller, Get, Post, Put, Delete, Param, Body, Query, Patch } from '@nestjs/common';

@Controller('users')
export class UsersController {
  @Get()
  findAll(@Query('limit') limit?: number): string {
    return `All users (limit: ${limit || 'none'})`;
  }

  @Get('active')
  findActiveUsers(): string {
    return 'Active users';
  }

  @Get('search')
  searchUsers(@Query('q') query: string): string {
    return `Search results for: ${query}`;
  }

  @Get(':id')
  findOne(@Param('id') id: string): string {
    return `User #${id}`;
  }

  @Get(':id/profile')
  getUserProfile(@Param('id') id: string): string {
    return `Profile for user #${id}`;
  }

  @Get(':id/posts')
  getUserPosts(@Param('id') id: string): string {
    return `Posts by user #${id}`;
  }

  @Get(':id/followers')
  getUserFollowers(@Param('id') id: string): string {
    return `Followers of user #${id}`;
  }

  @Get(':id/following')
  getUserFollowing(@Param('id') id: string): string {
    return `Users followed by #${id}`;
  }

  @Post()
  create(@Body() createUserDto: any): string {
    return 'User created';
  }

  @Post(':id/follow')
  followUser(@Param('id') id: string): string {
    return `Following user #${id}`;
  }

  @Post(':id/avatar')
  uploadAvatar(@Param('id') id: string): string {
    return `Avatar uploaded for user #${id}`;
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateUserDto: any): string {
    return `User #${id} updated`;
  }

  @Put(':id/profile')
  updateProfile(@Param('id') id: string, @Body() profileDto: any): string {
    return `Profile updated for user #${id}`;
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() statusDto: any): string {
    return `Status updated for user #${id}`;
  }

  @Patch(':id/preferences')
  updatePreferences(@Param('id') id: string, @Body() prefsDto: any): string {
    return `Preferences updated for user #${id}`;
  }

  @Delete(':id')
  remove(@Param('id') id: string): string {
    return `User #${id} deleted`;
  }

  @Delete(':id/avatar')
  removeAvatar(@Param('id') id: string): string {
    return `Avatar removed for user #${id}`;
  }

  @Delete(':id/unfollow')
  unfollowUser(@Param('id') id: string): string {
    return `Unfollowed user #${id}`;
  }
}