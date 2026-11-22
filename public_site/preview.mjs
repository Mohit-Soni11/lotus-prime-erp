import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, sep, extname } from 'node:path';

const root = fileURLToPath(new URL('./site/', import.meta.url));
const config = JSON.parse(await readFile(new URL('./firebase.json', import.meta.url), 'utf8'));
const headers = Object.fromEntries(config.hosting.headers[0].headers.map(({ key, value }) => [key, value]));
const port = Number(process.argv[2] ?? 8788);
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Choose a valid preview port.');

createServer(async (request, response) => {
  try {
    if (!['GET', 'HEAD'].includes(request.method)) {
      response.writeHead(405, { ...headers, Allow: 'GET, HEAD' }).end();
      return;
    }
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const target = resolve(root, `.${pathname === '/' ? '/index.html' : pathname}`);
    if (!target.startsWith(resolve(root) + sep)) {
      response.writeHead(403, headers).end('Forbidden');
      return;
    }
    const data = await readFile(target);
    const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8' };
    response.writeHead(200, { ...headers, 'Content-Type': types[extname(target)] ?? 'application/octet-stream' });
    response.end(request.method === 'HEAD' ? undefined : data);
  } catch {
    response.writeHead(404, headers).end('Not found');
  }
}).listen(port, '127.0.0.1', () => {
  console.log(`Lotus ERP public pages preview: http://127.0.0.1:${port}`);
});
