export const defaultSettings = {
  heartRateMin: 50,
  heartRateMax: 120,
  spo2Min: 94,
  dailyStepsGoal: 8000,
  sleepTargetHours: 7.5,
  notificationsEnabled: true,
  darkMode: false
};

export const createDefaultProfile = (user) => {
  const timestamp = new Date().toISOString();

  return {
    uid: user.uid,
    displayName: user.name ?? 'Stealthera Member',
    email: user.email ?? null,
    age: 32,
    sex: 'not_specified',
    createdAt: timestamp,
    updatedAt: timestamp
  };
};

const round = (value, digits = 0) => {
  const multiplier = 10 ** digits;

  return Math.round(value * multiplier) / multiplier;
};

const isoHoursAgo = (hours, now) => new Date(now.getTime() - hours * 60 * 60 * 1000).toISOString();

const isoDaysAgo = (days, now) => new Date(now.getTime() - days * 24 * 60 * 60 * 1000).toISOString();

export const createSampleReadings = (now = new Date()) => {
  const hourlyReadings = Array.from({ length: 24 }, (_, index) => {
    const hoursAgo = 23 - index;
    const wave = Math.sin(index / 2.8);
    const drift = Math.cos(index / 5);

    return [
      {
        id: `hr-${hoursAgo}`,
        type: 'heart_rate',
        value: Math.round(73 + wave * 9 + drift * 4),
        unit: 'bpm',
        recordedAt: isoHoursAgo(hoursAgo, now)
      },
      {
        id: `spo2-${hoursAgo}`,
        type: 'spo2',
        value: round(96.8 + Math.sin(index / 3.6) * 1.1, 1),
        unit: '%',
        recordedAt: isoHoursAgo(hoursAgo, now)
      }
    ];
  }).flat();

  const dailyReadings = Array.from({ length: 7 }, (_, index) => {
    const daysAgo = 6 - index;

    return [
      {
        id: `sleep-${daysAgo}`,
        type: 'sleep',
        value: round(6.4 + Math.sin(index / 1.5) * 0.8 + index * 0.08, 1),
        unit: 'hours',
        recordedAt: isoDaysAgo(daysAgo, now)
      },
      {
        id: `activity-${daysAgo}`,
        type: 'activity',
        value: Math.round(6500 + Math.cos(index / 1.7) * 1200 + index * 280),
        unit: 'steps',
        recordedAt: isoDaysAgo(daysAgo, now)
      }
    ];
  }).flat();

  return [...hourlyReadings, ...dailyReadings];
};

export const createDefaultAlerts = (now = new Date()) => [
  {
    id: 'sleep-quality-watch',
    type: 'sleep',
    severity: 'info',
    title: 'Sleep quality watch',
    message: 'Sleep recovery is slightly below your target for the week.',
    metricValue: 6.4,
    thresholdValue: defaultSettings.sleepTargetHours,
    status: 'active',
    createdAt: isoHoursAgo(6, now),
    resolvedAt: null
  }
];
