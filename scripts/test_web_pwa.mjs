import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';

const scope = 'https://example.test/td-game/';
const source = await readFile(new URL('../web/service-worker.js', import.meta.url), 'utf8');
const stores = new Map();
const network = new Map();
let online = true;
let clients = [];
const key = (request) => typeof request === 'string' || request instanceof URL ? new URL(request, scope).href : request.url;
const fetchResource = async (request) => {
  if (!online) throw new Error('offline');
  return new Response(network.get(key(request)) ?? 'missing', {status: network.has(key(request)) ? 200 : 404});
};
class RequestStub {
  constructor(input, options = {}) {
    this.url = key(input);
    this.mode = options.mode || input.mode || 'cors';
    this.method = options.method || input.method || 'GET';
  }
}
const cacheStorage = {
  async keys() { return [...stores.keys()]; },
  async delete(name) { return stores.delete(name); },
  async open(name) {
    if (!stores.has(name)) stores.set(name, new Map());
    const data = stores.get(name);
    return {
      async match(request) { return data.get(key(request))?.clone(); },
      async put(request, response) { data.set(key(request), response.clone()); },
      async addAll(requests) {
        for (const request of requests) {
          const response = await fetchResource(request);
          if (!response.ok) throw new Error('missing asset');
          data.set(key(request), response);
        }
      },
    };
  },
};
function worker(version) {
  const events = new Map();
  const files = ['index.html', `index.${version}.js`, `index.${version}.wasm`, `index.${version}.pck`];
  const context = {
    self: {
      registration: {scope}, location: {origin: new URL(scope).origin},
      addEventListener(name, callback) { events.set(name, callback); },
      async skipWaiting() {},
      clients: {async claim() {}, async matchAll() { return clients; }},
    },
    caches: cacheStorage, fetch: fetchResource, Request: RequestStub, Response, URL, AbortController, MessageChannel,
    setTimeout: (callback, delay) => setTimeout(callback, Math.min(delay, 30)), clearTimeout,
  };
  vm.runInNewContext(source.replace('__VERSION__', version).replace('__FILES__', JSON.stringify(files)), context);
  return {
    files,
    async lifecycle(name) {
      let pending;
      events.get(name)({waitUntil(promise) { pending = promise; }});
      await pending;
    },
    async request(path, mode = 'cors') {
      let response;
      events.get('fetch')({request: new RequestStub(new URL(path, scope).href, {mode}), respondWith(value) { response = value; }});
      return response ? await response : undefined;
    },
  };
}
function publish(version) {
  network.clear();
  network.set(scope + 'index.html', `<html data-build="${version}">build ${version}</html>`);
  network.set(scope, network.get(scope + 'index.html'));
  for (const extension of ['js', 'wasm', 'pck']) network.set(scope + `index.${version}.${extension}`, `${version}-${extension}`);
}
publish('A');
const a = worker('A');
await a.lifecycle('install');
await a.lifecycle('activate');
online = false;
assert.match(await (await a.request('', 'navigate')).text(), /build A/);
assert.equal(await (await a.request('index.A.wasm')).text(), 'A-wasm');
online = true;
publish('B');
assert.match(await (await a.request('', 'navigate')).text(), /build B/);
assert.equal(await (await a.request('index.B.js')).text(), 'B-js');
const b = worker('B');
let update;
let navigated = false;
clients = [{
  url: scope,
  postMessage(message, ports) {
    if (message.type === 'GET_CLIENT_VERSION') {
      ports[0].postMessage({version: 'A'});
      ports[0].close();
    } else update = message;
  },
  async navigate() { navigated = true; },
}];
await b.lifecycle('install');
await b.lifecycle('activate');
assert.equal(update.type, 'UPDATE_READY');
assert.equal(update.version, 'B');
assert.equal(navigated, false, 'a current client is never reloaded mid-match');
online = false;
assert.equal(await (await b.request('index.A.wasm')).text(), 'A-wasm');
assert.equal(await (await b.request('index.B.wasm')).text(), 'B-wasm');
assert.match(await (await b.request('', 'navigate')).text(), /build B/);
assert.equal(await b.request('https://elsewhere.test/asset.js'), undefined);
online = true;
publish('C');
network.delete(scope + 'index.C.pck');
const c = worker('C');
await assert.rejects(c.lifecycle('install'), /missing asset/);
assert.equal(stores.has('robot-defense-pwa-C'), false);
assert.equal(stores.has('robot-defense-pwa-B'), true);
publish('C');
clients = [{url: scope, postMessage() {}, async navigate() { navigated = true; }}];
await c.lifecycle('install');
await c.lifecycle('activate');
assert.equal(navigated, true, 'legacy pages migrate to the new shell after a complete precache');
assert.equal(stores.has('robot-defense-pwa-A'), false);
assert.equal(stores.has('robot-defense-pwa-B'), true);
console.log('WEB CACHE: offline, fresh navigation, A→B update, mixed-version assets, incomplete deploy and legacy migration passed');
