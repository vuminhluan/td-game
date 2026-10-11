# Player mech v4 — UP / RIGHT / LEFT

Nguồn hiện hành: `assets/generated/sprites/player_mech/directions`. Các đường dẫn `raw/`, `prompts/`, `references/`, `frames/` và `qa/` bên dưới tương đối với nguồn này. Đây là bản ghi của lần tạo asset; phiên bản nêu trong nội dung là lịch sử generation, không phải thư mục cần khôi phục.

## Generation and reference chain

Sprite-gen 2.43.0 prepared the numeric request, prompts and layout guides. Native image_gen generated all raster rows in this ChatGPT-authenticated chat, without an API-key provider. The local CLI model incompatibility from v2 remains; no provider/account configuration was changed. Extraction, alpha cleanup, placement, composition, preview and inspection used the installed sprite-gen engine.

Stage 1: idle rows use accepted v3 base-source.png as initial identity plus the matching idle layout guide. The first UP idle was rejected because front shin/toe features still faced DOWN; image_gen redrew the bodies/legs from behind with rear vents, pistons and heel backs. RIGHT and LEFT idle were drawn separately; no mirroring was used.

Stage 2: every action row uses its own direction's extracted idle frame-0 as identity and its own layout guide. LEFT walk/attack additionally attach the corresponding RIGHT raw row for rhythm/scale only. The original base is not attached to final action rows. UP walk was generated again after review showed alternating extremes without enough passing phases; final raw/up_walk.png includes contact/passing poses. The rejected walk is retained as raw/up_walk-rejected.png.

Request: input-request.json and sprite-request.json in the source directory. Prepared prompts under prompts/; references under references/. The image calls additionally identify each reference role and lock the required direction. Correction instructions requested true rear view and ordered left-contact, lift, passing, right-contact, lift, passing phases. No hand-painted, mirrored, re-ordered or re-timed source frames.

## Pipeline checks

The initial centroid alignment placed the long LEFT barrel against the cell border. The engine's bbox-center fit option was selected and extraction rerun; full barrel padding is now preserved. Output: 768x1152 RGBA atlas, 42 occupied 128x128 regions. Three states per direction, counts 4/6/4. The DOWN v3 sheet is retained separately for 56 runtime frames in total.

Extract/compose returned ok without errors/warnings. Inspect returned ok for nine states without errors/warnings. All contact sheets were visually reviewed: separate complete silhouettes, clean alpha, UP rear view, side guns/toes aligned, upright bodies rather than image rotations. Native Godot preview displays all 12 state/view combinations.

Idle/attack: small visual detail and pose variations, especially transitions between generated idle and action rows. Attack has readable braced/flash/recovery poses. Walks: leg articulation is present; UP retake improves passing phases. All walk loops remain experimental: foot-contact stability and seamless motion are not certified. inspect-motion reports real changing frames without exact duplicates for all three new walks; ground contact stays unknown because no manual stance/isolated-foot ROI was declared. Its needs-review status is retained rather than treated as a pass.

## Game integration

Directional SpriteFrames and view-specific anchors/muzzle distances are assigned via player_skin.tres. Actual textures are selected by direction; player rotation is zero. Main-game native Compatibility captures were reviewed for all four directions, mobile and the 12-animation board. All four game captures are produced by godot_tests/player_mech_visual.gd; the board is saved in docs/images/.

Godot 4.7.2 acceptance: 234 checks, 0 failures. Player tests load all 56 frames and cover view selection, moving fire, close steel/brick, close enemies, stationary recoil, pause, damage, respawn and replay. Extended barrel lengths are traced for collisions before bullet spawn.

Optional curation stays skipped, following the user's earlier cancelled choices. No defaults saved. Web PWA export remains dependent on installing the matching export templates; this task validates native Godot, not a browser build.
