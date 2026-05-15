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
    age: null,
    sex: 'not_specified',
    createdAt: timestamp,
    updatedAt: timestamp
  };
};
