import { Router } from 'express';
import { sendSuccess } from '../utils/apiResponse.js';
import { NotFoundError } from '../utils/httpError.js';
import { alertStatusSchema } from '../validation/schemas.js';

export const alertRoutes = ({ healthDataService }) => {
  const router = Router();

  router.get('/', async (request, response, next) => {
    try {
      const alerts = await healthDataService.getAlerts(request.user);
      sendSuccess(response, alerts, 'Alerts loaded');
    } catch (error) {
      next(error);
    }
  });

  router.patch('/:alertId', async (request, response, next) => {
    try {
      const { status } = alertStatusSchema.parse(request.body);
      const alert = await healthDataService.updateAlertStatus(request.user, request.params.alertId, status);

      if (!alert) {
        throw new NotFoundError('Alert was not found');
      }

      sendSuccess(response, alert, 'Alert updated');
    } catch (error) {
      next(error);
    }
  });

  return router;
};
