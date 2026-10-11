# Player mech v3 — provenance and validation

Nguồn hiện hành: `assets/generated/sprites/player_mech/down`. Các đường dẫn `raw/`, `prompts/`, `references/`, `frames/` và `qa/` bên dưới tương đối với nguồn này. Đây là bản ghi của lần tạo asset; phiên bản nêu trong nội dung là lịch sử generation, không phải thư mục cần khôi phục.

Generated using the built-in image_gen tool in the current Codex chat, without API-key providers. The sprite-gen 2.43.0 installed pipeline performed preparation, extraction, alpha cleanup, atlas composition, preview and inspection. Local CLI generation was unavailable for the configured ChatGPT model; no account/model configuration was changed.

Identity: user-provided mech.png and accepted DOWN-facing v2 base (`base-source.png`). Idle and attack reuse v2 generated rows. Walk was generated as six separate poses, then edited with image_gen to improve the leg transitions while preserving body identity and forward cannon/toe direction. No frames were hand-painted or re-ordered after extraction. Prompt and reference files are retained in this run.

The final atlas has 6 columns by 3 rows, 768x384 RGBA, 128x128 cells. Idle has 4 frames, walk 6, attack 4: 14 occupied regions. Extraction/composition succeeded. `sprite-gen inspect --run-dir ... --no-write` returned ok with no errors or warnings for all three states. Atlas poses were visually inspected for orientation, complete limbs and chroma removal. Minor body/pose variation remains; automated inspection does not certify seamless animation or foot contact.

Godot 4.7.2 loaded all 14 regions and advanced AnimatedSprite2D walk playback. Main-scene integration tests passed for four aligned directions, moving fire, blocked movement, stationary recoil, pause, damage flash, respawn and replay. Gameplay acceptance: 234 checks, 0 failures. Native Compatibility rendering captured desktop, paused, ready, mobile and small layouts; desktop/mobile screenshots were visually inspected with the new player in the battlefield.

At this generation stage the single DOWN view was rotated for four directions. The current game instead retains this atlas only for DOWN, with scale 0.5, anchor (64,50) and muzzle offset 15; the separately generated UP/RIGHT/LEFT views are documented in directions.md. Walk remains active during moving fire; stationary attack timing is synchronized to the gameplay weapon cooldown. QA GIFs show source animation rates, which differ from the gameplay attack timing.

Optional curation/default questions previously cancelled by the user were skipped; no provider defaults were saved.
