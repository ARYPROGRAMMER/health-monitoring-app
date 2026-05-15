import admin from 'firebase-admin';
import fs from 'node:fs';
import { env } from './env.js';

const parseServiceAccountJson = (value) => {
  if (!value) {
    return null;
  }

  try {
    return JSON.parse(value);
  } catch {
    return JSON.parse(Buffer.from(value, 'base64').toString('utf8'));
  }
};

const readServiceAccount = () => {
  const inlineAccount = parseServiceAccountJson(env.firebaseServiceAccountJson);

  if (inlineAccount) {
    return inlineAccount;
  }

  if (env.firebaseServiceAccountPath) {
    return JSON.parse(fs.readFileSync(env.firebaseServiceAccountPath, 'utf8'));
  }

  return null;
};

const initializeFirebase = () => {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const serviceAccount = readServiceAccount();

  if (serviceAccount) {
    return admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: env.firebaseProjectId
    });
  }

  if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.FIRESTORE_EMULATOR_HOST) {
    return admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: env.firebaseProjectId
    });
  }

  throw new Error('Firebase Admin credentials are required');
};

const firebaseApp = initializeFirebase();

export const firebaseAdmin = admin;
export const firebaseAppInstance = firebaseApp;
export const firestore = admin.firestore();
