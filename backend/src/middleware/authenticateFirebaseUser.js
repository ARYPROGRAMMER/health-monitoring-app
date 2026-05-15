import { firebaseAdmin } from '../config/firebase.js';
import { UnauthorizedError } from '../utils/httpError.js';

const readBearerToken = (request) => {
  const authorization = request.get('authorization') ?? '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);

  return match ? match[1] : null;
};

export const authenticateFirebaseUser = async (request, response, next) => {
  try {
    const token = readBearerToken(request);

    if (!token) {
      throw new UnauthorizedError('A valid Firebase bearer token is required');
    }

    const decodedToken = await firebaseAdmin.auth().verifyIdToken(token);
    request.user = {
      uid: decodedToken.uid,
      email: decodedToken.email ?? null,
      name: decodedToken.name ?? null
    };
    next();
  } catch (error) {
    next(error);
  }
};
