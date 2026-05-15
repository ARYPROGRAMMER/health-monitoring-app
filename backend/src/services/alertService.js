export class AlertService {
  createAlerts(readings, settings) {
    const latestReadings = this.latestByType(readings);
    const timestamp = new Date().toISOString();
    const alerts = [];

    const heartRate = latestReadings.heart_rate;
    const spo2 = latestReadings.spo2;
    const sleep = latestReadings.sleep;
    const activity = latestReadings.activity;

    if (heartRate && heartRate.value > settings.heartRateMax) {
      alerts.push(this.createAlert('heart_rate_high', 'critical', 'High heart rate detected', `Heart rate is ${heartRate.value} bpm, above your ${settings.heartRateMax} bpm threshold.`, heartRate.value, settings.heartRateMax, timestamp));
    }

    if (heartRate && heartRate.value < settings.heartRateMin) {
      alerts.push(this.createAlert('heart_rate_low', 'warning', 'Low heart rate detected', `Heart rate is ${heartRate.value} bpm, below your ${settings.heartRateMin} bpm threshold.`, heartRate.value, settings.heartRateMin, timestamp));
    }

    if (spo2 && spo2.value < settings.spo2Min) {
      alerts.push(this.createAlert('spo2_low', 'critical', 'Low SpO2 warning', `SpO2 is ${spo2.value}%, below your ${settings.spo2Min}% threshold.`, spo2.value, settings.spo2Min, timestamp));
    }

    if (sleep && sleep.value < settings.sleepTargetHours - 1) {
      alerts.push(this.createAlert('sleep_low', 'info', 'Sleep recovery watch', `Sleep is ${sleep.value} hours, below your ${settings.sleepTargetHours} hour target.`, sleep.value, settings.sleepTargetHours, timestamp));
    }

    if (activity && activity.value < settings.dailyStepsGoal * 0.55) {
      alerts.push(this.createAlert('activity_low', 'info', 'Activity goal lagging', `Steps are at ${activity.value}, below your usual goal pace.`, activity.value, settings.dailyStepsGoal, timestamp));
    }

    return alerts;
  }

  createAlert(type, severity, title, message, metricValue, thresholdValue, timestamp) {
    return {
      id: `${type}-${timestamp}`,
      type,
      severity,
      title,
      message,
      metricValue,
      thresholdValue,
      status: 'active',
      createdAt: timestamp,
      resolvedAt: null
    };
  }

  latestByType(readings) {
    return readings.reduce((latest, reading) => {
      const current = latest[reading.type];

      if (!current || new Date(reading.recordedAt) > new Date(current.recordedAt)) {
        latest[reading.type] = reading;
      }

      return latest;
    }, {});
  }
}
