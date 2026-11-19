'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { server } = require('../app/server');

let base;
test.before(() => new Promise((resolve) => server.listen(0, () => {
  base = `http://127.0.0.1:${server.address().port}`;
  resolve();
})));
test.after(() => new Promise((resolve) => server.close(resolve)));

test('GET /health returns UP', async () => {
  const r = await fetch(`${base}/health`);
  assert.equal(r.status, 200);
  assert.deepEqual(await r.json(), { status: 'UP' });
});

test('GET /api/info returns name and version', async () => {
  const body = await (await fetch(`${base}/api/info`)).json();
  assert.equal(body.name, 'codealpha-azure-cicd');
  assert.ok(body.version);
});

test('GET / returns HTML', async () => {
  const r = await fetch(`${base}/`);
  assert.match(r.headers.get('content-type'), /text\/html/);
});

test('unknown path is 404 and POST is 405', async () => {
  assert.equal((await fetch(`${base}/nope`)).status, 404);
  assert.equal((await fetch(`${base}/health`, { method: 'POST' })).status, 405);
});
