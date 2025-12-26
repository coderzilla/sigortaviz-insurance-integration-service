// src/main.ts
import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import helmet from '@fastify/helmet';
import fastifyCors from '@fastify/cors';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  // Security headers
  await app.register(helmet, {
    contentSecurityPolicy: false, // disable CSP by default; enable if you serve a UI
  });

  // CORS (allowlist via env CORS_ORIGINS=origin1,origin2)
  const corsOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  await app.register(fastifyCors, {
    origin: corsOrigins.length ? corsOrigins : ['http://localhost:3001'],
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-request-id'],
    credentials: true,
  });

  // Input validation & payload stripping
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // If you set this, remember the prefix:
  // app.setGlobalPrefix('api');

  await app.listen(3100, '0.0.0.0');
}
bootstrap();
