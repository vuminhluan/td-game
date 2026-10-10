extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var frames = load("res://assets/sprites/player_mech/player_mech.tres") as SpriteFrames
	if frames == null:
		push_error("SpriteFrames failed to load")
		quit(1)
		return
	var counts = {"idle": 4, "walk": 6, "attack": 4}
	for state in counts:
		if not frames.has_animation(state) or frames.get_frame_count(state) != counts[state]:
			push_error("Missing frames: " + state)
			quit(1)
			return
		for index in counts[state]:
			var frame = frames.get_frame_texture(state, index)
			if frame == null or frame.get_size() != Vector2(128, 128):
				push_error("Invalid texture frame")
				quit(1)
				return
	var directions = load("res://assets/sprites/player_mech/player_mech_directions.tres") as SpriteFrames
	for direction in ["up", "right", "left"]:
		for state in counts:
			var animation: String = direction + "_" + state
			require(directions.has_animation(animation) and directions.get_frame_count(animation) == counts[state], "direction must have complete idle/walk/attack frames")
			for index in counts[state]:
				require(directions.get_frame_texture(animation, index).get_size() == Vector2(128, 128), "direction frame must be 128x128")
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	root.add_child(sprite)
	sprite.play("walk")
	for i in 24:
		await process_frame
	if sprite.frame == 0:
		push_error("AnimatedSprite2D did not advance")
		quit(1)
		return
	sprite.queue_free()
	await process_frame
	await integration_checks()
	print("PLAYER MECH: Godot loaded all 56 atlas frames across four views and played walk animation")
	quit()

func require(condition: bool, label: String) -> void:
	if not condition:
		push_error(label)
		quit(1)
		assert(condition, label)

func integration_checks() -> void:
	var Sim = preload("res://gd/simulation.gd")
	var R = preload("res://gd/rules.gd")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.activate()
	var sim = game.sim
	sim.spawn_timer = 999
	var skin = game.battle.player_skin
	require(skin.frames == load("res://assets/sprites/player_mech/player_mech.tres"), "main scene must use new sprite set")
	for direction in ["up", "right", "down", "left"]:
		sim.player.pos = Vector2(420, 380)
		sim.player.cooldown = 0
		sim.bullets.clear()
		sim.update(0.02, direction, true)
		require(skin.rotation_for(direction) == 0.0, "directional sprites must never rotate the whole robot")
		require(sim.player.moving and skin.animation_for(sim.player) == "walk", "moving and firing must preserve walking animation")
		var animation: String = "walk" if direction == "down" else direction + "_walk"
		require(skin.animation_name_for(sim.player) == animation, "movement must select its matching direction")
		require(skin.frame_for(sim.player, sim.elapsed) == skin.frames_for(direction).get_frame_texture(animation, 0), "runtime must actually select direction artwork")
		var muzzle: Vector2 = sim.player.pos + R.VECTOR[direction] * skin.muzzle_distances[direction]
		require(sim.effects.back().pos.is_equal_approx(muzzle), "flash must start at muzzle in each direction")
		require((sim.bullets[0].pos - muzzle).dot(R.VECTOR[direction]) > 0, "bullet must travel forward from muzzle")
	# A long visual barrel must not let shots skip a close wall or a close enemy.
	for direction in ["up", "right", "down", "left"]:
		for kind in ["steel", "brick"]:
			var wall_sim = Sim.new()
			wall_sim.player_muzzle_distances = skin.muzzle_distances.duplicate()
			for row in wall_sim.map:
				for tile in row:
					tile.kind = "floor"
			var center = Vector2(420, 380)
			var wall: Vector2i = Vector2i(center / R.TILE) + Vector2i(R.VECTOR[direction])
			wall_sim.map[wall.y][wall.x] = {"kind": kind, "hp": 3}
			wall_sim.player.pos = center + R.VECTOR[direction] * 3
			wall_sim.player.dir = direction
			wall_sim.player.cooldown = 0
			wall_sim.start()
			wall_sim.spawn_timer = 999
			wall_sim.fire(wall_sim.player)
			for i in 8:
				wall_sim.update(0.01)
			require(wall_sim.bullets.is_empty(), "muzzle must not bypass close " + kind + " wall")
			require(wall_sim.map[wall.y][wall.x].hp == (2 if kind == "brick" else 3), "brick must receive exactly one hit")
		var close_sim = Sim.new()
		close_sim.player_muzzle_distances = skin.muzzle_distances.duplicate()
		close_sim.player.pos = Vector2(420, 380)
		close_sim.player.dir = direction
		close_sim.player.cooldown = 0
		var target = close_sim.make_actor("robot", close_sim.player.pos + R.VECTOR[direction] * 30)
		close_sim.enemies.append(target)
		close_sim.start()
		close_sim.spawn_timer = 999
		close_sim.fire(close_sim.player)
		close_sim.update(0.01)
		require(target.hp == 1 and close_sim.bullets.is_empty(), "long barrel must not skip close enemy")
	# Stop at a steel wall: walking clocks must not continue against an obstacle.
	sim.player.pos = Vector2(146, 140)
	sim.player.shot_clock = 0
	sim.update(0.05, "right")
	require(not sim.player.moving and skin.animation_for(sim.player) == "idle", "blocked movement must show idle")
	sim.player.pos = Vector2(420, 380)
	sim.player.cooldown = 0
	sim.update(0.01, "", true)
	require(skin.animation_for(sim.player) == "attack", "stationary shot must show attack")
	var first = skin.frame_for(sim.player, sim.elapsed)
	sim.update(0.05)
	sim.update(0.02)
	require(skin.frame_for(sim.player, sim.elapsed) != first, "recoil must advance during cooldown")
	sim.pause()
	var snapshot = var_to_bytes([sim.player, sim.elapsed])
	for i in 20:
		sim.update(0.05, "down", true)
	require(snapshot == var_to_bytes([sim.player, sim.elapsed]), "pause must freeze animation and gameplay clocks")
	sim.pause()
	for i in 8:
		sim.update(0.05)
	require(skin.animation_for(sim.player) == "idle", "attack must finish at idle")
	sim.hit_player()
	require(sim.player.hurt_clock > 0, "taking damage must trigger flash")
	sim.player.hp = 1
	sim.invulnerable = 0
	sim.hit_player()
	require(sim.player.hp == 5 and sim.invulnerable == 3 and sim.player.move_clock == 0 and sim.player.shot_clock == 0, "respawn must clear old animation and restore protection")
	game.sim.status = "lost"
	game.activate()
	require(game.sim.wave == 1 and skin.animation_for(game.sim.player) == "idle", "replay must reset animation")
	require(game.sim.player_muzzle_distances == skin.muzzle_distances, "replay must preserve skin muzzle geometry")
	game.queue_free()
	await process_frame
	print("PLAYER MECH INTEGRATION: four separate views, no rotation, moving fire, close walls/enemies, recoil, pause, damage, respawn and replay passed")
