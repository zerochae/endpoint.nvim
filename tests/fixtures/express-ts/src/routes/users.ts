import { Router, Request, Response } from 'express';
import { User, CreateUserRequest, ApiResponse, MessageResponse } from '../types';

const router = Router();

// Users router with TypeScript generics
router.get<{}, ApiResponse<User[]>>('/', (_req, res) => {
  const users: User[] = [
    { id: 1, name: 'Alice', email: 'alice@example.com', age: 28 },
    { id: 2, name: 'Bob', email: 'bob@example.com', age: 32 }
  ];

  res.json({
    data: users,
    success: true,
    message: 'Users from router retrieved successfully'
  });
});

router.get<{ id: string }, ApiResponse<User> | MessageResponse>('/:id', (req, res) => {
  const id = parseInt(req.params.id);

  if (isNaN(id) || id <= 0) {
    return res.status(400).json({ message: 'Invalid user ID format' });
  }

  const user: User = {
    id,
    name: 'Router User',
    email: 'router@example.com',
    age: 25
  };

  res.json({
    data: user,
    success: true,
    message: 'User from router retrieved successfully'
  });
});

router.post<{}, ApiResponse<User>, CreateUserRequest>('/', (req, res) => {
  const { name, email, age } = req.body;

  if (!name || !email) {
    return res.status(400).json({
      data: null,
      success: false,
      message: 'Name and email are required'
    });
  }

  const newUser: User = {
    id: Date.now(),
    name,
    email,
    age
  };

  res.status(201).json({
    data: newUser,
    success: true,
    message: 'User created via router successfully'
  });
});

router.put<{ id: string }, ApiResponse<User>, Partial<User>>('/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const updateData = req.body;

  const updatedUser: User = {
    id,
    name: updateData.name || 'Default Name',
    email: updateData.email || 'default@example.com',
    age: updateData.age
  };

  res.json({
    data: updatedUser,
    success: true,
    message: 'User updated via router successfully'
  });
});

router.delete<{ id: string }, MessageResponse>('/:id', (req, res) => {
  const id = req.params.id;
  res.json({ message: `User ${id} deleted via router successfully` });
});

router.patch<{ id: string }, ApiResponse<Partial<User>>, Partial<User>>('/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const patchData = req.body;

  res.json({
    data: { id, ...patchData },
    success: true,
    message: 'User patched via router successfully'
  });
});

// Nested route with complex generics
router.get<
  { id: string; action: string },
  ApiResponse<{ user: User; action: string }>,
  {},
  { details?: boolean }
>('/:id/:action', (req, res) => {
  const { id, action } = req.params;
  const { details } = req.query;

  res.json({
    data: {
      user: { id: parseInt(id), name: 'Action User', email: 'action@example.com' },
      action: action
    },
    success: true,
    message: `User ${action} action performed${details ? ' with details' : ''}`
  });
});

export default router;