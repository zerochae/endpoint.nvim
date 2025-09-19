import express from 'express';
import { MessageResponse, ApiResponse, User } from './types';

// Destructured routing patterns with TypeScript generics
const { get, post, put, delete: del, patch } = express.Router();

// Basic destructured routes with generics
get<{}, MessageResponse>('/destructured', (_req, res) => {
  res.json({ message: 'Destructured GET route with TypeScript' });
});

post<{}, ApiResponse<{ id: number }>, { name: string }>('/destructured', (req, res) => {
  const { name } = req.body;
  res.status(201).json({
    data: { id: Date.now() },
    success: true,
    message: `Created with name: ${name}`
  });
});

put<{ id: string }, MessageResponse, { name: string }>('/destructured/:id', (req, res) => {
  const { id } = req.params;
  const { name } = req.body;
  res.json({ message: `Updated ${id} with name: ${name}` });
});

del<{ id: string }, MessageResponse>('/destructured/:id', (req, res) => {
  const { id } = req.params;
  res.json({ message: `Deleted item ${id}` });
});

patch<{ id: string }, ApiResponse<User>, Partial<User>>('/destructured/:id', (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  const updatedUser: User = {
    id: parseInt(id),
    name: updateData.name || 'Default',
    email: updateData.email || 'default@example.com',
    ...updateData
  };

  res.json({
    data: updatedUser,
    success: true,
    message: 'User patched via destructured route'
  });
});

// More complex destructured patterns
get<
  { category: string; id: string },
  ApiResponse<any>,
  {},
  { include?: string; format?: 'json' | 'xml' }
>('/destructured/:category/:id', (req, res) => {
  const { category, id } = req.params;
  const { include, format } = req.query;

  res.json({
    data: { category, id, include, format },
    success: true,
    message: 'Complex destructured route with generics'
  });
});

export { get, post, put, del as delete, patch };