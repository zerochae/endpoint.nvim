import { Controller, Get } from '@nestjs/common';

@Controller('admin/dashboard')
export class DashboardController {
  @Get()
  getStats() {
    return {};
  }

  @Get('metrics')
  getMetrics() {
    return {};
  }
}
