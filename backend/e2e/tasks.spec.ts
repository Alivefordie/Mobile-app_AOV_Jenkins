import { test, expect } from '@playwright/test';

test('list tasks', async ({ request }) => {
  const response = await request.get('/tasks');

  expect(response.ok()).toBeTruthy();

  const tasks = await response.json();
  expect(Array.isArray(tasks)).toBeTruthy();
});

test('create task', async ({ request }) => {
  const response = await request.post('/tasks', {
    data: {
      title: 'Playwright task',
    },
  });

  expect(response.status()).toBe(201);

  const task = await response.json();

  expect(task.title).toBe('Playwright task');
  expect(task.done).toBe(false);
});

test('mark task done', async ({ request }) => {
  const createResponse = await request.post('/tasks', {
    data: {
      title: 'Complete me',
    },
  });

  expect(createResponse.status()).toBe(201);

  const task = await createResponse.json();

  const response = await request.patch(`/tasks/${task.id}/done`);

  expect(response.ok()).toBeTruthy();

  const updatedTask = await response.json();

  expect(updatedTask.done).toBe(true);
});
