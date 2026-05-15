export class HealthDataService {
  constructor(repository, alertService) {
    this.repository = repository;
    this.alertService = alertService;
  }

  async getProfile(user) {
    return this.repository.getProfile(user);
  }

  async updateProfile(user, updates) {
    return this.repository.updateProfile(user, updates);
  }

  async getSettings(user) {
    return this.repository.getSettings(user);
  }

  async updateSettings(user, updates) {
    const settings = await this.repository.updateSettings(user, updates);
    const readings = await this.repository.getReadings(user);
    const alerts = this.alertService.createAlerts(readings, settings);
    await this.repository.addAlerts(user, alerts);

    return settings;
  }

  async getVitals(user) {
    const readings = await this.repository.getReadings(user);

    return {
      latest: this.latestVitals(readings),
      readings
    };
  }

  async getTrends(user) {
    const readings = await this.repository.getReadings(user);

    return this.buildTrends(readings);
  }

  async getAlerts(user) {
    return this.repository.getAlerts(user);
  }

  async updateAlertStatus(user, alertId, status) {
    return this.repository.updateAlertStatus(user, alertId, status);
  }

  async getDashboard(user) {
    const [profile, settings, readings, alerts] = await Promise.all([
      this.repository.getProfile(user),
      this.repository.getSettings(user),
      this.repository.getReadings(user),
      this.repository.getAlerts(user)
    ]);

    const generatedAlerts = this.alertService.createAlerts(readings, settings);
    const allAlerts = await this.repository.addAlerts(user, generatedAlerts);
    const latestVitals = this.latestVitals(readings);
    const trends = this.buildTrends(readings);

    return {
      profile,
      settings,
      latestVitals,
      trends,
      activeAlerts: allAlerts.filter((alert) => alert.status === 'active'),
      sleep: this.latestReading(readings, 'sleep'),
      activity: this.latestReading(readings, 'activity'),
      insights: this.buildInsights(latestVitals, settings),
      generatedAt: new Date().toISOString()
    };
  }

  async syncHealthData(user, payload) {
    if (payload.profile) {
      await this.repository.updateProfile(user, payload.profile);
    }

    if (payload.settings) {
      await this.repository.updateSettings(user, payload.settings);
    }

    const readings = payload.readings.map((reading) => ({
      ...reading,
      id: reading.id ?? `${reading.type}-${reading.recordedAt ?? new Date().toISOString()}`,
      recordedAt: reading.recordedAt ?? new Date().toISOString()
    }));

    const storedReadings = await this.repository.addReadings(user, readings);
    const settings = await this.repository.getSettings(user);
    const alerts = this.alertService.createAlerts(storedReadings, settings);
    await this.repository.addAlerts(user, alerts);

    return this.getDashboard(user);
  }

  latestVitals(readings) {
    return {
      heartRate: this.latestReading(readings, 'heart_rate'),
      spo2: this.latestReading(readings, 'spo2')
    };
  }

  latestReading(readings, type) {
    return readings
      .filter((reading) => reading.type === type)
      .sort((a, b) => new Date(b.recordedAt) - new Date(a.recordedAt))[0] ?? null;
  }

  buildTrends(readings) {
    return {
      heartRate: this.trendForType(readings, 'heart_rate'),
      spo2: this.trendForType(readings, 'spo2'),
      sleep: this.trendForType(readings, 'sleep'),
      activity: this.trendForType(readings, 'activity')
    };
  }

  trendForType(readings, type) {
    return readings
      .filter((reading) => reading.type === type)
      .sort((a, b) => new Date(a.recordedAt) - new Date(b.recordedAt))
      .map((reading) => ({
        value: reading.value,
        unit: reading.unit,
        recordedAt: reading.recordedAt
      }));
  }

  buildInsights(latestVitals, settings) {
    const insights = [];

    if (latestVitals.heartRate) {
      const heartRate = latestVitals.heartRate.value;
      const state = heartRate > settings.heartRateMax ? 'above range' : heartRate < settings.heartRateMin ? 'below range' : 'in range';
      insights.push({
        id: 'heart-rate-range',
        title: 'Heart rate',
        message: `Heart rate is ${state} at ${heartRate} bpm.`,
        tone: state === 'in range' ? 'positive' : 'warning'
      });
    }

    if (latestVitals.spo2) {
      const spo2 = latestVitals.spo2.value;
      insights.push({
        id: 'spo2-stability',
        title: 'Oxygen saturation',
        message: spo2 >= settings.spo2Min ? `SpO2 is stable at ${spo2}%.` : `SpO2 needs attention at ${spo2}%.`,
        tone: spo2 >= settings.spo2Min ? 'positive' : 'critical'
      });
    }

    return insights;
  }
}
