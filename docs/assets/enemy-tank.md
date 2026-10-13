# Enemy tank

Four independently drawn direction atlases. Runtime entry: `enemy_skin.tres`.

Replacement/integration instructions: [Quy trình enemy sprite](../workflows/enemy-sprites.md).

Source: `assets/generated/sprites/enemy_tank/`. Each direction has idle 4 / walk 6 / attack 4 frames at 128×128, with its own SpriteFrames and geometry resource.

## Direction size calibration — 13/10/2026

The original atlases occupy different opaque areas: DOWN 9235, UP 6900, LEFT 6230 and RIGHT 6084 pixels in the first idle frame. Applying 0.5 to every view made DOWN visibly larger. Runtime scales are now DOWN 0.408, UP 0.472, LEFT/RIGHT 0.5. Their opaque areas in world space differ by about 2.4%, while each view retains its natural perspective. Anchors stay in source pixels; muzzle distances scale together to 16.32, 20.768, 34 and 35 units. Gameplay colliders and HP remain independent of artwork scale.

Runtime and generation manifests record the calibrated geometry. The native animation preview applies the same directional scale. `godot_tests/enemy_sprite_asset.gd` checks the ratio of maximum/minimum visible area is below 1.10 and verifies muzzle collisions. Enemy attack direction and movement behavior are described in [Combat](../features/combat.md).

Validation: full `make test` passed after this correction; enemy sprite regression has 305 checks, including all four aimed directions and directional area consistency. Native renders updated `docs/images/enemy-sprites-in-game.png` and `docs/images/enemy-sprites-four-directions.png`.
