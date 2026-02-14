import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Budget API
export const budgetAPI = {
  getAll: () => api.get('/budgets'),
  getById: (id) => api.get(`/budgets/${id}`),
  create: (data) => api.post('/budgets', data),
  update: (id, data) => api.put(`/budgets/${id}`, data),
  delete: (id) => api.delete(`/budgets/${id}`),
  getTransactions: (id) => api.get(`/budgets/${id}/transactions`),
  addTransaction: (id, data) => api.post(`/budgets/${id}/transactions`, data),
};

// Portfolio API
export const portfolioAPI = {
  getAll: () => api.get('/portfolios'),
  getById: (id) => api.get(`/portfolios/${id}`),
  create: (data) => api.post('/portfolios', data),
  update: (id, data) => api.put(`/portfolios/${id}`, data),
  delete: (id) => api.delete(`/portfolios/${id}`),
  getTransactions: (id) => api.get(`/portfolios/${id}/transactions`),
  addTransaction: (id, data) => api.post(`/portfolios/${id}/transactions`, data),
  getPerformance: (id) => api.get(`/portfolios/${id}/performance`),
};

// Stock API
export const stockAPI = {
  getQuote: (symbol) => api.get(`/stocks/quote/${symbol}`),
  search: (query) => api.get(`/stocks/search?q=${query}`),
  getTrending: () => api.get('/stocks/trending'),
  getQuotes: (symbols) => api.post('/stocks/quotes', { symbols }),
};

// User API
export const userAPI = {
  getProfile: () => api.get('/users/profile'),
  updateProfile: (data) => api.put('/users/profile', data),
  getPreferences: () => api.get('/users/preferences'),
  updatePreferences: (data) => api.put('/users/preferences', data),
};

// Auth API
export const authAPI = {
  register: (data) => api.post('/auth/register', data),
  login: (data) => api.post('/auth/login', data),
  logout: () => api.post('/auth/logout'),
};

export default api;
