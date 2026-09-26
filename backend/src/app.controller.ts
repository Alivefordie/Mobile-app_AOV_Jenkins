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

  // @Get('status')
  // getStatus(): string {
  //   return this.appService.getStatus();
  // }

  // @Get('author')
  // getAuthor(): string {
  //   return this.appService.getAuthor();
  // }

  // @Get('build-number')
  // getBuildNumber(): number {
  //   return this.appService.getBuildNumber();
  // }

  // @Get('ready')
  // isReady(): boolean {
  //   return this.appService.isReady();
  // }

  // @Get('description')
  // getDescription(): string {
  //   return this.appService.getDescription();
  // }
}
