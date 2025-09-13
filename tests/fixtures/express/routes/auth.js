const express = require('express');
const router = express.Router();

// Authentication routes
router.post('/login', (req, res) => {
  res.json({ token: 'fake-jwt-token' });
});

router.post('/register', (req, res) => {
  res.status(201).json({ message: 'User registered' });
});

router.get('/profile', (req, res) => {
  res.json({ profile: {} });
});

router.put('/profile', (req, res) => {
  res.json({ message: 'Profile updated' });
});

router.post('/logout', (req, res) => {
  res.json({ message: 'Logged out' });
});

router.delete('/account', (req, res) => {
  res.json({ message: 'Account deleted' });
});

// Password management
router.post('/forgot-password', (req, res) => {
  res.json({ message: 'Password reset email sent' });
});

router.patch('/reset-password', (req, res) => {
  res.json({ message: 'Password reset successfully' });
});

module.exports = router;