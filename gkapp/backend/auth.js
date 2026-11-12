const {
  createHash,
  createHmac,
  timingSafeEqual,
} = require('node:crypto');
const express = require('express');

const TOKEN_TTL_SECONDS = 8 * 60 * 60;

function safeEqual(first, second) {
  const firstHash = createHash('sha256').update(first).digest();
  const secondHash = createHash('sha256').update(second).digest();
  return timingSafeEqual(firstHash, secondHash);
}

function sign(value, secret) {
  return createHmac('sha256', secret).update(value).digest('base64url');
}

function createToken(username, secret, now = Date.now()) {
  const payload = Buffer.from(
    JSON.stringify({
      sub: username,
      exp: Math.floor(now / 1000) + TOKEN_TTL_SECONDS,
    }),
  ).toString('base64url');
  const signedValue = `v1.${payload}`;
  return `${signedValue}.${sign(signedValue, secret)}`;
}

function verifyToken(token, secret, now = Date.now()) {
  if (typeof token !== 'string') return null;
  const [version, payload, signature, extra] = token.split('.');
  if (version !== 'v1' || !payload || !signature || extra) return null;

  const signedValue = `${version}.${payload}`;
  if (!safeEqual(signature, sign(signedValue, secret))) return null;

  try {
    const data = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    if (
      typeof data.sub !== 'string' ||
      !Number.isInteger(data.exp) ||
      data.exp <= Math.floor(now / 1000)
    ) {
      return null;
    }
    return { username: data.sub, expiresAt: data.exp };
  } catch {
    return null;
  }
}

function createAuthRouter({ username, password, secret }) {
  if (
    typeof username !== 'string' ||
    !username ||
    typeof password !== 'string' ||
    !password ||
    typeof secret !== 'string' ||
    secret.length < 32
  ) {
    throw new Error(
      'Cần cấu hình AUTH_USERNAME, AUTH_PASSWORD và AUTH_TOKEN_SECRET (ít nhất 32 ký tự) trong backend/.env.',
    );
  }

  const router = express.Router();
  router.post('/login', (request, response) => {
    const { username: suppliedUsername, password: suppliedPassword } =
      request.body || {};
    if (
      typeof suppliedUsername !== 'string' ||
      typeof suppliedPassword !== 'string' ||
      suppliedUsername.length > 200 ||
      suppliedPassword.length > 1000
    ) {
      return response.status(400).json({ error: 'Thông tin đăng nhập không hợp lệ.' });
    }

    const validUsername = safeEqual(suppliedUsername, username);
    const validPassword = safeEqual(suppliedPassword, password);
    if (!(validUsername && validPassword)) {
      return response.status(401).json({ error: 'Tên đăng nhập hoặc mật khẩu không đúng.' });
    }

    response.json({
      token: createToken(username, secret),
      expiresIn: TOKEN_TTL_SECONDS,
    });
  });
  return router;
}

function createAuthMiddleware(secret) {
  if (typeof secret !== 'string' || secret.length < 32) {
    throw new Error('AUTH_TOKEN_SECRET phải có ít nhất 32 ký tự.');
  }

  return (request, response, next) => {
    const authorization = request.get('authorization') || '';
    const match = /^Bearer ([^\s]+)$/.exec(authorization);
    if (!match || !verifyToken(match[1], secret)) {
      return response.status(401).json({ error: 'Vui lòng đăng nhập lại.' });
    }
    next();
  };
}

module.exports = {
  TOKEN_TTL_SECONDS,
  createAuthMiddleware,
  createAuthRouter,
  createToken,
  verifyToken,
};
