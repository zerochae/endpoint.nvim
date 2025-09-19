import express from 'express';
import { MessageResponse, ApiResponse, User } from './src/types';

const app = express();
const port = process.env.PORT || 3000;

// Root level app.ts routes (commonly found in many Express projects)
app.get<{}, MessageResponse>('/health', (_req, res) => {
  res.json({ message: 'Server is healthy' });
});

app.get<{}, ApiResponse<{ version: string }>>('/version', (_req, res) => {
  res.json({
    data: { version: '1.0.0' },
    success: true,
    message: 'Version info retrieved'
  });
});

app.post<{}, MessageResponse, { message: string }>('/ping', (req, res) => {
  const { message } = req.body;
  res.json({ message: `Pong: ${message}` });
});

// Start server
app.listen(port, () => {
  console.log(`Root app running on port ${port}`);
});

export default app;