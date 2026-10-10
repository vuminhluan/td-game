# Player mech v2 — provenance and QA

## Generation

- Skill: sprite-gen 2.43.0, installed from aldegad/sprite-gen.
- Identity reference: supplied mech.png, then generated base-source.png.
- All images were generated through the built-in image_gen tool in the current Codex chat. No API-key provider was used.
- The original gen-set --provider codex attempt failed because the local Codex CLI rejected its configured gpt-6.1-sol model for the signed-in ChatGPT account. No model/account configuration was changed. Generation alone was performed in this chat; extraction, placement, atlas, previews and inspect used the installed sprite-gen pipeline unchanged.
- Prompt set: prompts/idle.txt, prompts/walk.txt, prompts/attack.txt. Each call also explicitly identified the base as identity, guide as geometry, required exactly four separate complete sprites, and reiterated DOWN-facing cannon and toes, no arms or tracks. Walk reiterated alternating leg phases; attack reiterated neutral/recoil/recovery/neutral.
- v1 base rejected: cannon pointed up while feet pointed down. v2 replaced it before any final sheet publication.
- Canonical orientation: DOWN / south. Feet, muzzle and locomotion are aligned. This is a single-view sheet; the game can rotate the whole sprite for its four directions. It is not four independently drawn views.
- Camera is elevated frontal/top-down stylization, not a verified strict orthographic overhead projection.

## Output and static QA

- 512x384 RGBA atlas, 4 columns, 3 rows; each cell is 128x128.
- idle / walk / attack: four nonempty frames each. Extract and compose returned ok; inspect returned no errors or warnings.
- Atlas and all contact-sheet poses visually inspected. No chopped limbs, empty cells or visible magenta background observed. Cannon points down with toe tips in every frame.
- Native Godot 4.7.2 imported the sheet, loaded the SpriteFrames resource, validated all 12 regions, and advanced the walk animation.

## Motion status

- idle: best-effort. Slight torso/armor variation between poses; not certified seamless.
- walk: experimental. Alternating foot reach is visible, but four poses offer limited passing/contact transitions and mild body drift. No production locomotion or seamless-contact guarantee.
- attack: best-effort. Braced pose, visible barrel recoil/attached flash, and recovery are present; detailed timing needs visual approval.
- GIFs were generated at requested state rates. Live Computer Use observation of Godot was unavailable because app access was not approved. Static pose review and native animation playback were verified; live-loop visual review remains unverified.
- No frame order changes, hand-painted animation repairs or timing changes were used to conceal defects.

## Optional choices

The user cancelled the optional curation/defaults questions. Curation was skipped and no preferences were saved. The finish guide only offers saving defaults; this has no effect on the delivered files.
