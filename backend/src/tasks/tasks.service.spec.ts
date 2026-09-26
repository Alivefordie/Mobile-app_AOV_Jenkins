import { NotFoundException } from '@nestjs/common';
import { TasksService } from './tasks.service';

describe('TasksService', () => {
  let service: TasksService;

  beforeEach(() => {
    service = new TasksService();
  });

  it('should start with an empty task list', () => {
    expect(service.findAll()).toEqual([]);
  });

  it('should create a task', () => {
    const task = service.create('Test task');

    expect(task).toEqual({
      id: 1,
      title: 'Test task',
      done: false,
    });
  });

  it('should return all created tasks', () => {
    service.create('Task 1');
    service.create('Task 2');

    const tasks = service.findAll();

    expect(tasks).toHaveLength(2);
    expect(tasks[0].title).toBe('Task 1');
    expect(tasks[1].title).toBe('Task 2');
  });

  it('should mark a task as done', () => {
    const task = service.create('Complete me');

    const updatedTask = service.markDone(task.id);

    expect(updatedTask.done).toBe(true);
    expect(updatedTask.id).toBe(task.id);
  });

  it('should throw NotFoundException when task does not exist', () => {
    expect(() => service.markDone(999)).toThrow(NotFoundException);
  });
});