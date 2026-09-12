import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  host: process.env.DB_HOST ?? 'localhost', //postgres//localhostw
  //host: process.env.DB_HOST ?? 'postgres', //postgres//localhostw
  port: Number.parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USER ?? 'root',
  password: process.env.DB_PASSWORD ?? 'root',
  name: process.env.DB_NAME ?? 'dev',
}));
