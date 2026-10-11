# Enemy mech v1 — QA / provenance

Generated using built-in image_gen through existing ChatGPT access. Sprite-gen 2.43.0 owns preparation, component extraction, atlas composition, GIF/contact previews, inspect and inspect-motion. Runtime conversion from composed manifest uses scripts/install_enemy_direction.py (no image processing). No API key, paid provider fallback, mirror, image rotation or provider-default changes.

Four independently generated views. Own extracted idle frame becomes each direction base-source.png for walk/attack. Actual image prompts are retained under prompts/*-built-in.txt. Layout guides are geometry-only references. Raw rows, rejected rows and extracted frame manifests remain available.

## Inspection evidence

- DOWN: inspect ok=True; warnings: none.
  - idle: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - walk: 6 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - attack: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - Selected retakes: prompts/walk-correction-built-in.txt. Earlier rows retained in raw/*-rejected*.png.
- UP: inspect ok=True; warnings: none.
  - idle: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - walk: 6 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - attack: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
- LEFT: inspect ok=True; warnings: idle: motion presence is too low (0.0093 < 0.0100).
  - idle: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - walk: 6 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - attack: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
- RIGHT: inspect ok=True; warnings: none.
  - idle: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - walk: 6 frames, exact duplicates=0, visible motion=True, edge contact frames=[].
  - attack: 4 frames, exact duplicates=0, visible motion=True, edge contact frames=[].

## Limits

Native RGBA cleanup uses key/fringe thresholds=0, fringe_delta=0, fringe_unmix_reach=0, spill_max_fraction=0. This preserves the generated red armor: default magenta despill had shifted some red plates toward yellow. Exact options are retained in frames/frames-manifest.json.extract_args and provenance.json. All extraction/compose stages remain canonical sprite-gen; no hand-painted or custom-cut frames.

Motion/contact reports are evidence, not certification of seamless locomotion. No manual same-foot contact spans or isolated foot ROI were supplied: stride_verified=false. Tracks have no biped foot contacts. All source frame durations were retained; no frame reversal, duplicate deletion or timing changes were used to hide motion defects. Minimal idle motion warnings are retained deliberately. Minor AI detail/pose variation remains, and wrap seams are not certified.

The native visual board covers 24 animations and eight in-game views; the in-game board also shows damaged HP bars. Runtime test coverage: 264 enemy checks, 234 existing acceptance checks, player 56-frame/integration pass. Web PWA has not been exported or verified.
