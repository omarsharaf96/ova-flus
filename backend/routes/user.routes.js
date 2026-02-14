const express = require('express');
const router = express.Router();

/**
 * User Routes
 * Handles user profile and preferences
 */

// Mock data
let users = [
  {
    id: '1',
    email: 'demo@ovaflus.com',
    name: 'Demo User',
    createdAt: new Date('2024-01-01'),
    preferences: {
      currency: 'USD',
      theme: 'light',
      notifications: true,
      language: 'en'
    }
  }
];

// @route   GET /api/users/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', async (req, res) => {
  try {
    // Mock authenticated user ID
    const userId = '1';
    const user = users.find(u => u.id === userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching profile',
      error: error.message
    });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', async (req, res) => {
  try {
    const userId = '1';
    const index = users.findIndex(u => u.id === userId);
    
    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    users[index] = { ...users[index], ...req.body };
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: users[index]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message
    });
  }
});

// @route   GET /api/users/preferences
// @desc    Get user preferences
// @access  Private
router.get('/preferences', async (req, res) => {
  try {
    const userId = '1';
    const user = users.find(u => u.id === userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: user.preferences
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching preferences',
      error: error.message
    });
  }
});

// @route   PUT /api/users/preferences
// @desc    Update user preferences
// @access  Private
router.put('/preferences', async (req, res) => {
  try {
    const userId = '1';
    const user = users.find(u => u.id === userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    user.preferences = { ...user.preferences, ...req.body };
    
    res.json({
      success: true,
      message: 'Preferences updated successfully',
      data: user.preferences
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating preferences',
      error: error.message
    });
  }
});

module.exports = router;
