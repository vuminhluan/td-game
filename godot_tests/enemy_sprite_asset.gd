extends SceneTree
const Terrain = preload("res://godot_tests/terrain_fixture.gd")
var checks = 0
const Sim = preload("res://gd/simulation.gd")
const R = preload("res://gd/rules.gd")

func _initialize() -> void:
	call_deferred("run")

func require(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.map_preparation.confirm_selection()
	game.activate()
	for kind in ["tank", "robot"]:
		var skin: Resource = game.battle.enemy_skins[kind]
		require(game.sim.enemy_muzzle_distances[kind] == skin.muzzle_distances(), "bind each enemy muzzle geometry")
		var areas: Array[float] = []
		for direction in ["down", "up", "left", "right"]:
			var view: Resource = skin.direction_for(direction)
			if kind == "tank":
				var image: Image = view.frames.get_frame_texture("idle", 0).get_image()
				var area = 0
				for y in image.get_height():
					for x in image.get_width():
						if image.get_pixel(x, y).a > 0.5:
							area += 1
				areas.append(area * view.texture_scale * view.texture_scale)
			for state in {"idle": 4, "walk": 6, "attack": 4}:
				var count: int = {"idle": 4, "walk": 6, "attack": 4}[state]
				require(view.frames.get_frame_count(state) == count, kind + direction + state + " frame count")
				require(view.frames.get_animation_loop(state) == (state != "attack"), "one-shot attack contract")
				for i in count:
					var texture: Texture2D = view.frames.get_frame_texture(state, i)
					require(texture.get_size() == Vector2(128,128), "complete 128px frame")
			var sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
			for row in sim.map:
				for tile in row:
					Terrain.apply(tile, "floor")
			sim.start()
			sim.spawn_timer = 999
			sim.enemy_muzzle_distances[kind] = skin.muzzle_distances()
			sim.player.pos = Vector2(800, 800)
			var enemy = sim.make_actor(kind, Vector2(420, 380))
			require(enemy.hp == (4 if kind == "tank" else 2), "keep existing enemy HP")
			enemy.dir = direction
			enemy.cooldown = 0
			sim.enemies.append(enemy)
			require(skin.frame_for(enemy, 0) == view.frames.get_frame_texture("idle", 0), "select exact direction texture")
			sim.fire(enemy)
			require(skin.animation_for(enemy) == "attack", "stationary enemy shot animates")
			require(sim.effects.back().pos.is_equal_approx(enemy.pos + R.VECTOR[direction] * view.muzzle_distance), "flash at enemy muzzle")
			enemy.shot_clock -= 0.1
			require(skin.frame_for(enemy, 0) != view.frames.get_frame_texture("attack", 0), "recoil advances independently of long cooldown")
			enemy.target = enemy.pos + R.VECTOR[direction] * 40
			sim.update(0.02)
			require(not enemy.moving and skin.animation_for(enemy) == "attack", "enemy keeps facing and position during attack")
			for i in 8:
				sim.update(0.05)
			require(enemy.moving and skin.animation_for(enemy) == "walk", "enemy resumes locomotion after attack")
			sim.pause()
			var snapshot = var_to_bytes([enemy, sim.elapsed])
			sim.update(0.05)
			require(snapshot == var_to_bytes([enemy, sim.elapsed]), "pause freezes enemy clocks")
			sim.pause()
			enemy.target = enemy.pos
			enemy.shot_clock = 0
			enemy.cooldown = 999
			sim.update(0.02)
			require(not enemy.moving and enemy.move_clock == 0 and skin.animation_for(enemy) == "idle", "stopped movement resets walk clock")
			for wall_kind in ["brick", "steel", "player"]:
				var close = Sim.new(preload("res://assets/loadouts/standard.tres"))
				for row in close.map:
					for tile in row:
						Terrain.apply(tile, "floor")
				close.enemy_muzzle_distances[kind] = {direction: 48.0}
				var shooter = close.make_actor(kind, Vector2(420,380))
				shooter.dir = direction
				shooter.cooldown = 0
				close.enemies.append(shooter)
				if wall_kind == "player":
					close.player.pos = shooter.pos + R.VECTOR[direction] * 30
				else:
					var cell = Vector2i(shooter.pos / R.TILE) + Vector2i(R.VECTOR[direction])
					close.map[cell.y][cell.x] = Terrain.tile(wall_kind, 3)
				close.fire(shooter)
				require(close.bullets.is_empty(), "enemy muzzle may not bypass " + wall_kind)
				if wall_kind == "player":
					require(close.player.hp == R.PLAYER_HP - 1, "close player receives exactly one hit")
		if kind == "tank":
			require(areas.max() / areas.min() < 1.10, "tank visible size stays consistent across four directions")
		for aim in ["up", "down", "left", "right"]:
			var aiming = Sim.new(preload("res://assets/loadouts/standard.tres"))
			for row in aiming.map:
				for tile in row:
					Terrain.apply(tile, "floor")
			aiming.start()
			aiming.spawn_timer = 999
			aiming.enemy_muzzle_distances[kind] = skin.muzzle_distances()
			var shooter = aiming.make_actor(kind, Vector2(420, 380))
			shooter.dir = "down"
			shooter.target = shooter.pos + Vector2(0, 40)
			shooter.cooldown = 0
			aiming.enemies.append(shooter)
			aiming.player.pos = shooter.pos + R.VECTOR[aim] * 150
			aiming.update(0.01)
			require(aiming.bullets.size() == 1 and aiming.bullets[0].dir == aim and shooter.dir == aim, "aimed bullet and rendered facing agree: " + aim)
			require(not shooter.moving and shooter.pos == Vector2(420, 380), "aimed shot stops movement")
			aiming.update(0.05)
			require(shooter.dir == aim and not shooter.moving, "attack cannot turn back to route before recoil ends")
			for i in 8:
				aiming.update(0.05)
			require(shooter.dir == "down" and shooter.moving, "route resumes after aimed attack")
		var replacement = preload("res://gd/enemy_direction.gd").new()
		replacement.frames = skin.directions.right.frames
		replacement.anchor = Vector2(70,60)
		var copy: Resource = skin.duplicate()
		copy.directions = skin.directions.duplicate()
		copy.directions.left = replacement
		require(copy.direction_for("left") == replacement and copy.direction_for("right") == skin.direction_for("right"), "replace a single direction independently")
		var test_actor = Sim.new(preload("res://assets/loadouts/standard.tres")).make_actor(kind, Vector2.ZERO)
		test_actor.dir = "left"
		require(copy.frame_for(test_actor, 0) == replacement.frames.get_frame_texture("idle", 0), "render the replacement texture")
	game.sim.status = "lost"
	game.activate()
	for kind in game.battle.enemy_skins:
		require(game.sim.enemy_muzzle_distances[kind] == game.battle.enemy_skins[kind].muzzle_distances(), "replay rebinds geometry")
	game.queue_free()
	await process_frame
	print("ENEMY SPRITES: %d checks passed; 112 frames, direction replacement, clocks, pause, muzzle collision, replay" % checks)
	quit()
