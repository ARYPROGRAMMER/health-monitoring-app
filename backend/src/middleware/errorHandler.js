import { ZodError } from 'zod';
import { env } from '../config/env.js';
import { HttpError, NotFoundError } from '../utils/httpError.js';

export const notFoundHandler = (request, response, next) => {
  next(new NotFoundError(`Route ${request.method} ${request.originalUrl} was not found`));
};

export const errorHandler = (error, request, response, next) => {
  const isValidationError = error instanceof ZodError;
  const isHttpError = error instanceof HttpError;
  const statusCode = isValidationError ? 400 : isHttpError ? error.statusCode : 500;
  const message = statusCode === 500 && env.isProduction ? 'Internal server error' : error.message;
  const details = isValidationError ? error.flatten() : error.details;

  console.error(
    `[${request?.method ?? 'UNKNOWN'}] ${request?.originalUrl ?? 'UNKNOWN'} ` +
      `failed with ${statusCode}: ${message}`,
    {
      code: error.code ?? error.name ?? 'Error',
      details: details ?? null,
      body: request?.body ?? null
    }
  );

  response.status(statusCode).json({
    success: false,
    message,
    error: {
      code: error.code ?? error.name ?? 'Error',
      details: details ?? null
    }
  });
};
