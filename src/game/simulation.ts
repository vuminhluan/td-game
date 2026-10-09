import {
  BASE,
  COLS,
  ROWS,
  TILE,
  WIDTH,
  HEIGHT,
  RULES,
  VECTOR,
  type Direction,
  type Point,
  type Tile,
} from "./config";
import { createMap, canOccupy, tileAt, findPath } from "./map";
export type Actor = Point & {
  id: number;
  dir: Direction;
  hp: number;
  maxHp: number;
  cooldown: number;
  kind: "player" | "robot" | "tank";
  target?: Point;
};
export type Bullet = Point & { id: number; dir: Direction; friendly: boolean };
export type Effect = Point & {
  life: number;
  max: number;
  kind: "spark" | "explosion";
};
export type Status = "ready" | "playing" | "paused" | "won" | "lost";
export class Simulation {
  private sequence = 1;
  map: Tile[][] = createMap();
  player: Actor = this.makeActor("player", BASE.x, BASE.y - 2 * TILE);
  enemies: Actor[] = [];
  bullets: Bullet[] = [];
  effects: Effect[] = [];
  status: Status = "ready";
  baseHp = RULES.baseHp;
  lives = RULES.lives;
  wave = 0;
  score = 0;
  kills = 0;
  elapsed = 0;
  toSpawn = 0;
  spawnTimer = 0;
  waveTimer = 0;
  invulnerable = 0;
  revision = 0;
  message = "Phòng tuyến cuối cùng";
  private makeActor(kind: Actor["kind"], x: number, y: number): Actor {
    const hp = kind === "player" ? RULES.playerHp : kind === "tank" ? 4 : 2;
    return {
      id: this.sequence++,
      x,
      y,
      kind,
      hp,
      maxHp: hp,
      dir: kind === "player" ? "up" : "down",
      cooldown: 0.7,
    };
  }
  start() {
    if (this.status === "ready") {
      this.status = "playing";
      this.nextWave();
    }
  }
  pause() {
    if (this.status === "playing") this.status = "paused";
    else if (this.status === "paused") this.status = "playing";
  }
  private nextWave() {
    this.wave++;
    this.toSpawn = RULES.waveCounts[this.wave - 1];
    this.spawnTimer = 0.8;
    this.message = `Đợt ${this.wave} — Bảo vệ căn cứ`;
  }
  fire(actor: Actor) {
    if (actor.cooldown > 0) return;
    actor.cooldown =
      actor.kind === "player"
        ? RULES.shotCooldown
        : actor.kind === "tank"
          ? 1.3
          : 1.7;
    const v = VECTOR[actor.dir];
    this.bullets.push({
      id: this.sequence++,
      x: actor.x + v.x * 20,
      y: actor.y + v.y * 20,
      dir: actor.dir,
      friendly: actor.kind === "player",
    });
    this.effect(actor.x + v.x * 21, actor.y + v.y * 21, "spark");
  }
  private effect(x: number, y: number, kind: Effect["kind"]) {
    const life = kind === "spark" ? 0.13 : 0.48;
    this.effects.push({ x, y, kind, life, max: life });
  }
  damageBrick(x: number, y: number) {
    const t = tileAt(this.map, x, y);
    if (t?.kind !== "brick") return;
    t.hp--;
    if (t.hp === 0) {
      t.kind = "floor";
      this.revision++;
      for (const e of this.enemies) e.target = undefined;
    }
    this.effect(x, y, t.hp === 0 ? "explosion" : "spark");
  }
  private hitPlayer() {
    if (this.invulnerable > 0) return;
    this.player.hp--;
    this.invulnerable = 0.85;
    if (this.player.hp <= 0) {
      this.lives--;
      this.effect(this.player.x, this.player.y, "explosion");
      if (this.lives <= 0) {
        this.status = "lost";
        this.message = "Robot đã bị vô hiệu hóa";
        return;
      }
      this.player = this.makeActor("player", BASE.x, BASE.y - 2 * TILE);
      this.invulnerable = 3;
    }
  }
  update(dt: number, input: { direction?: Direction; fire: boolean }) {
    if (this.status !== "playing") return;
    dt = Math.min(dt, 0.05);
    this.elapsed += dt;
    this.invulnerable = Math.max(0, this.invulnerable - dt);
    this.effects = this.effects.filter((e) => (e.life -= dt) > 0);
    this.player.cooldown = Math.max(0, this.player.cooldown - dt);
    if (input.direction) {
      this.player.dir = input.direction;
      const v = VECTOR[input.direction],
        x = this.player.x + v.x * RULES.playerSpeed * dt,
        y = this.player.y + v.y * RULES.playerSpeed * dt;
      if (canOccupy(this.map, x, y) && !this.inBase(x, y, 25))
        Object.assign(this.player, { x, y });
    }
    if (input.fire) this.fire(this.player);
    if (this.toSpawn > 0) {
      this.spawnTimer -= dt;
      if (this.spawnTimer <= 0) {
        const lanes = [1, 10, 19];
        const lane =
          lanes[(RULES.waveCounts[this.wave - 1] - this.toSpawn) % 3];
        if (
          !this.enemies.some(
            (e) => Math.hypot(e.x - (lane + 0.5) * TILE, e.y - TILE / 2) < 35,
          )
        ) {
          this.enemies.push(
            this.makeActor(
              this.wave > 1 && this.toSpawn % 3 === 0 ? "tank" : "robot",
              (lane + 0.5) * TILE,
              TILE / 2,
            ),
          );
          this.toSpawn--;
        }
        this.spawnTimer = RULES.spawnDelay;
      }
    }
    for (const enemy of this.enemies) {
      enemy.cooldown = Math.max(0, enemy.cooldown - dt);
      this.moveEnemy(enemy, dt);
    }
    // Substeps keep fast bullets from tunneling through a tile or actor.
    for (const bullet of [...this.bullets]) {
      let dead = false;
      const v = VECTOR[bullet.dir];
      const steps = Math.ceil((RULES.bulletSpeed * dt) / 5);
      for (let s = 0; s < steps && !dead; s++) {
        bullet.x += (v.x * RULES.bulletSpeed * dt) / steps;
        bullet.y += (v.y * RULES.bulletSpeed * dt) / steps;
        if (
          bullet.x < 0 ||
          bullet.y < 0 ||
          bullet.x > WIDTH ||
          bullet.y > HEIGHT
        ) {
          dead = true;
          break;
        }
        const tile = tileAt(this.map, bullet.x, bullet.y);
        if (tile?.kind === "brick") {
          this.damageBrick(bullet.x, bullet.y);
          dead = true;
          break;
        }
        if (tile?.kind === "steel") {
          this.effect(bullet.x, bullet.y, "spark");
          dead = true;
          break;
        }
        if (bullet.friendly) {
          const enemy = this.enemies.find(
            (e) =>
              Math.abs(e.x - bullet.x) < 16 && Math.abs(e.y - bullet.y) < 16,
          );
          if (enemy) {
            enemy.hp--;
            dead = true;
            this.effect(
              enemy.x,
              enemy.y,
              enemy.hp <= 0 ? "explosion" : "spark",
            );
            if (enemy.hp <= 0) {
              this.enemies = this.enemies.filter((e) => e !== enemy);
              this.kills++;
              this.score += enemy.kind === "tank" ? 250 : 100;
            }
          }
        } else if (this.inBase(bullet.x, bullet.y, 28)) {
          this.baseHp--;
          dead = true;
          this.effect(bullet.x, bullet.y, "spark");
          if (this.baseHp <= 0) {
            this.status = "lost";
            this.message = "Căn cứ đã bị phá hủy";
            this.effect(BASE.x, BASE.y, "explosion");
          }
        } else if (
          Math.abs(bullet.x - this.player.x) < 14 &&
          Math.abs(bullet.y - this.player.y) < 14
        ) {
          this.hitPlayer();
          dead = true;
        }
      }
      if (dead) this.bullets = this.bullets.filter((b) => b !== bullet);
    }
    if (this.status !== "playing") return;
    if (this.toSpawn === 0 && this.enemies.length === 0) {
      if (this.wave === RULES.waveCounts.length) {
        this.status = "won";
        this.message = "Phòng tuyến được giữ vững";
      } else {
        this.waveTimer += dt;
        this.message = `Đợt tiếp theo sau ${Math.ceil(RULES.waveDelay - this.waveTimer)} giây`;
        if (this.waveTimer >= RULES.waveDelay) {
          this.waveTimer = 0;
          this.nextWave();
        }
      }
    }
  }
  private inBase(x: number, y: number, r: number) {
    return Math.abs(x - BASE.x) < r && Math.abs(y - BASE.y) < r;
  }
  private moveEnemy(e: Actor, dt: number) {
    if (Math.abs(e.x - BASE.x) < 18 && e.y > BASE.y - 100) {
      e.dir = "down";
      this.fire(e);
      return;
    }
    // Shoot at the defender when it crosses the same lane.
    const dx = this.player.x - e.x,
      dy = this.player.y - e.y;
    if ((Math.abs(dx) < 14 || Math.abs(dy) < 14) && Math.hypot(dx, dy) < 240) {
      e.dir =
        Math.abs(dx) < 14
          ? dy > 0
            ? "down"
            : "up"
          : dx > 0
            ? "right"
            : "left";
      this.fire(e);
    }
    if (!e.target) {
      const start = {
        x: Math.min(COLS - 1, Math.floor(e.x / TILE)),
        y: Math.min(ROWS - 1, Math.floor(e.y / TILE)),
      };
      const center = { x: (start.x + 0.5) * TILE, y: (start.y + 0.5) * TILE };
      if (Math.hypot(e.x - center.x, e.y - center.y) > 1) e.target = center;
      else {
        const path = findPath(this.map, start, { x: 10, y: 16 });
        if (path.length)
          e.target = {
            x: (path[0].x + 0.5) * TILE,
            y: (path[0].y + 0.5) * TILE,
          };
      }
    }
    const t = e.target;
    if (!t) return;
    const tx = t.x - e.x,
      ty = t.y - e.y;
    e.dir =
      Math.abs(tx) > 0.5 ? (tx > 0 ? "right" : "left") : ty > 0 ? "down" : "up";
    if (tileAt(this.map, t.x, t.y)?.kind === "brick") {
      this.fire(e);
      return;
    }
    const distance = Math.hypot(tx, ty),
      step = (e.kind === "tank" ? 40 : 54 + this.wave * 3) * dt;
    if (distance <= step) {
      e.x = t.x;
      e.y = t.y;
      e.target = undefined;
    } else {
      const v = VECTOR[e.dir];
      e.x += v.x * step;
      e.y += v.y * step;
    }
  }
}
