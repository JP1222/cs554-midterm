'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { once } = require('node:events');
const { createServer } = require('../src/server');

test('one instance becomes unready and recovers without stopping or losing its counter', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'midterm-readiness-'));
  const marker = path.join(dir, 'not-ready');
  const server = createServer({ readinessBlockFile: marker });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const base = 'http://127.0.0.1:' + server.address().port;
  try {
    assert.equal((await fetch(base + '/health')).status, 200);
    assert.equal((await (await fetch(base + '/')).json()).requestCount, 1);
    fs.writeFileSync(marker, 'controlled failure');
    const unavailable = await fetch(base + '/health');
    assert.equal(unavailable.status, 503);
    assert.deepEqual(await unavailable.json(), { status: 'not-ready' });
    assert.equal((await (await fetch(base + '/')).json()).requestCount, 2);
    fs.unlinkSync(marker);
    assert.equal((await fetch(base + '/health')).status, 200);
    assert.equal((await (await fetch(base + '/')).json()).requestCount, 3);
  } finally {
    await new Promise(resolve => server.close(resolve));
    fs.rmSync(dir, { recursive: true, force: true });
  }
});
