const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Express API' });
});

// Basic CRUD routes for users
app.get('/users', (req, res) => {
  res.json({ users: [] });
});

app.get('/users/:id', (req, res) => {
  res.json({ user: { id: req.params.id } });
});

app.post('/users', (req, res) => {
  res.status(201).json({ message: 'User created' });
});

app.put('/users/:id', (req, res) => {
  res.json({ message: 'User updated' });
});

app.delete('/users/:id', (req, res) => {
  res.json({ message: 'User deleted' });
});

app.patch('/users/:id', (req, res) => {
  res.json({ message: 'User patched' });
});

// API routes
app.get('/api/v1/posts', (req, res) => {
  res.json({ posts: [] });
});

app.post('/api/v1/posts', (req, res) => {
  res.status(201).json({ message: 'Post created' });
});

// Complex path with multiple parameters
app.get('/api/v1/users/:userId/posts/:postId', (req, res) => {
  res.json({ 
    userId: req.params.userId,
    postId: req.params.postId 
  });
});

// Route with query parameters
app.get('/api/search', (req, res) => {
  res.json({ query: req.query });
});

// Import route modules
const userRoutes = require('./routes/users');
const authRoutes = require('./routes/auth');

// Use route modules
app.use('/api/users', userRoutes);
app.use('/auth', authRoutes);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

module.exports = app;