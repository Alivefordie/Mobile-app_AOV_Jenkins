import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  getHealth(): string {
    return this.appService.getHealth();
  }

  @Get('version')
  getVersion(): string {
    return this.appService.getVersion();
  }

  @Get('app-name')
  getAppName(): string {
    return this.appService.getAppName();
  }

  @Get('environment')
  getEnvironment(): string {
    return this.appService.getEnvironment();
  }
}