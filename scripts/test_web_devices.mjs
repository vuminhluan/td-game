import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';

const source = await readFile(new URL('../web/pwa.js', import.meta.url), 'utf8');
const windows = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/141.0.0.0 Safari/537.36';
const mac = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/26.0 Safari/605.1.15';
const linux = 'Mozilla/5.0 (X11; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0';
const profiles = [
  {name: 'Windows desktop', agent: windows, allowed: true},
  {name: 'Mac Safari', agent: mac, allowed: true},
  {name: 'Linux Firefox', agent: linux, allowed: true},
  {name: 'ChromeOS laptop', agent: 'Mozilla/5.0 (X11; CrOS x86_64 16000.0.0) Chrome/141.0.0.0', allowed: true},
  {name: 'touchscreen Windows laptop with trackpad', agent: windows, touch: 10, allowed: true},
  {name: 'narrow portrait desktop window', agent: windows, width: 400, height: 800, allowed: true},
  {name: 'portrait touchscreen laptop', agent: windows, touch: 10, width: 720, height: 1000, allowed: true},
  {name: 'Android phone', agent: 'Mozilla/5.0 (Linux; Android 15; Pixel 9) Chrome/141.0 Mobile Safari/537.36', touch: 5, coarse: true, allowed: false},
  {name: 'Android tablet without Mobile token', agent: 'Mozilla/5.0 (Linux; Android 15; SM-X910) Chrome/141.0 Safari/537.36', touch: 10, allowed: false},
  {name: 'Android tablet desktop UA with platform hint', agent: linux, hints: {platform: 'Android', mobile: false}, touch: 10, allowed: false},
  {name: 'iPhone', agent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1', touch: 5, coarse: true, allowed: false},
  {name: 'iPad classic UA', agent: 'Mozilla/5.0 (iPad; CPU OS 18_6 like Mac OS X) AppleWebKit/605.1.15 Version/18.6 Safari/604.1', touch: 5, allowed: false},
  {name: 'iPad desktop Safari with keyboard and pointer', agent: mac, platform: 'MacIntel', touch: 5, allowed: false},
  {name: 'iPad desktop PWA portrait', agent: mac, platform: 'MacIntel', touch: 5, width: 1024, height: 1366, allowed: false},
  {name: 'Kindle Fire tablet', agent: 'Mozilla/5.0 (Linux; U; Android 9; KFMAWI) AppleWebKit/537.36 Silk/141.0 Safari/537.36', touch: 5, allowed: false},
  {name: 'Windows tablet with coarse pointer', agent: windows, touch: 10, coarse: true, allowed: false},
  {name: 'mobile client hint overrides desktop UA', agent: windows, hints: {platform: 'Windows', mobile: true}, allowed: false},
  {name: 'unknown touch tablet', agent: 'TabletBrowser/1.0', touch: 5, allowed: false},
  {name: 'unknown device fails closed', agent: '', allowed: false},
];

for (const profile of profiles) {
  const elements = new Map();
  const events = new Map();
  const width = profile.width || 1280;
  const height = profile.height || 720;
  const element = (id) => {
    if (!elements.has(id)) elements.set(id, {
      style: {}, hidden: false, width: 0, height: 0,
      addEventListener() {}, focus() {},
      getBoundingClientRect() { return {width, height}; },
    });
    return elements.get(id);
  };
  class Engine {
    static getMissingFeatures() { return []; }
    startGame() { return Promise.resolve(); }
  }
  const context = {
    document: {documentElement: {dataset: {build: 'test'}}, getElementById: element, addEventListener() {}},
    navigator: {userAgent: profile.agent, platform: profile.platform || '', maxTouchPoints: profile.touch || 0, userAgentData: profile.hints},
    matchMedia() { return {matches: profile.coarse || false}; },
    window: {innerWidth: width, innerHeight: height, devicePixelRatio: 2, addEventListener(name, callback) { events.set(name, callback); }},
    GODOT_CONFIG: {}, GODOT_THREADS_ENABLED: false, Engine, console, setInterval() {},
  };
  vm.runInNewContext(source, context);
  await Promise.resolve();
  const bridge = context.window.RobotDefenseWeb;
  assert.equal(bridge.metrics.localCoop, profile.allowed, profile.name);
  assert.equal(bridge.metrics.width, width, profile.name + ' logical width');
  const portraitGate = Boolean((profile.touch || profile.coarse) && !profile.allowed && height > width);
  assert.equal(bridge.metrics.blocked, portraitGate, profile.name + ' portrait policy');
  let delivered;
  bridge.subscribe((json) => { delivered = JSON.parse(json); });
  assert.equal(delivered.localCoop, profile.allowed, profile.name + ' initial Godot handshake');
  events.get('resize')();
  assert.equal(delivered.localCoop, profile.allowed, profile.name + ' resize handshake');
}
console.log(`WEB DEVICES: ${profiles.length} desktop/laptop/phone/tablet profiles passed, including iPad desktop mode and touchscreen laptops`);
