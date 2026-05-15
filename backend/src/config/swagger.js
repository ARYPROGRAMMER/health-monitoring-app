export const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Stealthera Health Monitoring API',
      description: 'REST API for health data synchronization, profile management, and alert handling. All endpoints require Firebase authentication.',
      version: '1.0.0',
      contact: {
        name: 'Stealthera Support'
      }
    },
    servers: [
      {
        url: 'https://health-monitoring-app-hhiu.onrender.com',
        description: 'Production Server'
      },
      {
        url: 'http://localhost:3000',
        description: 'Development Server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Firebase Authentication Token. Obtain from Firebase ID token after sign-in.'
        }
      },
      schemas: {
        Profile: {
          type: 'object',
          properties: {
            uid: { type: 'string', description: 'Firebase user ID' },
            email: { type: 'string', format: 'email' },
            displayName: { type: 'string' },
            age: { type: 'integer', minimum: 1, maximum: 120 },
            sex: { type: 'string', enum: ['female', 'male', 'non_binary', 'not_specified'] },
            photoUrl: { type: 'string', format: 'uri' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
          }
        },
        Settings: {
          type: 'object',
          properties: {
            heartRateMin: { type: 'integer', minimum: 30, maximum: 100, default: 50 },
            heartRateMax: { type: 'integer', minimum: 80, maximum: 220, default: 120 },
            spo2Min: { type: 'number', minimum: 80, maximum: 100, default: 94 },
            dailyStepsGoal: { type: 'integer', minimum: 1000, maximum: 50000, default: 8000 },
            sleepTargetHours: { type: 'number', minimum: 4, maximum: 12, default: 7.5 },
            notificationsEnabled: { type: 'boolean', default: true },
            darkMode: { type: 'boolean', default: false }
          }
        },
        HealthReading: {
          type: 'object',
          required: ['type', 'value', 'unit'],
          properties: {
            id: { type: 'string', description: 'Optional unique reading ID' },
            type: { type: 'string', enum: ['heart_rate', 'spo2', 'sleep', 'activity'] },
            value: { type: 'number', description: 'Reading value' },
            unit: { type: 'string', example: 'bpm' },
            recordedAt: { type: 'string', format: 'date-time', description: 'ISO 8601 timestamp. Defaults to current time if omitted.' }
          },
          example: {
            type: 'heart_rate',
            value: 72,
            unit: 'bpm',
            recordedAt: '2026-05-16T14:30:00.000Z'
          }
        },
        Alert: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            type: { type: 'string', enum: ['heart_rate', 'spo2', 'activity', 'sleep'] },
            severity: { type: 'string', enum: ['low', 'medium', 'high'] },
            message: { type: 'string' },
            status: { type: 'string', enum: ['active', 'resolved'] },
            reading: { $ref: '#/components/schemas/HealthReading' },
            createdAt: { type: 'string', format: 'date-time' },
            resolvedAt: { type: 'string', format: 'date-time', nullable: true }
          }
        },
        Dashboard: {
          type: 'object',
          properties: {
            profile: { $ref: '#/components/schemas/Profile' },
            settings: { $ref: '#/components/schemas/Settings' },
            vitals: {
              type: 'object',
              properties: {
                lastHeartRate: { type: 'number' },
                lastSpo2: { type: 'number' },
                todaySteps: { type: 'integer' },
                lastSleep: { type: 'number' }
              }
            },
            activeAlerts: { type: 'array', items: { $ref: '#/components/schemas/Alert' } }
          }
        },
        SyncPayload: {
          type: 'object',
          description: 'Batch sync payload for profile updates, settings, and health readings',
          properties: {
            profile: {
              type: 'object',
              properties: {
                displayName: { type: 'string', minLength: 2, maxLength: 80 },
                age: { type: 'integer', minimum: 1, maximum: 120 },
                sex: { type: 'string', enum: ['female', 'male', 'non_binary', 'not_specified'] }
              }
            },
            settings: { $ref: '#/components/schemas/Settings' },
            readings: {
              type: 'array',
              items: { $ref: '#/components/schemas/HealthReading' },
              maxItems: 200
            }
          },
          example: {
            profile: { displayName: 'John Doe', age: 30 },
            settings: { heartRateMin: 55, heartRateMax: 130 },
            readings: [
              {
                type: 'heart_rate',
                value: 75,
                unit: 'bpm',
                recordedAt: '2026-05-16T14:30:00.000Z'
              }
            ]
          }
        },
        ApiResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: { type: 'object' },
            timestamp: { type: 'string', format: 'date-time' }
          }
        },
        Error: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            message: { type: 'string' },
            code: { type: 'string' },
            details: { type: 'object' },
            timestamp: { type: 'string', format: 'date-time' }
          }
        }
      },
      responses: {
        Unauthorized: {
          description: 'Unauthorized - Missing or invalid authentication token',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        },
        NotFound: {
          description: 'Resource not found',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        },
        BadRequest: {
          description: 'Bad request - Validation error',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        }
      }
    },
    security: [{ bearerAuth: [] }],
    paths: {
      '/healthz': {
        get: {
          tags: ['Health'],
          summary: 'Health check endpoint',
          security: [],
          responses: {
            '200': {
              description: 'Backend is healthy'
            }
          }
        }
      },
      '/api/health/dashboard': {
        get: {
          tags: ['Health'],
          summary: 'Get dashboard data',
          description: 'Retrieves complete dashboard data including profile, settings, vitals, and active alerts',
          responses: {
            '200': {
              description: 'Dashboard loaded successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/health/vitals': {
        get: {
          tags: ['Health'],
          summary: 'Get vital signs',
          description: 'Retrieves latest vital signs (heart rate, SpO2, steps, sleep)',
          responses: {
            '200': {
              description: 'Vitals loaded successfully'
            },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/health/trends': {
        get: {
          tags: ['Health'],
          summary: 'Get health trends',
          description: 'Retrieves health trends over time',
          responses: {
            '200': {
              description: 'Trends loaded successfully'
            },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/health/sync': {
        post: {
          tags: ['Health'],
          summary: 'Sync health data',
          description: 'Upload health readings, update profile, and sync settings in a single batch request. Perfect for manual data entry or device synchronization.',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/SyncPayload' }
              }
            }
          },
          responses: {
            '200': {
              description: 'Health data synced successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '400': { $ref: '#/components/responses/BadRequest' },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/profile': {
        get: {
          tags: ['Profile'],
          summary: 'Get user profile',
          responses: {
            '200': {
              description: 'Profile loaded successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        },
        put: {
          tags: ['Profile'],
          summary: 'Update user profile',
          description: 'Update display name, age, or sex. All fields are optional.',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    displayName: { type: 'string', minLength: 2, maxLength: 80 },
                    age: { type: 'integer', minimum: 1, maximum: 120 },
                    sex: { type: 'string', enum: ['female', 'male', 'non_binary', 'not_specified'] }
                  }
                }
              }
            }
          },
          responses: {
            '200': {
              description: 'Profile updated successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '400': { $ref: '#/components/responses/BadRequest' },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/settings': {
        get: {
          tags: ['Settings'],
          summary: 'Get user settings',
          responses: {
            '200': {
              description: 'Settings loaded successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        },
        put: {
          tags: ['Settings'],
          summary: 'Update user settings',
          description: 'Update health thresholds, goals, and preferences. All fields are optional.',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Settings' }
              }
            }
          },
          responses: {
            '200': {
              description: 'Settings updated successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '400': { $ref: '#/components/responses/BadRequest' },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/alerts': {
        get: {
          tags: ['Alerts'],
          summary: 'Get all alerts',
          responses: {
            '200': {
              description: 'Alerts loaded successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '401': { $ref: '#/components/responses/Unauthorized' }
          }
        }
      },
      '/api/alerts/{alertId}': {
        patch: {
          tags: ['Alerts'],
          summary: 'Update alert status',
          description: 'Resolve or reactivate an alert',
          parameters: [
            {
              name: 'alertId',
              in: 'path',
              required: true,
              schema: { type: 'string' }
            }
          ],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['status'],
                  properties: {
                    status: { type: 'string', enum: ['active', 'resolved'] }
                  }
                }
              }
            }
          },
          responses: {
            '200': {
              description: 'Alert updated successfully',
              content: {
                'application/json': {
                  schema: { $ref: '#/components/schemas/ApiResponse' }
                }
              }
            },
            '400': { $ref: '#/components/responses/BadRequest' },
            '401': { $ref: '#/components/responses/Unauthorized' },
            '404': { $ref: '#/components/responses/NotFound' }
          }
        }
      }
    }
  },
  apis: []
};
