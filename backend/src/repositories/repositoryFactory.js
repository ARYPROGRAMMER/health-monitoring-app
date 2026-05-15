import { FirestoreHealthRepository } from './firestoreHealthRepository.js';
import { firestore } from '../config/firebase.js';

export const createHealthRepository = () => {
  return new FirestoreHealthRepository(firestore);
};
