import type { PushNotificationSettings } from './notification';

export interface User {
  id: string;
  email: string;
  displayName: string;
  avatar?: string;
  tier: 'free' | 'premium' | 'family';
  createdAt: Date;
  updatedAt: Date;
}

export interface UserSettings {
  userId: string;
  currency: string;
  locale: string;
  theme: 'light' | 'dark' | 'auto';
  notifications: PushNotificationSettings;
  biometricEnabled: boolean;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: Date;
}
