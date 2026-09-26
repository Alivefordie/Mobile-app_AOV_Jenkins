import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',

  workers: process.env.CI ? 1 : undefined,

  reporter: [
    [
      'junit',
      {
        outputFile: 'reports/e2e-junit.xml',
      },
    ],
    [
      'html',
      {
        outputFolder: 'playwright-report',
        open: 'never',
        doNotInlineAssets: true,
      },
    ],
  ],

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
  },
});