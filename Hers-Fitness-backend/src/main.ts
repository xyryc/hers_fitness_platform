import { NestFactory, Reflector } from '@nestjs/core';
import { AppModule } from './app.module';
import { ClassSerializerInterceptor } from '@nestjs/common';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';
import { AppValidationPipe } from './common/pipes/app-validation.pipe';
import { AppConfig } from './config/app.config';
import { setupSwagger } from './config/swagger.config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const appConfig = app.get(AppConfig);
  const port = appConfig.port;

  app.setGlobalPrefix('api');

  setupSwagger(app);

  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalPipes(new AppValidationPipe());

  app.useGlobalInterceptors(
    new ClassSerializerInterceptor(app.get(Reflector)), //// this code is for global serializer and validation
    new ResponseInterceptor(),
  );

  await app.listen(port, async () => {
    console.log(`Application is running on: ${await app.getUrl()}`);
  });
}
bootstrap();
