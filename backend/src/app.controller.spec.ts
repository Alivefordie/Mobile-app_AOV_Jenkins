import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  it('should return Hello World!', () => {
    expect(appController.getHello()).toBe('Hello World!');
  });

  it('should return health status OK', () => {
    expect(appController.getHealth()).toBe('OK');
  });

  it('should return version 1.0.0', () => {
    expect(appController.getVersion()).toBe('1.0.0');
  });

  it('should return app name taskflow-api', () => {
    expect(appController.getAppName()).toBe('taskflow-api');
  });

  it('should return environment test', () => {
    expect(appController.getEnvironment()).toBe('test');
  });
});
