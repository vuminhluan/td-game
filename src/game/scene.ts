import Phaser from "phaser";
import {
  ANGLE,
  BASE,
  COLS,
  ROWS,
  TILE,
  WIDTH,
  HEIGHT,
  type Direction,
} from "./config";
import { Simulation } from "./simulation";
import { createTextures } from "./textures";
export class BattleScene extends Phaser.Scene {
  sim = new Simulation();
  onChange: (sim: Simulation) => void = () => {};
  touchDirection?: Direction;
  touchFire = false;
  private terrain!: Phaser.GameObjects.Container;
  private foliage!: Phaser.GameObjects.Container;
  private actors = new Map<number, Phaser.GameObjects.Image>();
  private fx!: Phaser.GameObjects.Graphics;
  private revision = -1;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private lastHud = 0;
  constructor() {
    super("Battle");
  }
  create() {
    createTextures(this);
    this.terrain = this.add.container();
    this.foliage = this.add.container().setDepth(6);
    this.fx = this.add.graphics().setDepth(8);
    this.keys = this.input.keyboard!.addKeys(
      "W,A,S,D,UP,RIGHT,DOWN,LEFT,SPACE,ESC,P",
    ) as Record<string, Phaser.Input.Keyboard.Key>;
    this.keys.ESC.on("down", () => this.togglePause());
    this.keys.P.on("down", () => this.togglePause());
    this.input.keyboard!.addCapture(["SPACE", "UP", "DOWN", "LEFT", "RIGHT"]);
    this.game.events.on("blur", () => {
      if (this.sim.status === "playing") {
        this.sim.pause();
        this.onChange(this.sim);
      }
      this.touchDirection = undefined;
      this.touchFire = false;
    });
    this.drawMap();
    this.onChange(this.sim);
  }
  start() {
    this.sim.start();
    this.onChange(this.sim);
  }
  restart() {
    for (const s of this.actors.values()) s.destroy();
    this.actors.clear();
    this.sim = new Simulation();
    this.sim.start();
    this.revision = -1;
    this.onChange(this.sim);
  }
  togglePause() {
    this.sim.pause();
    this.onChange(this.sim);
  }
  private drawMap() {
    this.terrain.removeAll(true);
    this.foliage.removeAll(true);
    for (let y = 0; y < ROWS; y++)
      for (let x = 0; x < COLS; x++) {
        const px = (x + 0.5) * TILE,
          py = (y + 0.5) * TILE,
          t = this.sim.map[y][x];
        this.terrain.add(this.add.image(px, py, `floor${(x * 7 + y * 3) % 4}`));
        if (t.kind !== "floor" && t.kind !== "grass")
          this.terrain.add(
            this.add.image(
              px,
              py,
              t.kind === "brick" ? `brick${t.hp}` : t.kind,
            ),
          );
        if (t.kind === "grass")
          this.foliage.add(this.add.image(px, py, "grass").setAlpha(0.85));
      }
    this.terrain.add(this.add.image(BASE.x, BASE.y - 5, "base"));
    const markings = this.add.graphics();
    markings.lineStyle(1, 0xc7af70, 0.28);
    markings.strokeRect(BASE.x - 60, BASE.y - 65, 120, 105);
    for (let x = BASE.x - 54; x < BASE.x + 58; x += 12) {
      markings.lineStyle(3, 0xb4a15d, 0.4);
      markings.lineBetween(x, BASE.y + 43, x + 7, BASE.y + 36);
    }
    this.terrain.add(markings);
    for (const x of [1, 10, 19])
      this.terrain.add(
        this.add
          .text((x + 0.5) * TILE, 7, "▼", {
            fontFamily: "monospace",
            fontSize: "15px",
            color: "#d98160",
          })
          .setOrigin(0.5, 0),
      );
    this.revision = this.sim.revision;
  }
  update(time: number, delta: number) {
    if (!this.keys) return;
    const order: [string, Direction][] = [
      ["W", "up"],
      ["UP", "up"],
      ["D", "right"],
      ["RIGHT", "right"],
      ["S", "down"],
      ["DOWN", "down"],
      ["A", "left"],
      ["LEFT", "left"],
    ];
    const pressed = order
      .filter(([k]) => this.keys[k].isDown)
      .sort((a, b) => this.keys[b[0]].timeDown - this.keys[a[0]].timeDown);
    const before = this.sim.map
      .flat()
      .filter((t) => t.kind === "brick")
      .reduce((n, t) => n + t.hp, 0);
    this.sim.update(delta / 1000, {
      direction: this.touchDirection ?? pressed[0]?.[1],
      fire: this.touchFire || this.keys.SPACE.isDown,
    });
    const after = this.sim.map
      .flat()
      .filter((t) => t.kind === "brick")
      .reduce((n, t) => n + t.hp, 0);
    if (this.revision !== this.sim.revision || before !== after) this.drawMap();
    const alive = new Set<number>();
    for (const actor of [this.sim.player, ...this.sim.enemies]) {
      alive.add(actor.id);
      let sprite = this.actors.get(actor.id);
      if (!sprite) {
        sprite = this.add.image(actor.x, actor.y, actor.kind).setDepth(5);
        this.actors.set(actor.id, sprite);
      }
      sprite.setPosition(actor.x, actor.y).setRotation(ANGLE[actor.dir]);
      sprite.setAlpha(
        actor.kind === "player" && this.sim.invulnerable > 0
          ? Math.sin(time / 60) > 0.0
            ? 0.35
            : 1
          : 1,
      );
    }
    for (const [id, sprite] of this.actors)
      if (!alive.has(id)) {
        sprite.destroy();
        this.actors.delete(id);
      }
    this.fx.clear();
    for (const e of this.sim.enemies) {
      if (e.hp < e.maxHp) {
        this.fx.fillStyle(0x172023);
        this.fx.fillRect(e.x - 13, e.y + 23, 26, 3);
        this.fx.fillStyle(0xed9870);
        this.fx.fillRect(e.x - 13, e.y + 23, (26 * e.hp) / e.maxHp, 3);
      }
    }
    for (const b of this.sim.bullets) {
      this.fx.fillStyle(b.friendly ? 0xffe9ae : 0xff8659, 0.18);
      this.fx.fillCircle(b.x, b.y, 7);
      this.fx.fillStyle(b.friendly ? 0xffedb6 : 0xff8158);
      this.fx.fillRect(b.x - 2, b.y - 3, 4, 6);
    }
    for (const e of this.sim.effects) {
      const p = 1 - e.life / e.max;
      this.fx.fillStyle(0xffa153, 1 - p);
      this.fx.fillCircle(
        e.x,
        e.y,
        e.kind === "explosion" ? 5 + p * 23 : 3 + p * 7,
      );
      this.fx.lineStyle(2, 0xffde9a, 1 - p);
      for (let i = 0; i < 7; i++) {
        let a = (i * Math.PI * 2) / 7;
        this.fx.lineBetween(
          e.x + Math.cos(a) * p * 10,
          e.y + Math.sin(a) * p * 10,
          e.x + Math.cos(a) * (8 + p * 30),
          e.y + Math.sin(a) * (8 + p * 30),
        );
      }
    }
    if (time - this.lastHud > 100) {
      this.onChange(this.sim);
      this.lastHud = time;
    }
  }
}
