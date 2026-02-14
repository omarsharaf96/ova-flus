/**
 * User Model
 * Shared data structures for user management across all platforms
 */

class User {
  constructor(id, email, name, createdAt, preferences) {
    this.id = id;
    this.email = email;
    this.name = name;
    this.createdAt = createdAt || new Date();
    this.preferences = preferences || {
      currency: 'USD',
      theme: 'light',
      notifications: true,
      language: 'en'
    };
  }

  updatePreferences(newPreferences) {
    this.preferences = { ...this.preferences, ...newPreferences };
  }
}

class UserPreferences {
  constructor(currency, theme, notifications, language) {
    this.currency = currency || 'USD';
    this.theme = theme || 'light';
    this.notifications = notifications !== undefined ? notifications : true;
    this.language = language || 'en';
  }
}

module.exports = {
  User,
  UserPreferences
};
