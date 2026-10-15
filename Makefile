GODOT ?= godot
TEST_LOG_DIR ?= /tmp

.PHONY: dev editor import check test test-visual build serve

dev:
	$(GODOT) --path .

editor:
	$(GODOT) --path . --editor

import:
	$(GODOT) --headless --path . --editor --import --quit

check:
	python3 scripts/check_repository.py

test: check
	$(GODOT) --headless --path . --script godot_tests/environment_objects.gd --log-file $(TEST_LOG_DIR)/robot-defense-environment-objects.log
	$(GODOT) --headless --path . --script godot_tests/map_refactor.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-refactor.log
	$(GODOT) --headless --path . --script godot_tests/map_camera.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-camera.log
	$(GODOT) --headless --path . --script godot_tests/map_selection.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-selection.log
	$(GODOT) --headless --path . --script godot_tests/character_selection.gd --log-file $(TEST_LOG_DIR)/robot-defense-character-selection.log
	$(GODOT) --headless --path . --script godot_tests/player_loadout.gd --log-file $(TEST_LOG_DIR)/robot-defense-player-loadout.log
	$(GODOT) --headless --path . --script godot_tests/power_ups.gd --log-file $(TEST_LOG_DIR)/robot-defense-power-ups.log
	$(GODOT) --headless --path . --script godot_tests/acceptance.gd --log-file $(TEST_LOG_DIR)/robot-defense-acceptance.log
	$(GODOT) --headless --path . --fixed-fps 60 --script godot_tests/player_mech_asset.gd --log-file $(TEST_LOG_DIR)/robot-defense-player-mech-asset.log
	$(GODOT) --headless --path . --fixed-fps 60 --script godot_tests/enemy_sprite_asset.gd --log-file $(TEST_LOG_DIR)/robot-defense-enemy-sprite-asset.log
	$(GODOT) --headless --path . --fixed-fps 60 --script godot_tests/map_art_asset.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-art-asset.log

test-visual:
	$(GODOT) --path . --script godot_tests/environment_objects_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-environment-objects-visual.log
	$(GODOT) --path . --script godot_tests/map_camera_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-camera-visual.log
	$(GODOT) --path . --script godot_tests/map_selection_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-selection-visual.log
	$(GODOT) --path . --script godot_tests/character_selection_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-character-selection-visual.log
	$(GODOT) --path . --script godot_tests/player_loadout_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-player-loadout-visual.log
	$(GODOT) --path . --script godot_tests/power_up_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-power-ups-visual.log
	$(GODOT) --path . --script godot_tests/visual_smoke.gd --log-file $(TEST_LOG_DIR)/robot-defense-smoke-visual.log
	$(GODOT) --path . --script godot_tests/player_mech_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-player-mech-visual.log
	$(GODOT) --path . --script godot_tests/enemy_sprite_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-enemy-sprite-visual.log
	$(GODOT) --path . --script godot_tests/map_art_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-map-art-visual.log

build:
	mkdir -p build/web
	$(GODOT) --headless --path . --export-release "Web PWA" build/web/index.html
	python3 scripts/prepare_web_pwa.py build/web/index.html

serve:
	python3 -m http.server 8080 --directory build/web
