import { Controller, Get, Post, Put, Delete, Param, Body, Query, Patch } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getHello(): string {
    return 'Hello World!';
  }

  @Get('health')
  getHealth(): string {
    return 'OK';
  }

  @Get('version')
  getVersion(): string {
    return 'v1.0.0';
  }

  @Get('status')
  getStatus(): string {
    return 'Running';
  }

  @Post('feedback')
  submitFeedback(@Body() feedback: any): string {
    return 'Feedback submitted';
  }

  @Get('metrics')
  getMetrics(): string {
    return 'System metrics';
  }
}