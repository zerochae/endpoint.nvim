import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import {
  User,
  CreateUserRequest,
  UpdateUserRequest,
  MessageResponse,
  ApiResponse,
  QueryParams
} from './types';

// Test types for complex nested generics
type FooType = { id: string };
type BarType = { message: string };
type RequestType<T, U> = { data: T; meta: U };
type ResponseType<T> = { result: T };

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());

// Root route with TypeScript generics
app.get<{}, MessageResponse>('/', (_req, res) => {
  res.json({ message: 'Welcome to Express TypeScript API', timestamp: new Date() });
});

// Users routes with TypeScript generics and types
app.get<{}, ApiResponse<User[]>>('/users', (_req, res) => {
  const users: User[] = [
    { id: 1, name: 'John Doe', email: 'john@example.com', age: 30 },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com', age: 25 }
  ];
  res.json({
    data: users,
    success: true,
    message: 'Users retrieved successfully'
  });
});

app.get<{ id: string }, ApiResponse<User> | MessageResponse>('/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const user: User = { id, name: 'John Doe', email: 'john@example.com', age: 30 };

  if (id <= 0) {
    return res.status(400).json({ message: 'Invalid user ID' });
  }

  res.json({
    data: user,
    success: true,
    message: 'User retrieved successfully'
  });
});

app.post<{}, ApiResponse<User>, CreateUserRequest>('/users', (req, res) => {
  const { name, email, age } = req.body;
  const newUser: User = {
    id: Date.now(),
    name,
    email,
    age
  };

  res.status(201).json({
    data: newUser,
    success: true,
    message: 'User created successfully'
  });
});

app.put<{ id: string }, ApiResponse<User>, UpdateUserRequest>('/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const updatedUser: User = {
    id,
    name: req.body.name || 'Updated User',
    email: req.body.email || 'updated@example.com',
    age: req.body.age
  };

  res.json({
    data: updatedUser,
    success: true,
    message: 'User updated successfully'
  });
});

app.delete<{ id: string }, MessageResponse>('/users/:id', (req, res) => {
  const id = req.params.id;
  res.json({ message: `User ${id} deleted successfully` });
});

app.patch<{ id: string }, ApiResponse<Partial<User>>, Partial<UpdateUserRequest>>('/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const patchedFields = req.body;

  res.json({
    data: { id, ...patchedFields },
    success: true,
    message: 'User partially updated'
  });
});

// API routes with complex generics
app.get<{}, ApiResponse<any[]>, {}, QueryParams>('/api/v1/posts', (req, res) => {
  const { page = 1, limit = 10, sort = 'createdAt', order = 'desc' } = req.query;

  res.json({
    data: [],
    success: true,
    message: `Posts retrieved: page ${page}, limit ${limit}, sorted by ${sort} ${order}`
  });
});

app.post<{}, ApiResponse<any>, { title: string; content: string }>('/api/v1/posts', (req, res) => {
  const { title, content } = req.body;
  const newPost = {
    id: Date.now(),
    title,
    content,
    authorId: 1,
    createdAt: new Date(),
    updatedAt: new Date()
  };

  res.status(201).json({
    data: newPost,
    success: true,
    message: 'Post created successfully'
  });
});

// Complex nested path with generics
app.get<
  { userId: string; postId: string },
  ApiResponse<{ user: User; post: any }>,
  {},
  QueryParams
>('/api/v1/users/:userId/posts/:postId', (req, res) => {
  const { userId, postId } = req.params;

  res.json({
    data: {
      user: { id: parseInt(userId), name: 'John', email: 'john@example.com' },
      post: { id: parseInt(postId), title: 'Sample Post', content: 'Content' }
    },
    success: true,
    message: 'User post retrieved successfully'
  });
});

// Search route with generics
app.get<{}, ApiResponse<any[]>, {}, { q?: string; category?: string }>('/api/search', (req, res) => {
  const { q, category } = req.query;
  res.json({
    data: [],
    success: true,
    message: `Search results for query: ${q}, category: ${category}`
  });
});

// Complex nested generics test cases
app.get<
  FooType,
  BarType
>('/complex-nested', (req, res) => {
  res.json({ message: 'Complex nested generics' });
});

app.post<
  RequestType<string, number>,
  ResponseType<ApiResponse<User[]>>
>('/super-complex', (req, res) => {
  res.json({ data: [], success: true });
});

// Edge case: deeply nested generics with multiple < > pairs
app.put<
  Record<string, Map<number, Set<Promise<Array<User>>>>>,
  Promise<ApiResponse<Record<string, Array<{ id: number; data: Map<string, any> }>>>>
>('/extreme-nesting', (req, res) => {
  res.json({ data: {}, success: true });
});

// Import route modules
import userRoutes from './routes/users';
import authRoutes from './routes/auth';

// Use route modules
app.use('/api/users', userRoutes);
app.use('/auth', authRoutes);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

export default app;
