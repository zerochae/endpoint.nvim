import { Controller, Get, Post, Delete, Param } from '@nestjs/common';

@Controller('admin/users')
export class AdminUsersController {
  @Get()
  findAll() {
    return [];
  }

  @Post(':id/ban')
  banUser(@Param('id') id: string) {
    return {};
  }

  @Delete(':id')
  removeUser(@Param('id') id: string) {
    return {};
  }
}
