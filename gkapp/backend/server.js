require('dotenv').config();

const cors = require('cors');
const express = require('express');
const { createAuthMiddleware, createAuthRouter } = require('./auth');
const {
  closeDatabase,
  connectDatabase,
} = require('./db');
const { router: lecturerRoutes } = require('./lecturer-routes');

const app = express();
const port = Number(process.env.PORT || 3000);
const allowedOrigin = process.env.CORS_ORIGIN || '*';

app.use(cors({ origin: allowedOrigin === '*' ? true : allowedOrigin }));
app.use(express.json({ limit: '7mb' }));

app.get('/api/health', (_request, response) => {
  response.json({ status: 'ok' });
});
app.use(
  '/api/auth',
  createAuthRouter({
    username: process.env.AUTH_USERNAME,
    password: process.env.AUTH_PASSWORD,
    secret: process.env.AUTH_TOKEN_SECRET,
  }),
);
app.use(
  '/api/lecturers',
  createAuthMiddleware(process.env.AUTH_TOKEN_SECRET),
  lecturerRoutes,
);

app.use((error, _request, response, _next) => {
  if (error.type === 'entity.too.large') {
    return response.status(413).json({ error: 'Ảnh vượt quá dung lượng cho phép.' });
  }
  if (error instanceof SyntaxError && 'body' in error) {
    return response.status(400).json({ error: 'JSON không hợp lệ.' });
  }
  console.error(error);
  response.status(500).json({ error: 'Lỗi máy chủ. Vui lòng thử lại.' });
});

async function start() {
  await connectDatabase();
  const server = app.listen(port, () => {
    console.log(`API đang chạy tại http://localhost:${port}`);
  });

  const shutdown = async () => {
    server.close(async () => {
      await closeDatabase();
      process.exit(0);
    });
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

start().catch(async (error) => {
  console.error(`Không thể khởi động API: ${error.message}`);
  await closeDatabase();
  process.exitCode = 1;
});
