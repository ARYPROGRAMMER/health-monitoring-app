import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env.js';
import { swaggerOptions } from './config/swagger.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import { createHealthRepository } from './repositories/repositoryFactory.js';
import { apiRoutes } from './routes/index.js';
import { AlertService } from './services/alertService.js';
import { HealthDataService } from './services/healthDataService.js';
import { sendSuccess } from './utils/apiResponse.js';

const resolveCorsOrigin = () => {
  if (env.corsOrigin === '*') {
    return true;
  }

  return env.corsOrigin.split(',').map((origin) => origin.trim()).filter(Boolean);
};

export const createApp = () => {
  const app = express();
  const repository = createHealthRepository();
  const alertService = new AlertService();
  const healthDataService = new HealthDataService(repository, alertService);

  app.use(helmet());
  app.use(cors({ origin: resolveCorsOrigin(), credentials: true }));
  app.use(express.json({ limit: '1mb' }));
  app.use(morgan(env.isProduction ? 'combined' : 'dev'));
  app.use((request, response, next) => {
    const startedAt = Date.now();

    response.on('finish', () => {
      if (request.path === '/api/health/sync' || request.path === '/api/health/dashboard') {
        console.log(
          `[${request.method}] ${request.originalUrl} ${response.statusCode} ` +
            `${Date.now() - startedAt}ms user=${request.user?.uid ?? 'anonymous'} ` +
            `body=${JSON.stringify(request.body ?? {})}`,
        );
      }
    });

    next();
  });

  app.get('/healthz', (request, response) => {
    sendSuccess(response, {
      service: 'stealthera-backend',
      mode: repository.mode,
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    }, 'Backend is healthy');
  });

  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerOptions));

  app.use('/api', apiRoutes({ healthDataService }));
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};
