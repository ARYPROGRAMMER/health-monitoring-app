import { z } from 'zod';

export const profileUpdateSchema = z.object({
  displayName: z.string().trim().min(2).max(80).optional(),
  age: z.number().int().min(1).max(120).optional(),
  sex: z.enum(['female', 'male', 'non_binary', 'not_specified']).optional()
}).strict();

export const settingsUpdateSchema = z.object({
  heartRateMin: z.number().int().min(30).max(100).optional(),
  heartRateMax: z.number().int().min(80).max(220).optional(),
  spo2Min: z.number().min(80).max(100).optional(),
  dailyStepsGoal: z.number().int().min(1000).max(50000).optional(),
  sleepTargetHours: z.number().min(4).max(12).optional(),
  notificationsEnabled: z.boolean().optional(),
  darkMode: z.boolean().optional()
}).strict();

export const readingSchema = z.object({
  id: z.string().trim().min(3).max(120).optional(),
  type: z.enum(['heart_rate', 'spo2', 'sleep', 'activity']),
  value: z.number().finite(),
  unit: z.string().trim().min(1).max(16),
  recordedAt: z.string().datetime().optional()
}).strict();

export const syncPayloadSchema = z.object({
  profile: profileUpdateSchema.optional(),
  settings: settingsUpdateSchema.optional(),
  readings: z.array(readingSchema).max(200).default([])
}).strict();

export const alertStatusSchema = z.object({
  status: z.enum(['active', 'resolved'])
}).strict();
