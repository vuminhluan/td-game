import test from "node:test";
import assert from "node:assert/strict";
import { Simulation } from "../src/game/simulation";
import { createMap, canOccupy, findPath } from "../src/game/map";
import { BASE, RULES, TILE } from "../src/game/config";
const step = (s: Simulation, seconds: number) => {
  for (let i = 0; i < seconds * 60; i++) s.update(1 / 60, { fire: false });
};
test("brick takes exactly three hits and opens a traversable path", () => {
  const s = new Simulation();
  const x = 4.5 * TILE,
    y = 1.5 * TILE;
  assert.equal(canOccupy(s.map, x, y), false);
  s.damageBrick(x, y);
  assert.equal(s.map[1][4].hp, 2);
  s.damageBrick(x, y);
  assert.equal(s.map[1][4].kind, "brick");
  s.damageBrick(x, y);
  assert.equal(s.map[1][4].kind, "floor");
  assert.equal(canOccupy(s.map, x, y), true);
});
test("grass is passable; water, steel and world boundaries block actors", () => {
  const map = createMap();
  assert.ok(canOccupy(map, 4.5 * TILE, 5.5 * TILE));
  assert.equal(canOccupy(map, 3.5 * TILE, 4.5 * TILE), false);
  assert.equal(canOccupy(map, 4.5 * TILE, 3.5 * TILE), false);
  assert.equal(canOccupy(map, 1, 1), false);
});
test("all spawn lanes have a four-direction route to base", () => {
  const map = createMap();
  for (const x of [1, 10, 19]) {
    const path = findPath(map, { x, y: 0 }, { x: 10, y: 16 });
    assert.ok(path.length);
    let prev = { x, y: 0 };
    for (const p of path) {
      assert.equal(Math.abs(p.x - prev.x) + Math.abs(p.y - prev.y), 1);
      assert.ok(!["steel", "water"].includes(map[p.y][p.x].kind));
      prev = p;
    }
    assert.deepEqual(path.at(-1), { x: 10, y: 16 });
  }
});
test("pathfinder can breach a brick when all other routes are blocked", () => {
  const map = createMap();
  map[0][0] = { kind: "floor", hp: 0 };
  map[0][1] = { kind: "brick", hp: 3 };
  map[1][0] = { kind: "steel", hp: 0 };
  assert.ok(
    findPath(map, { x: 0, y: 0 }, { x: 2, y: 0 }).some(
      (p) => p.x === 1 && p.y === 0,
    ),
  );
});
test("pause freezes simulation and resume continues it", () => {
  const s = new Simulation();
  s.start();
  step(s, 1);
  s.pause();
  const snapshot = JSON.stringify(s);
  step(s, 10);
  assert.equal(JSON.stringify(s), snapshot);
  s.pause();
  step(s, 1);
  assert.ok(s.elapsed > 1.9);
});
test("movement stays on one axis and cannot enter the base", () => {
  const s = new Simulation();
  s.start();
  const x = s.player.x;
  s.update(0.05, { direction: "right", fire: false });
  assert.ok(s.player.x > x);
  assert.equal(s.player.y, BASE.y - 80);
  s.player.x = BASE.x;
  s.player.y = BASE.y - 26;
  s.update(0.05, { direction: "down", fire: false });
  assert.equal(s.player.y, BASE.y - 26);
});
test("enemy bullets damage base while friendly bullets do not", () => {
  for (const friendly of [true, false]) {
    const s = new Simulation();
    s.start();
    s.bullets.push({
      id: 99,
      x: BASE.x,
      y: BASE.y - 30,
      dir: "down",
      friendly,
    });
    s.update(0.05, { fire: false });
    assert.equal(s.baseHp, RULES.baseHp - (friendly ? 0 : 1));
  }
});
test("bullet traverses water but is absorbed by steel", () => {
  const s = new Simulation();
  s.start();
  s.bullets.push({
    id: 90,
    x: 3.5 * TILE,
    y: 4 * TILE - 2,
    dir: "down",
    friendly: true,
  });
  s.update(0.05, { fire: false });
  assert.ok(s.bullets.some((b) => b.id === 90));
  s.bullets.push({
    id: 91,
    x: 4.5 * TILE,
    y: 3 * TILE - 2,
    dir: "down",
    friendly: true,
  });
  s.update(0.05, { fire: false });
  assert.ok(!s.bullets.some((b) => b.id === 91));
});
test("enemy waves can destroy an undefended base, and IDs are unique", () => {
  const s = new Simulation();
  s.start();
  s.player.x = 20;
  s.player.y = HEIGHT_SAFE;
  step(s, 180);
  assert.equal(s.status, "lost");
  assert.equal(s.baseHp, 0);
  assert.equal(
    new Set([s.player.id, ...s.enemies.map((e) => e.id)]).size,
    s.enemies.length + 1,
  );
});
const HEIGHT_SAFE = 740;
test("clearing all five waves reaches victory and restart creates a clean state", () => {
  const s = new Simulation();
  s.start();
  for (let wave = 1; wave <= 5; wave++) {
    assert.equal(s.wave, wave);
    s.enemies = [];
    s.toSpawn = 0;
    step(s, 5.1);
  }
  assert.equal(s.status, "won");
  const fresh = new Simulation();
  assert.equal(fresh.status, "ready");
  assert.equal(fresh.baseHp, 20);
  assert.equal(fresh.score, 0);
});
test("three destroyed player robots end the game; respawn grants immunity", () => {
  const s = new Simulation();
  s.start();
  s.toSpawn = 99;
  s.spawnTimer = 999;
  for (let life = 3; life > 0; life--) {
    s.player.hp = 1;
    s.invulnerable = 0;
    s.bullets.push({
      id: 100 + life,
      x: s.player.x,
      y: s.player.y - 15,
      dir: "down",
      friendly: false,
    });
    s.update(0.02, { fire: false });
    assert.equal(s.lives, life - 1);
    if (life > 1) assert.ok(s.invulnerable > 0);
  }
  assert.equal(s.status, "lost");
});
