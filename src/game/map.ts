import { COLS, ROWS, TILE, type Tile, type Point } from "./config";
export function createMap(): Tile[][] {
  const map: Tile[][] = Array.from({ length: ROWS }, () =>
    Array.from({ length: COLS }, () => ({ kind: "floor", hp: 0 })),
  );
  const place = (kind: Tile["kind"], x: number, y: number, w = 1, h = 1) => {
    for (let j = y; j < y + h; j++)
      for (let i = x; i < x + w; i++)
        map[j][i] = { kind, hp: kind === "brick" ? 3 : 0 };
  };
  for (const x of [4, 12]) place("brick", x, 1, 5);
  for (const x of [4, 15]) {
    place("steel", x, 3, 2, 2);
    place("grass", x, 5, 2);
    place("steel", x, 8, 2, 2);
    place("grass", x, 10, 2);
    place("steel", x, 12, 2, 2);
    place("grass", x, 14, 2);
  }
  for (const x of [3, 17]) {
    place("water", x, 4, 1, 2);
    place("water", x, 9, 1, 2);
  }
  for (const x of [1, 19]) {
    place("brick", x, 4, 1, 2);
    place("brick", x, 8, 1, 2);
    place("brick", x, 13);
  }
  place("brick", 8, 5, 1, 3);
  place("brick", 7, 5);
  place("brick", 12, 5, 1, 3);
  place("brick", 13, 5);
  place("grass", 8, 9);
  place("grass", 12, 9);
  place("brick", 8, 10, 1, 2);
  place("brick", 7, 11);
  place("brick", 12, 10, 1, 2);
  place("brick", 13, 11);
  for (const x of [7, 13]) place("brick", x, 14);
  for (const x of [6, 14]) place("brick", x, 16, 1, 2);
  place("brick", 4, 17, 2);
  place("brick", 15, 17, 2);
  return map;
}
export function tileAt(map: Tile[][], x: number, y: number) {
  return map[Math.floor(y / TILE)]?.[Math.floor(x / TILE)];
}
export function canOccupy(
  map: Tile[][],
  x: number,
  y: number,
  r = 13,
): boolean {
  for (const dx of [-r, r])
    for (const dy of [-r, r]) {
      const t = tileAt(map, x + dx, y + dy);
      if (!t || ["brick", "steel", "water"].includes(t.kind)) return false;
    }
  return true;
}
// Dijkstra with a breach cost: enemies can choose to shoot through brick, never steel or water.
export function findPath(map: Tile[][], start: Point, goal: Point): Point[] {
  const key = (p: Point) => p.y * COLS + p.x;
  const frontier = [{ ...start, cost: 0 }];
  const costs = new Map<number, number>([[key(start), 0]]);
  const parent = new Map<number, Point>();
  while (frontier.length) {
    frontier.sort((a, b) => a.cost - b.cost);
    const current = frontier.shift()!;
    if (current.cost !== costs.get(key(current))) continue;
    if (current.x === goal.x && current.y === goal.y) {
      const path: Point[] = [];
      let p: Point = current;
      while (key(p) !== key(start)) {
        path.unshift({ x: p.x, y: p.y });
        p = parent.get(key(p))!;
      }
      return path;
    }
    for (const d of [
      { x: 0, y: 1 },
      { x: -1, y: 0 },
      { x: 1, y: 0 },
      { x: 0, y: -1 },
    ]) {
      const p = { x: current.x + d.x, y: current.y + d.y };
      const tile = map[p.y]?.[p.x];
      if (!tile || tile.kind === "steel" || tile.kind === "water") continue;
      const cost = current.cost + (tile.kind === "brick" ? 7 : 1);
      if (cost < (costs.get(key(p)) ?? Infinity)) {
        costs.set(key(p), cost);
        parent.set(key(p), current);
        frontier.push({ ...p, cost });
      }
    }
  }
  return [];
}
