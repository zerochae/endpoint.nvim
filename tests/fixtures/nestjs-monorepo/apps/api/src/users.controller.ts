import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';

@Controller('api/users')
export class UsersController {
  @Get()
  findAll() {
    return [];
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return {};
  }

  @Post()
  create(@Body() body: any) {
    return {};
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() body: any) {
    return {};
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return {};
  }
}
