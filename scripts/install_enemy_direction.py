#!/usr/bin/env python3
import argparse
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ('down', 'up', 'left', 'right')

def install(kind, direction, run, anchor, scale, muzzle, sheet_name):
    manifest = json.loads((run / 'manifest.json').read_text())
    rows = manifest['frame_layout']['rows']
    metadata = manifest['animation']['rows']
    for state in ('idle', 'walk', 'attack'):
        if state not in rows or not rows[state]:
            raise ValueError(f'Missing {state} in composed manifest')
    target = ROOT / 'assets/sprites' / f'enemy_{kind}'
    target.mkdir(parents=True, exist_ok=True)
    sheet_name = sheet_name or f'{direction}.png'
    if Path(sheet_name).name != sheet_name or not sheet_name.endswith('.png'):
        raise ValueError('--sheet-name must be a PNG basename')
    shutil.copy2(run / manifest['sprite_sheet_alpha'], target / sheet_name)
    texture_path = f'res://assets/sprites/enemy_{kind}/{sheet_name}'
    lines = ['[gd_resource type="SpriteFrames" load_steps=16 format=3]', '', f'[ext_resource type="Texture2D" path="{texture_path}" id="1"]', '']
    animations = []
    total = sum(len(rows[s]) for s in ('idle', 'walk', 'attack'))
    lines[0] = f'[gd_resource type="SpriteFrames" load_steps={total + 2} format=3]'
    for state in ('idle', 'walk', 'attack'):
        ids = []
        for index, rect in enumerate(rows[state]):
            name = f'{state}_{index}'
            lines += [f'[sub_resource type="AtlasTexture" id="{name}"]', 'atlas = ExtResource("1")', f'region = Rect2({rect["x"]}, {rect["y"]}, {rect["w"]}, {rect["h"]})', '']
            ids.append('{"duration": 1.0, "texture": SubResource("' + name + '")}')
        meta = metadata[state]
        animations.append('{"frames": [' + ', '.join(ids) + '], "loop": ' + str(meta['loop']).lower() + ', "name": &"' + state + '", "speed": ' + str(float(meta['fps'])) + '}')
    lines += ['[resource]', 'animations = [' + ',\n'.join(animations) + ']', '']
    (target / f'{direction}_frames.tres').write_text('\n'.join(lines))
    (target / f'{direction}.tres').write_text(f'''[gd_resource type="Resource" load_steps=3 format=3]

[ext_resource type="Script" path="res://gd/enemy_direction.gd" id="1"]
[ext_resource type="SpriteFrames" path="res://assets/sprites/enemy_{kind}/{direction}_frames.tres" id="2"]

[resource]
script = ExtResource("1")
frames = ExtResource("2")
anchor = Vector2({anchor[0]}, {anchor[1]})
texture_scale = {scale}
muzzle_distance = {muzzle}
''')
    manifest['runtime_sheet'] = texture_path
    manifest['runtime_frames'] = f'res://assets/sprites/enemy_{kind}/{direction}_frames.tres'
    manifest['source_run'] = str(run.relative_to(ROOT)) if run.is_relative_to(ROOT) else str(run)
    manifest['geometry'] = {'anchor': anchor, 'scale': scale, 'muzzle_distance': muzzle}
    (target / f'{direction}_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    skin = target / 'enemy_skin.tres'
    if not skin.exists():
        ext = '\n'.join(f'[ext_resource type="Resource" path="res://assets/sprites/enemy_{kind}/{d}.tres" id="{i+2}"]' for i,d in enumerate(DIRECTIONS))
        mapping = ', '.join(f'"{d}": ExtResource("{i+2}")' for i,d in enumerate(DIRECTIONS))
        skin.write_text('[gd_resource type="Resource" load_steps=6 format=3]\n\n[ext_resource type="Script" path="res://gd/enemy_skin.gd" id="1"]\n' + ext + '\n\n[resource]\nscript = ExtResource("1")\ndirections = {' + mapping + '}\n')
    print(f'Installed enemy_{kind}/{direction}: {total} frames from manifest')

if __name__ == '__main__':
    p = argparse.ArgumentParser(description='Install one composed sprite-gen direction without rewriting the other views.\nUses only the canonical manifest rects. Run with any Python 3 (stdlib only).\n')
    p.add_argument('--kind', choices=('tank','mech'), required=True)
    p.add_argument('--direction', choices=DIRECTIONS, required=True)
    p.add_argument('--run-dir', type=Path, required=True)
    p.add_argument('--anchor', nargs=2, type=float, default=(64,64), metavar=('X','Y'))
    p.add_argument('--scale', type=float, default=0.5)
    p.add_argument('--muzzle', type=float, default=20.0)
    p.add_argument('--sheet-name', help='Versioned PNG filename for a replacement')
    args = p.parse_args()
    install(args.kind, args.direction, args.run_dir.resolve(), args.anchor, args.scale, args.muzzle, args.sheet_name)
