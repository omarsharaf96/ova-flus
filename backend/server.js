const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
const authRoutes = require('./routes/auth.routes');
const budgetRoutes = require('./routes/budget.routes');
const portfolioRoutes = require('./routes/portfolio.routes');
const userRoutes = require('./routes/user.routes');
const stockRoutes = require('./routes/stock.routes');

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/portfolios', portfolioRoutes);
app.use('/api/users', userRoutes);
app.use('/api/stocks', stockRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'OVA FLUS Finance API'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to OVA FLUS Finance Management API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      budgets: '/api/budgets',
      portfolios: '/api/portfolios',
      users: '/api/users',
      stocks: '/api/stocks',
      health: '/health'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Internal Server Error',
      status: err.status || 500
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      message: 'Endpoint not found',
      status: 404
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 OVA FLUS Finance API running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
