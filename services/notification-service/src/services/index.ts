// TODO: Integrate with AWS SNS for push notifications and SES for email
// SNS topics: budget-alerts, price-alerts, general-notifications
// SES: transactional emails (welcome, password reset, weekly digest)

interface ListOptions {
  page: number;
  limit: number;
  unreadOnly: boolean;
}

export const notificationService = {
  async list(userId: string, options: ListOptions) {
    // TODO: SELECT notifications for user with pagination
    throw new Error('Not implemented');
  },

  async markRead(userId: string, notificationId: string) {
    // TODO: UPDATE notification SET read = true
    throw new Error('Not implemented');
  },

  async markAllRead(userId: string) {
    // TODO: UPDATE all unread notifications for user
    throw new Error('Not implemented');
  },

  async getPreferences(userId: string) {
    // TODO: SELECT notification preferences for user
    throw new Error('Not implemented');
  },

  async updatePreferences(userId: string, prefs: Record<string, unknown>) {
    // TODO: UPSERT notification preferences
    // Preferences: push enabled, email enabled, quiet hours, per-type settings
    throw new Error('Not implemented');
  },

  async createBudgetAlert(userId: string, data: { budgetId: string; threshold: number }) {
    // TODO: Create budget alert rule
    // When spending exceeds threshold %, trigger SNS notification
    throw new Error('Not implemented');
  },

  async createStockPriceAlert(
    userId: string,
    data: { symbol: string; targetPrice: number; direction: 'above' | 'below' },
  ) {
    // TODO: Create stock price alert rule
    // Monitor via market-data-service, trigger SNS when price crosses target
    throw new Error('Not implemented');
  },

  async listAlerts(userId: string) {
    // TODO: SELECT alert rules for user
    throw new Error('Not implemented');
  },

  async removeAlert(userId: string, alertId: string) {
    // TODO: DELETE alert rule
    throw new Error('Not implemented');
  },

  async sendPushNotification(userId: string, title: string, body: string) {
    // TODO: Publish to SNS topic for push delivery (APNs, FCM, Web Push)
    throw new Error('Not implemented');
  },

  async sendEmail(userId: string, subject: string, htmlBody: string) {
    // TODO: Send email via AWS SES
    throw new Error('Not implemented');
  },
};
