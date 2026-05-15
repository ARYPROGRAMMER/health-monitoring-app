import { firestore } from '../config/firebase.js';
import { FirestoreHealthRepository } from './firestoreHealthRepository.js';
import { MemoryHealthRepository } from './memoryHealthRepository.js';

export const createHealthRepository = () => {
  if (firestore) {
    return new FirestoreHealthRepository(firestore);
  }

  return new MemoryHealthRepository();
};
