import { Router } from 'express';
import { MessageResponse, ApiResponse } from '../types';

const router = Router();

interface LoginRequest {
  email: string;
  password: string;
}

interface LoginResponse {
  token: string;
  user: {
    id: number;
    email: string;
    name: string;
  };
}

interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
}

// Authentication routes with TypeScript generics
router.post<{}, ApiResponse<LoginResponse>, LoginRequest>('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      data: null,
      success: false,
      message: 'Email and password are required'
    });
  }

  const loginResponse: LoginResponse = {
    token: 'jwt-token-here',
    user: {
      id: 1,
      email,
      name: 'Authenticated User'
    }
  };

  res.json({
    data: loginResponse,
    success: true,
    message: 'Login successful'
  });
});

router.post<{}, ApiResponse<{ user: any }>, RegisterRequest>('/register', (req, res) => {
  const { name, email, password, confirmPassword } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({
      data: null,
      success: false,
      message: 'Name, email, and password are required'
    });
  }

  if (password !== confirmPassword) {
    return res.status(400).json({
      data: null,
      success: false,
      message: 'Passwords do not match'
    });
  }

  const newUser = {
    id: Date.now(),
    name,
    email,
    createdAt: new Date()
  };

  res.status(201).json({
    data: { user: newUser },
    success: true,
    message: 'User registered successfully'
  });
});

router.post<{}, MessageResponse>('/logout', (_req, res) => {
  res.json({ message: 'Logout successful' });
});

router.get<{}, ApiResponse<{ user: any }>, {}, { includePermissions?: boolean }>('/me', (req, res) => {
  const { includePermissions } = req.query;

  const userData = {
    id: 1,
    name: 'Current User',
    email: 'current@example.com',
    ...(includePermissions && { permissions: ['read', 'write'] })
  };

  res.json({
    data: { user: userData },
    success: true,
    message: 'Current user data retrieved'
  });
});

router.put<{}, ApiResponse<MessageResponse>, { oldPassword: string; newPassword: string }>('/change-password', (req, res) => {
  const { oldPassword, newPassword } = req.body;

  if (!oldPassword || !newPassword) {
    return res.status(400).json({
      data: null,
      success: false,
      message: 'Old password and new password are required'
    });
  }

  res.json({
    data: { message: 'Password changed successfully' },
    success: true,
    message: 'Password update completed'
  });
});

router.post<{}, MessageResponse, { email: string }>('/forgot-password', (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  res.json({ message: 'Password reset email sent' });
});

export default router;