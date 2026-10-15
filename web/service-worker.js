const VERSION = '__VERSION__';
const FILES = __FILES__;
const PREFIX = 'robot-defense-pwa-';
const CACHE = PREFIX + VERSION;
const ENTRY = new URL('index.html', self.registration.scope).href;

function owned(name) {
  return name.startsWith(PREFIX) || name.startsWith('Robot Defense-sw-cache-');
}

function clientVersion(client) {
  return new Promise((resolve) => {
    const channel = new MessageChannel();
    const timeout = setTimeout(() => {
      channel.port1.close();
      resolve(null);
    }, 1500);
    channel.port1.onmessage = (event) => {
      clearTimeout(timeout);
      channel.port1.close();
      resolve(event.data.version || null);
    };
    client.postMessage({type: 'GET_CLIENT_VERSION'}, [channel.port2]);
  });
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    try {
      const response = await fetch(new Request(ENTRY, {cache: 'no-store'}));
      if (!response.ok || !(await response.clone().text()).includes(`data-build="${VERSION}"`)) throw new Error('Build changed during update');
      await cache.put(ENTRY, response);
      await cache.addAll(FILES.filter((file) => file !== 'index.html').map((file) => new Request(new URL(file, self.registration.scope), {cache: 'reload'})));
      await self.skipWaiting();
    } catch (error) {
      await caches.delete(CACHE);
      throw error;
    }
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = (await caches.keys()).filter((name) => name.startsWith(PREFIX) && name !== CACHE);
    await Promise.all(keys.slice(0, -1).map((name) => caches.delete(name)));
    await self.clients.claim();
    for (const client of await self.clients.matchAll({type: 'window'})) {
      if (!client.url.startsWith(self.registration.scope)) continue;
      const currentVersion = await clientVersion(client);
      if (currentVersion === null) await client.navigate(client.url);
      else client.postMessage({type: 'UPDATE_READY', version: VERSION});
    }
  })());
});

async function cachedResource(request) {
  const names = [CACHE, ...(await caches.keys()).filter((name) => name !== CACHE && owned(name)).reverse()];
  for (const name of names) {
    const response = await (await caches.open(name)).match(request);
    if (response) return response;
  }
  return undefined;
}

async function navigate(request) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 4000);
  try {
    const response = await fetch(new Request(request, {cache: 'no-store', signal: controller.signal}));
    if (response.ok) return response;
  } catch {
  } finally {
    clearTimeout(timeout);
  }
  const cached = await cachedResource(ENTRY);
  return cached || new Response('Kết nối mạng để tải game lần đầu.', {status: 503, headers: {'Content-Type': 'text/plain; charset=utf-8'}});
}

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || !url.href.startsWith(self.registration.scope)) return;
  if (event.request.mode === 'navigate') {
    event.respondWith(navigate(event.request));
  } else {
    event.respondWith((async () => (await cachedResource(event.request)) || fetch(event.request))());
  }
});

self.addEventListener('message', (event) => {
  if (event.origin !== self.location.origin) return;
  if (event.data?.type === 'GET_VERSION') event.ports[0]?.postMessage({version: VERSION});
});
