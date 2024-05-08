import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { AppService } from './app.service';

@Controller()
@ApiTags('Health Check API')
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('/auth')
  getHello(): string {
    return this.appService.getHello();
  }
}
