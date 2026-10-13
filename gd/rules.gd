extends RefCounted

const TILE = 40
const PLAYER_SPEED = 150.0
const PLAYER_HP = 5
const LIVES = 3
const BASE_HP = 20
const SHOT_COOLDOWN = 0.4
const PLAYER_SHOT_DURATION = 0.23
const POWER_UP_DURATION = 5.0
const POWER_UP_SAFE_DISTANCE = 3.0 * TILE
const POWER_UP_PICKUP_RADIUS = 25.0
const STEEL_HP = 5
const RAPID_FIRE_MULTIPLIER = 2.0
const SPEED_BOOST_MULTIPLIER = 1.5
const DOUBLE_SHOT_DELAY = 0.08
const PLAYER_MUZZLE_DISTANCE = 15.0
const BULLET_SPEED = 410.0
const WAVE_COUNTS = [5, 7, 9, 11, 14]
const WAVE_DELAY = 5.0
const SPAWN_DELAY = 1.4
const VECTOR = {"up": Vector2.UP, "right": Vector2.RIGHT, "down": Vector2.DOWN, "left": Vector2.LEFT}
const ANGLE = {"up": 0.0, "right": PI / 2, "down": PI, "left": -PI / 2}
