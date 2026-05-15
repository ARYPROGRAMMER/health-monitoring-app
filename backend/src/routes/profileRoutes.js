import { Router } from 'express';
import { sendSuccess } from '../utils/apiResponse.js';
import { profileUpdateSchema } from '../validation/schemas.js';

export const profileRoutes = ({ healthDataService }) => {
  const router = Router();

  router.get('/', async (request, response, next) => {
    try {
      const profile = await healthDataService.getProfile(request.user);
      sendSuccess(response, profile, 'Profile loaded');
    } catch (error) {
      next(error);
    }
  });

  router.put('/', async (request, response, next) => {
    try {
      const updates = profileUpdateSchema.parse(request.body);
      const profile = await healthDataService.updateProfile(request.user, updates);
      sendSuccess(response, profile, 'Profile updated');
    } catch (error) {
      next(error);
    }
  });

  return router;
};
