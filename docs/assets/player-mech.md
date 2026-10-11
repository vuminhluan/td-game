# Player mech — four directional views

Reusable creation/replacement/integration workflow: [Quy trình sprite](../workflows/sprites.md).

The game uses four separately drawn views, with no whole-image rotations or runtime mirroring. DOWN retains the previously accepted artwork. UP shows rear armor/vents and heel backs. LEFT and RIGHT have separately generated side views with cannon and toes aimed along movement.

Each view has idle 4 frames at 4 FPS, walk 6 at 10 FPS, and attack 4 at 12 FPS (non-loop): 56 frames total, each 128x128.

- `player_mech.png` / `player_mech.tres` / `manifest.json`: DOWN, 768x384, 14 frames.
- `player_mech_directions.png` / `player_mech_directions.tres` / `directions_manifest.json`: UP/RIGHT/LEFT, 768x1152, 42 frames. The resource uses exact composed manifest regions rather than assuming a row order.
- `player_skin.tres`: runtime skin assigned to `BattleView.player_skin`.

`gd/player_skin.gd` chooses frames using direction and simulation clocks. Movement plays walk only when position changes; stationary fire plays attack during the 0.23 second weapon cooldown. Moving fire preserves walking legs and uses the simulation muzzle effect. Pause freezes clocks. Damage flash, respawn immunity and foliage ordering remain active. Replay/respawn reset animation clocks.

The skin owns per-direction anchors and muzzle distances. Scale is 0.5. Anchors: DOWN (64,50), UP (64,54), RIGHT (45,45), LEFT (83,45). Muzzle distances: DOWN 15, UP 23, RIGHT 31, LEFT 33 world units. The battle view supplies these distances to each new simulation, including replay. The simulation traces the extended barrel path before spawning a projectile so nearby steel, brick or enemies cannot be skipped. Collisions retain the gameplay collider independent of alpha.

## Replace the art

For identical layouts, replace the two PNGs. For different layouts, create SpriteFrames with idle/walk/attack for DOWN and `up_idle`, `up_walk`, `up_attack`, `left_*`, `right_*` in the directional resource. Assign resources, scale, directional anchors and muzzle distances on the skin. Keep barrel axis aligned with movement. Setting directional_frames to null preserves the original single-view rotation fallback for another skin.

## Preview and validation

```sh
godot --path . scenes/player_mech_preview.tscn
godot --headless --path . --fixed-fps 60 --script godot_tests/player_mech_asset.gd
godot --path . --script godot_tests/player_mech_visual.gd
make test
```

Preview shows all 12 animations. Visual test captures four directions in the main scene plus `docs/images/player-mech-four-directions.png`. Main-scene integration tests cover selecting actual direction textures, zero rotation, moving fire, walls, close enemies, pause, damage, respawn and replay. Gameplay acceptance has 234 checks.

Generated via the built-in image tool without API keys, with sprite-gen 2.43.0 preparation/extraction/atlas/QA. Sources: `assets/generated/sprites/player_mech/down/` (DOWN) and `assets/generated/sprites/player_mech/directions/` (new directions). Prompts and raw rows are retained. Minor pose/detail variation remains; locomotion loops are experimental rather than certified seamless motion.
