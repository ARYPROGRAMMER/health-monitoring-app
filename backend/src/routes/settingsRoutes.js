import { Router } from 'express';
import { sendSuccess } from '../utils/apiResponse.js';
import { settingsUpdateSchema } from '../validation/schemas.js';

export const settingsRoutes = ({ healthDataService }) => {
  const router = Router();

  router.get('/', async (request, response, next) => {
    try {
      const settings = await healthDataService.getSettings(request.user);
      sendSuccess(response, settings, 'Settings loaded');
    } catch (error) {
      next(error);
    }
  });

  router.put('/', async (request, response, next) => {
    try {
      const updates = settingsUpdateSchema.parse(request.body);
      const settings = await healthDataService.updateSettings(request.user, updates);
      sendSuccess(response, settings, 'Settings updated');
    } catch (error) {
      next(error);
    }
  });

  return router;
};
