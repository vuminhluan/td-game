export const TILE = 40;
export const COLS = 21;
export const ROWS = 19;
export const WIDTH = COLS * TILE;
export const HEIGHT = ROWS * TILE;
export const RULES = {
  playerSpeed: 150,
  playerHp: 5,
  lives: 3,
  baseHp: 20,
  shotCooldown: 0.23,
  bulletSpeed: 410,
  waveCounts: [5, 7, 9, 11, 14],
  waveDelay: 5,
  spawnDelay: 1.4,
};
export type Direction = "up" | "right" | "down" | "left";
export const VECTOR: Record<Direction, { x: number; y: number }> = {
  up: { x: 0, y: -1 },
  right: { x: 1, y: 0 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
};
export const ANGLE: Record<Direction, number> = {
  up: 0,
  right: Math.PI / 2,
  down: Math.PI,
  left: -Math.PI / 2,
};
export type Tile = {
  kind: "floor" | "brick" | "steel" | "water" | "grass";
  hp: number;
};
export type Point = { x: number; y: number };
export const BASE = { x: 10 * TILE + TILE / 2, y: 17 * TILE + TILE / 2 };
