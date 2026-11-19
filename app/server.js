'use strict';
const http = require('http');

const VERSION = process.env.APP_VERSION || '1.0.0';
const BUILD_ID = process.env.BUILD_ID || 'local';

function handler(req, res) {
  const send = (status, body, type = 'application/json') => {
    res.writeHead(status, { 'Content-Type': type, 'X-Content-Type-Options': 'nosniff' });
    res.end(type === 'application/json' ? JSON.stringify(body) : body);
  };
  if (req.method !== 'GET') return send(405, { error: 'method not allowed' });
  const path = new URL(req.url, 'http://localhost').pathname;
  switch (path) {
    case '/':
      return send(200, '<!doctype html><title>CodeAlpha Azure CI/CD</title>' +
        '<h1>Deployed by Azure Pipelines</h1><p>Version ' + VERSION + ' · build ' +
        BUILD_ID.replace(/[^\w.-]/g, '') + '</p>', 'text/html; charset=utf-8');
    case '/health':
      return send(200, { status: 'UP' });
    case '/api/info':
      return send(200, { name: 'codealpha-azure-cicd', version: VERSION, build: BUILD_ID, uptimeSeconds: Math.round(process.uptime()) });
    default:
      return send(404, { error: 'not found' });
  }
}

const server = http.createServer(handler);

if (require.main === module) {
  const port = Number(process.env.PORT || process.env.WEBSITES_PORT || 8080);
  server.listen(port, () => console.log(`listening on ${port}`));
  process.on('SIGTERM', () => server.close(() => process.exit(0)));
}

module.exports = { server, handler };
