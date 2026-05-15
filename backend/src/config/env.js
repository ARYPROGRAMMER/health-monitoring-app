import dotenv from 'dotenv';

dotenv.config();

const booleanFromEnv = (value, fallback) => {
  if (value === undefined || value === '') {
    return fallback;
  }

  return ['1', 'true', 'yes', 'on'].includes(value.toLowerCase());
};

export const env = {
  port: Number(process.env.PORT ?? 8080),
  corsOrigin: process.env.CORS_ORIGIN ?? '*',
  allowDemoAuth: booleanFromEnv(process.env.ALLOW_DEMO_AUTH, process.env.NODE_ENV !== 'production'),
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? 'stealthera',
  firebaseServiceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH ?? '',
  firebaseServiceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '',
  isProduction: process.env.NODE_ENV === 'production'
};
