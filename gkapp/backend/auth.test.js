const assert = require('node:assert/strict');
const test = require('node:test');
const express = require('express');

const {
  TOKEN_TTL_SECONDS,
  createAuthMiddleware,
  createAuthRouter,
  createToken,
  verifyToken,
} = require('./auth');

const config = {
  username: 'admin',
  password: 'a long test password',
  secret: 'a test signing secret with more than 32 characters',
};

async function withAuthServer(run) {
  const app = express();
  app.use(express.json());
  app.use('/api/auth', createAuthRouter(config));
  app.get('/api/protected', createAuthMiddleware(config.secret), (_req, res) => {
    res.json({ ok: true });
  });

  const server = await new Promise((resolve) => {
    const listeningServer = app.listen(0, '127.0.0.1', () =>
      resolve(listeningServer),
    );
  });
  try {
    await run(`http://127.0.0.1:${server.address().port}`);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
}

test('login returns a signed token without writing credentials to a database', async () => {
  await withAuthServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: config.username,
        password: config.password,
      }),
    });
    const result = await response.json();

    assert.equal(response.status, 200);
    assert.equal(result.expiresIn, TOKEN_TTL_SECONDS);
    assert.equal(verifyToken(result.token, config.secret)?.username, 'admin');
  });
});

test('login rejects invalid credentials', async () => {
  await withAuthServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'admin', password: 'wrong' }),
    });

    assert.equal(response.status, 401);
    assert.deepEqual(await response.json(), {
      error: 'Tên đăng nhập hoặc mật khẩu không đúng.',
    });
  });
});

test('protected API rejects missing and invalid tokens', async () => {
  await withAuthServer(async (baseUrl) => {
    for (const token of [null, 'invalid']) {
      const response = await fetch(`${baseUrl}/api/protected`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      assert.equal(response.status, 401);
    }
  });
});

test('protected API accepts valid tokens and rejects expired tokens', async () => {
  const token = createToken('admin', config.secret);
  const expiredToken = createToken('admin', config.secret, 0);

  await withAuthServer(async (baseUrl) => {
    const validResponse = await fetch(`${baseUrl}/api/protected`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    assert.equal(validResponse.status, 200);
    assert.deepEqual(await validResponse.json(), { ok: true });

    const expiredResponse = await fetch(`${baseUrl}/api/protected`, {
      headers: { Authorization: `Bearer ${expiredToken}` },
    });
    assert.equal(expiredResponse.status, 401);
  });
});

test('server refuses to start without configured credentials and signing secret', () => {
  assert.throws(
    () => createAuthRouter({ username: '', password: '', secret: '' }),
    /AUTH_USERNAME/,
  );
  assert.throws(
    () => createAuthMiddleware('too short'),
    /AUTH_TOKEN_SECRET/,
  );
});
