import { Controller, Get, Post, Param } from '@nestjs/common';

@Controller('api/orders')
export class OrdersController {
  @Get()
  findAll() {
    return [];
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return {};
  }

  @Post()
  create() {
    return {};
  }
}
