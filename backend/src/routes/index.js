import { Router } from 'express';
import { authenticateFirebaseUser } from '../middleware/authenticateFirebaseUser.js';
import { alertRoutes } from './alertRoutes.js';
import { healthRoutes } from './healthRoutes.js';
import { profileRoutes } from './profileRoutes.js';
import { settingsRoutes } from './settingsRoutes.js';

export const apiRoutes = ({ healthDataService }) => {
  const router = Router();

  router.use(authenticateFirebaseUser);
  router.use('/alerts', alertRoutes({ healthDataService }));
  router.use('/health', healthRoutes({ healthDataService }));
  router.use('/profile', profileRoutes({ healthDataService }));
  router.use('/settings', settingsRoutes({ healthDataService }));

  return router;
};
