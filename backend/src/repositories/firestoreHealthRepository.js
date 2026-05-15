import { createDefaultProfile, defaultSettings } from '../data/defaults.js';

export class FirestoreHealthRepository {
  constructor(firestore) {
    this.mode = 'firestore';
    this.firestore = firestore;
  }

  userDocument(user) {
    return this.firestore.collection('users').doc(user.uid);
  }

  async getProfile(user) {
    const reference = this.userDocument(user);
    const snapshot = await reference.get();

    if (!snapshot.exists) {
      const profile = createDefaultProfile(user);
      await reference.set(profile, { merge: true });
      return profile;
    }

    return snapshot.data();
  }

  async updateProfile(user, updates) {
    const profile = {
      ...updates,
      uid: user.uid,
      updatedAt: new Date().toISOString()
    };

    await this.userDocument(user).set(profile, { merge: true });

    return this.getProfile(user);
  }

  async getSettings(user) {
    const reference = this.userDocument(user).collection('settings').doc('preferences');
    const snapshot = await reference.get();

    if (!snapshot.exists) {
      await reference.set(defaultSettings, { merge: true });
      return { ...defaultSettings };
    }

    return { ...defaultSettings, ...snapshot.data() };
  }

  async updateSettings(user, updates) {
    const reference = this.userDocument(user).collection('settings').doc('preferences');
    await reference.set(updates, { merge: true });

    return this.getSettings(user);
  }

  async getReadings(user) {
    const collection = this.userDocument(user).collection('readings');
    const snapshot = await collection.orderBy('recordedAt', 'desc').limit(96).get();

    return snapshot.docs.map((doc) => doc.data()).sort((a, b) => new Date(a.recordedAt) - new Date(b.recordedAt));
  }

  async addReadings(user, readings) {
    if (readings.length === 0) {
      return this.getReadings(user);
    }

    const collection = this.userDocument(user).collection('readings');
    const batch = this.firestore.batch();
    readings.forEach((reading) => batch.set(collection.doc(reading.id), reading, { merge: true }));
    await batch.commit();

    return this.getReadings(user);
  }

  async getAlerts(user) {
    const collection = this.userDocument(user).collection('alerts');
    const snapshot = await collection.orderBy('createdAt', 'desc').limit(50).get();

    return snapshot.docs.map((doc) => doc.data());
  }

  async addAlerts(user, alerts) {
    if (alerts.length === 0) {
      return this.getAlerts(user);
    }

    const collection = this.userDocument(user).collection('alerts');
    const batch = this.firestore.batch();
    alerts.forEach((alert) => batch.set(collection.doc(alert.id), alert, { merge: true }));
    await batch.commit();

    return this.getAlerts(user);
  }

  async updateAlertStatus(user, alertId, status) {
    const reference = this.userDocument(user).collection('alerts').doc(alertId);
    const snapshot = await reference.get();

    if (!snapshot.exists) {
      return null;
    }

    const updates = {
      status,
      resolvedAt: status === 'resolved' ? new Date().toISOString() : snapshot.data().resolvedAt ?? null
    };

    await reference.set(updates, { merge: true });
    const updatedSnapshot = await reference.get();

    return updatedSnapshot.data();
  }
}
