const express = require('express');
const app = express();

// Destructured methods from app
const { get, post, put, delete: del, patch } = app;

// Using destructured methods
get('/', (req, res) => {
  res.json({ message: 'Home page via destructured get' });
});

post('/api/users', (req, res) => {
  res.status(201).json({ message: 'User created via destructured post' });
});

put('/api/users/:id', (req, res) => {
  res.json({ message: 'User updated via destructured put' });
});

// Using del alias for delete
del('/api/users/:id', (req, res) => {
  res.json({ message: 'User deleted via destructured del' });
});

patch('/api/users/:id/profile', (req, res) => {
  res.json({ message: 'User profile patched via destructured patch' });
});

// Complex path with destructured method
get('/api/v1/users/:userId/posts/:postId', (req, res) => {
  res.json({ 
    userId: req.params.userId,
    postId: req.params.postId 
  });
});

// Mixed usage - both destructured and regular
app.get('/regular', (req, res) => {
  res.json({ type: 'regular' });
});

get('/destructured', (req, res) => {
  res.json({ type: 'destructured' });
});

module.exports = app;