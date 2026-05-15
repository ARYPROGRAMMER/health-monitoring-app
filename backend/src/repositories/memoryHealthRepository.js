import { createDefaultAlerts, createDefaultProfile, createSampleReadings, defaultSettings } from '../data/sampleData.js';

export class MemoryHealthRepository {
  constructor() {
    this.mode = 'memory';
    this.users = new Map();
  }

  ensureUser(user) {
    if (!this.users.has(user.uid)) {
      this.users.set(user.uid, {
        profile: createDefaultProfile(user),
        settings: { ...defaultSettings },
        readings: createSampleReadings(),
        alerts: createDefaultAlerts()
      });
    }

    return this.users.get(user.uid);
  }

  async getProfile(user) {
    return this.ensureUser(user).profile;
  }

  async updateProfile(user, updates) {
    const record = this.ensureUser(user);
    record.profile = {
      ...record.profile,
      ...updates,
      uid: user.uid,
      updatedAt: new Date().toISOString()
    };

    return record.profile;
  }

  async getSettings(user) {
    return this.ensureUser(user).settings;
  }

  async updateSettings(user, updates) {
    const record = this.ensureUser(user);
    record.settings = {
      ...record.settings,
      ...updates
    };

    return record.settings;
  }

  async getReadings(user) {
    return this.ensureUser(user).readings;
  }

  async addReadings(user, readings) {
    const record = this.ensureUser(user);
    const existingIds = new Set(record.readings.map((reading) => reading.id));
    const incomingReadings = readings.filter((reading) => !existingIds.has(reading.id));
    record.readings = [...record.readings, ...incomingReadings].sort((a, b) => new Date(a.recordedAt) - new Date(b.recordedAt));

    return record.readings;
  }

  async getAlerts(user) {
    return this.ensureUser(user).alerts;
  }

  async addAlerts(user, alerts) {
    const record = this.ensureUser(user);
    const existingIds = new Set(record.alerts.map((alert) => alert.id));
    const incomingAlerts = alerts.filter((alert) => !existingIds.has(alert.id));
    record.alerts = [...incomingAlerts, ...record.alerts].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    return record.alerts;
  }

  async updateAlertStatus(user, alertId, status) {
    const record = this.ensureUser(user);
    const timestamp = new Date().toISOString();
    record.alerts = record.alerts.map((alert) => alert.id === alertId ? {
      ...alert,
      status,
      resolvedAt: status === 'resolved' ? timestamp : alert.resolvedAt
    } : alert);

    return record.alerts.find((alert) => alert.id === alertId) ?? null;
  }
}
