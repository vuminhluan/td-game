GODOT ?= godot

.PHONY: dev editor import test test-visual build

dev:
	$(GODOT) --path .

editor:
	$(GODOT) --path . --editor

import:
	$(GODOT) --headless --path . --editor --import --quit

test:
	$(GODOT) --headless --path . --script godot_tests/acceptance.gd
	$(GODOT) --headless --path . --fixed-fps 60 --script godot_tests/player_mech_asset.gd
	$(GODOT) --headless --path . --fixed-fps 60 --script godot_tests/enemy_sprite_asset.gd
	$(GODOT) --headless --path . --fixed-fps 60 --script godot_tests/map_art_asset.gd

test-visual:
	$(GODOT) --path . --script godot_tests/visual_smoke.gd
	$(GODOT) --path . --script godot_tests/player_mech_visual.gd
	$(GODOT) --path . --script godot_tests/enemy_sprite_visual.gd
	$(GODOT) --path . --script godot_tests/map_art_visual.gd

build:
	mkdir -p build/web
	$(GODOT) --headless --path . --export-release "Web PWA" build/web/index.html
