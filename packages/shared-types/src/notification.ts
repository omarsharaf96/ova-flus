export enum NotificationType {
  BUDGET_ALERT = 'BUDGET_ALERT',
  BUDGET_EXCEEDED = 'BUDGET_EXCEEDED',
  STOCK_PRICE_ALERT = 'STOCK_PRICE_ALERT',
  MARKET_NEWS = 'MARKET_NEWS',
  BILL_REMINDER = 'BILL_REMINDER',
  WEEKLY_SUMMARY = 'WEEKLY_SUMMARY',
  MONTHLY_SUMMARY = 'MONTHLY_SUMMARY',
  SYSTEM = 'SYSTEM',
}

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  read: boolean;
  createdAt: Date;
}

export interface PushNotificationSettings {
  budgetAlerts: boolean;
  stockAlerts: boolean;
  billReminders: boolean;
  weeklySummary: boolean;
  monthlySummary: boolean;
}
