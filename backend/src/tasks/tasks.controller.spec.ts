import { Test, TestingModule } from '@nestjs/testing';
import { TasksController } from './tasks.controller';
import { TasksService } from './tasks.service';

describe('TasksController', () => {
  let controller: TasksController;
  let service: TasksService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TasksController],
      providers: [TasksService],
    }).compile();

    controller = module.get<TasksController>(TasksController);
    service = module.get<TasksService>(TasksService);
  });

  it('should list tasks', () => {
    service.create('Task 1');

    const tasks = controller.findAll();

    expect(tasks).toHaveLength(1);
    expect(tasks[0].title).toBe('Task 1');
  });

  it('should create a task', () => {
    const task = controller.create({
      title: 'Controller task',
    });

    expect(task.title).toBe('Controller task');
    expect(task.done).toBe(false);
  });

  it('should mark a task as done', () => {
    const task = service.create('Complete me');

    const updatedTask = controller.markDone(String(task.id));

    expect(updatedTask.id).toBe(task.id);
    expect(updatedTask.done).toBe(true);
  });
});
