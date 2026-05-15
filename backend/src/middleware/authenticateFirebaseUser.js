import { env } from '../config/env.js';
import { firebaseAdmin, firebaseAppInstance } from '../config/firebase.js';
import { UnauthorizedError } from '../utils/httpError.js';

const readBearerToken = (request) => {
  const authorization = request.get('authorization') ?? '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);

  return match ? match[1] : null;
};

export const authenticateFirebaseUser = async (request, response, next) => {
  try {
    const token = readBearerToken(request);

    if (token && firebaseAppInstance) {
      const decodedToken = await firebaseAdmin.auth().verifyIdToken(token);
      request.user = {
        uid: decodedToken.uid,
        email: decodedToken.email ?? null,
        name: decodedToken.name ?? null
      };
      next();
      return;
    }

    if (token && !firebaseAppInstance && !env.allowDemoAuth) {
      throw new UnauthorizedError('Firebase Admin is not configured on the backend');
    }

    if (env.allowDemoAuth) {
      request.user = {
        uid: request.get('x-demo-user-id') ?? 'demo-user',
        email: request.get('x-demo-email') ?? 'demo@stealthera.app',
        name: request.get('x-demo-name') ?? 'Demo Patient'
      };
      next();
      return;
    }

    throw new UnauthorizedError('A valid Firebase bearer token is required');
  } catch (error) {
    next(error);
  }
};
