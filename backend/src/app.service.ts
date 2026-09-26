import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Hello World!';
  }

  getHealth(): string {
    return 'OK';
  }

  getVersion(): string {
    return '1.0.0';
  }

  getAppName(): string {
    return 'taskflow-api';
  }

  getEnvironment(): string {
    return 'test';
  }

  getStatus(): string {
    return 'running';
  }

  getAuthor(): string {
    return 'admin';
  }

  getBuildNumber(): number {
    return 1;
  }

  isReady(): boolean {
    return true;
  }

  getDescription(): string {
    return 'Taskflow API';
  }
}
