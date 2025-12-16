import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS for Angular admin
  app.enableCors({
    origin: ['http://localhost:4200', 'http://localhost:4201'],
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
  }));

  // API prefix
  app.setGlobalPrefix('api/v1');

  await app.listen(process.env.PORT ?? 3000);
  console.log(`🚀 API running on http://localhost:${process.env.PORT ?? 3000}/api/v1`);
}
void bootstrap();
