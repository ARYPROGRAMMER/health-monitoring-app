import { Router } from 'express';
import { sendSuccess } from '../utils/apiResponse.js';
import { syncPayloadSchema } from '../validation/schemas.js';

export const healthRoutes = ({ healthDataService }) => {
  const router = Router();

  router.get('/dashboard', async (request, response, next) => {
    try {
      const dashboard = await healthDataService.getDashboard(request.user);
      sendSuccess(response, dashboard, 'Dashboard loaded');
    } catch (error) {
      next(error);
    }
  });

  router.get('/vitals', async (request, response, next) => {
    try {
      const vitals = await healthDataService.getVitals(request.user);
      sendSuccess(response, vitals, 'Vitals loaded');
    } catch (error) {
      next(error);
    }
  });

  router.get('/trends', async (request, response, next) => {
    try {
      const trends = await healthDataService.getTrends(request.user);
      sendSuccess(response, trends, 'Trends loaded');
    } catch (error) {
      next(error);
    }
  });

  router.post('/sync', async (request, response, next) => {
    try {
      const payload = syncPayloadSchema.parse(request.body);
      const result = await healthDataService.syncHealthData(request.user, payload);
      sendSuccess(response, result, 'Health data synced');
    } catch (error) {
      next(error);
    }
  });

  return router;
};
