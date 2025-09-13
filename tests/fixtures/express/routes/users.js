const express = require('express');
const router = express.Router();

// User management routes using router
router.get('/', (req, res) => {
  res.json({ users: [] });
});

router.get('/:id', (req, res) => {
  res.json({ user: { id: req.params.id } });
});

router.post('/', (req, res) => {
  res.status(201).json({ message: 'User created via router' });
});

router.put('/:id', (req, res) => {
  res.json({ message: 'User updated via router' });
});

router.delete('/:id', (req, res) => {
  res.json({ message: 'User deleted via router' });
});

router.patch('/:id/profile', (req, res) => {
  res.json({ message: 'User profile patched' });
});

// Nested route with complex path
router.get('/:id/posts/:postId/comments', (req, res) => {
  res.json({ 
    userId: req.params.id,
    postId: req.params.postId,
    comments: []
  });
});

module.exports = router;