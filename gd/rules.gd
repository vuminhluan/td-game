extends RefCounted

const TILE = 40
const COLS = 21
const ROWS = 19
const WIDTH = COLS * TILE
const HEIGHT = ROWS * TILE
const BASE = Vector2(420, 700)
const PLAYER_SPEED = 150.0
const PLAYER_HP = 5
const LIVES = 3
const BASE_HP = 20
const SHOT_COOLDOWN = 0.23
const PLAYER_MUZZLE_DISTANCE = 15.0
const BULLET_SPEED = 410.0
const WAVE_COUNTS = [5, 7, 9, 11, 14]
const WAVE_DELAY = 5.0
const SPAWN_DELAY = 1.4
const VECTOR = {"up": Vector2.UP, "right": Vector2.RIGHT, "down": Vector2.DOWN, "left": Vector2.LEFT}
const ANGLE = {"up": 0.0, "right": PI / 2, "down": PI, "left": -PI / 2}
