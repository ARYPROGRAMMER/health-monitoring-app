import dotenv from 'dotenv';

dotenv.config();

export const env = {
  port: Number(process.env.PORT ?? 8080),
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? 'stealthera',
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH ?? '',
  firebaseServiceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '',
  isProduction: process.env.NODE_ENV === 'production'
};
