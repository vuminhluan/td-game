GODOT ?= godot
TEST_LOG_DIR ?= /tmp

.PHONY: dev editor import check test test-web test-visual build serve

dev:
	$(GODOT) --path .

editor:
	$(GODOT) --path . --editor

import:
	$(GODOT) --headless --path . --editor --import --quit

check:
	python3 scripts/check_repository.py

test: check
	$(GODOT) --headless --path . --script godot_tests/local_coop_map.gd --log-file $(TEST_LOG_DIR)/robot-defense-local-coop-map.log
	$(GODOT) --headless --path . --script godot_tests/local_coop_simulation.gd --log-file $(TEST_LOG_DIR)/robot-defense-local-coop-simulation.log
	$(GODOT) --headless --path . --script godot_tests/local_coop_selection.gd --log-file $(TEST_LOG_DIR)/robot-defense-local-coop-selection.log
	$(GODOT) --headless --path . --script godot_tests/local_coop.gd --log-file $(TEST_LOG_DIR)/robot-defense-local-coop.log
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

test-web:
	$(GODOT) --headless --path . --script godot_tests/web_mobile.gd --log-file $(TEST_LOG_DIR)/robot-defense-web-mobile.log
	python3 scripts/test_prepare_web_pwa.py
	node scripts/test_web_pwa.mjs
	node scripts/test_web_devices.mjs

test-visual:
	$(GODOT) --path . --script godot_tests/local_coop_visual.gd --log-file $(TEST_LOG_DIR)/robot-defense-local-coop-visual.log
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
