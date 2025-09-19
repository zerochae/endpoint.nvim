export interface User {
  id: number;
  name: string;
  email: string;
  age?: number;
}

export interface CreateUserRequest {
  name: string;
  email: string;
  age?: number;
}

export interface UpdateUserRequest extends Partial<CreateUserRequest> {
  id: number;
}

export interface MessageResponse {
  message: string;
  timestamp?: Date;
}

export interface ErrorResponse {
  error: string;
  code: number;
  details?: string;
}

export interface ApiResponse<T = any> {
  data: T;
  success: boolean;
  message?: string;
}

export interface Post {
  id: number;
  title: string;
  content: string;
  authorId: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreatePostRequest {
  title: string;
  content: string;
  authorId: number;
}

export interface QueryParams {
  page?: number;
  limit?: number;
  sort?: string;
  order?: 'asc' | 'desc';
}