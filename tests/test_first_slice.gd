extends SceneTree

func _initialize() -> void:
	call_deferred("_run_first_slice")

func _run_first_slice() -> void:
	# Keep this test deterministic even if it is rerun in a reused editor profile.
	var save_path := ProjectSettings.globalize_path("user://first_stage_progress.cfg")
	var settings_path := ProjectSettings.globalize_path("user://first_stage_settings.cfg")
	if FileAccess.file_exists("user://first_stage_progress.cfg"):
		DirAccess.remove_absolute(save_path)
	if FileAccess.file_exists("user://first_stage_settings.cfg"):
		DirAccess.remove_absolute(settings_path)
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if not _check(packed_scene != null, "main scene could not be loaded"):
		return

	var game := packed_scene.instantiate() as Node3D
	if not _check(game != null, "main scene root is not Node3D"):
		return
	root.add_child(game)
	await process_frame

	var player := game.get("player") as CharacterBody3D
	var key := game.get_node_or_null("BrassKey") as Node3D
	var letter := game.get_node_or_null("TornLetter") as Node3D
	var chest := game.get_node_or_null("MemoryChest") as Node3D
	var station_clock := game.get_node_or_null("StationClock") as Node3D
	if not _check(player != null, "player was not created"):
		return
	if not _check(key != null and letter != null and chest != null, "one or more story props are missing"):
		return
	if not _check(chest.get_node_or_null("ChestFrontPanel_L") != null and chest.get_node_or_null("ChestFrontPanel_R") != null and chest.find_child("LidSealMedallion", true, false) != null, "the memory chest is missing its crafted panel and lid details"):
		return
	if not _check(station_clock != null and station_clock.is_in_group("interactables"), "the next carriage clock interaction is missing"):
		return
	var window_vista := game.get_node_or_null("WindowVista") as Node3D
	if not _check(window_vista != null and window_vista.get_child_count() == 9, "the carriage windows are missing their floating-island vista and distant station beacons"):
		return

	# First-person hands are a required part of every story interaction, not an optional visual.
	var hands := game.get("first_person_hands") as Node3D
	var camera := game.get("camera") as Camera3D
	if not _check(hands != null and camera != null, "first-person hands or camera were not created"):
		return
	if not _check(bool(game.get("world_intro_active")) and game.get("world_intro_root") != null, "the worlds train arrival scene did not start before stage one"):
		return
	if not _check(game.get("world_intro_camera") is Camera3D, "the worlds arrival camera is missing"):
		return
	# Input over the opening story card must not start a hidden look gesture.
	var blocked_touch := InputEventScreenTouch.new()
	blocked_touch.index = 7
	blocked_touch.position = Vector2(900.0, 400.0)
	blocked_touch.pressed = true
	game.call("_input", blocked_touch)
	if not _check(int(game.get("touch_look_id")) == -1 and int(game.get("touch_move_id")) == -1, "touch input leaked through the opening story card"):
		return
	var intro_root := game.get("world_intro_root") as Node3D
	if not _check(intro_root.get_node_or_null("LocomotiveConnectingRod_L") != null and intro_root.get_node_or_null("LocomotiveConnectingRod_R") != null, "the establishing locomotive is missing its wheel connecting rods"):
		return
	if not _check(intro_root.find_children("SoftSteamPuff_*", "MeshInstance3D", true, false).size() == 3, "the establishing locomotive is missing its restrained steam plume"):
		return
	game.call("_enter_stage_one")
	if not _check(not bool(game.get("world_intro_active")) and camera.current, "entering stage one did not switch to the carriage camera"):
		return
	game.call("_close_story_card")
	if not _check(hands.get_child_count() >= 16, "first-person hands are missing sleeves, cuffs, palms, fingers, or thumbs"):
		return
	if not _check(hands.get_node_or_null("Thumb_L") != null and hands.get_node_or_null("Thumb_R") != null, "both visible thumbs must be present for a readable hand silhouette"):
		return
	if not _check(hands.get_parent() == camera, "first-person hands are not attached to the camera view"):
		return
	if not _check(not hands.visible, "first-person hands must stay hidden during normal exploration"):
		return

	# Each interaction gesture must visibly move the view model and then restore it.
	# This checks animation behavior without changing player movement or camera input.
	for action_name in ["take", "read", "open"]:
		game.call("_play_hand_action", action_name)
		var active_hand_tween := game.get("hand_action_tween") as Tween
		if not _check(hands.visible, "hands did not appear for interaction: " + action_name):
			return
		if not _check(active_hand_tween != null and active_hand_tween.is_running(), "hand action did not start its animation: " + action_name):
			return
		await create_timer(0.80).timeout
		if not _check(hands.position.distance_to(Vector3.ZERO) < 0.01, "hand action did not return to neutral: " + action_name):
			return
		if not _check(not hands.visible, "hands stayed visible after interaction: " + action_name):
			return

	# A chest must not open until both clues have been found and understood.
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(not bool(game.get("chest_open")), "chest opened without the brass key"):
		return
	game.call("_close_story_card")

	# Find the key on the floor.
	player.global_position = key.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(bool(game.get("has_key")), "interacting with the brass key did not collect it"):
		return
	if not _check(int(game.get("mystery_beat_count")) == 1, "key pickup did not trigger the first suspense beat"):
		return
	game.call("_close_story_card")
	await create_timer(0.80).timeout
	var held_key := game.get("held_key_prop") as Node3D
	if not _check(held_key != null and is_instance_valid(held_key), "picked-up brass key vanished after the hand animation"):
		return
	if not _check(held_key.get_parent() == hands, "held brass key is not attached to the persistent first-person view model"):
		return
	if not _check(not hands.visible, "hands should return to hidden exploration state while retaining the held key"):
		return

	# The key alone is insufficient: the letter must be read first.
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(not bool(game.get("chest_open")), "chest opened before the letter was read"):
		return
	game.call("_close_story_card")

	player.global_position = letter.global_position + Vector3(0.0, 0.0, 0.20)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(bool(game.get("letter_read")), "interacting with the torn letter did not mark it read"):
		return
	if not _check(int(game.get("mystery_beat_count")) == 2, "reading the letter did not trigger the second suspense beat"):
		return
	if not _check(bool(game.get("letter_inspecting")), "reading the letter did not enter physical inspection mode"):
		return
	if not _check(not bool(game.get("story_card_open")), "reading the letter replaced the physical paper with a story overlay"):
		return
	var held_letter := game.get("held_letter_prop") as Node3D
	if not _check(held_letter != null and held_letter.get_parent() == hands and hands.visible, "the readable letter is not visible between the player's hands"):
		return
	var physical_message := held_letter.get_node_or_null("LetterMessage") as Label3D
	if not _check(physical_message != null and physical_message.text.contains("DO NOT LET IT FINISH"), "the fresh clock warning is missing from the physical paper"):
		return
	if not _check(str(interact_button.text).contains("CLOSE LETTER"), "the physical letter has no clear close action"):
		return
	game.call("_interact")
	if not _check(not bool(game.get("letter_inspecting")) and not hands.visible and game.get("held_letter_prop") == null, "closing the letter did not restore normal exploration")
		return

	# With both prerequisites met, the chest should open and its lid should move.
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(bool(game.get("chest_open")), "chest did not open after key and letter"):
		return
	if not _check(int(game.get("mystery_beat_count")) == 3, "opening the chest did not trigger the final suspense beat"):
		return
	if not _check(is_instance_valid(game.get("held_key_prop")) and (game.get("held_key_prop") as Node3D).get_parent() == hands, "chest-opening hand animation discarded the persistent brass key"):
		return
	var chest_story := str(game.get("story_body").text)
	if not _check(chest_story.contains("MEMORY RECOVERED"), "chest reveal did not reward the player with the recovered-memory story card"):
		return
	# The chest lid now opens with a short cinematic tween.
	await create_timer(0.85).timeout
	var lid := chest.get_node_or_null("Lid") as Node3D
	if not _check(lid != null and is_equal_approx(lid.rotation.x, deg_to_rad(-72.0)), "chest lid did not reach the open position"):
		return

	# The chest reward must exist as a visible, inspectable 3D photograph after the reveal beat.
	var photo := chest.get_node_or_null("SunsetPhotograph") as Node3D
	if not _check(photo != null and photo.visible, "the sunset photograph did not appear after the chest reveal"):
		return
	if not _check(photo.is_in_group("interactables") and photo.get_node_or_null("StationName") != null, "the photograph is not a readable interactable reward"):
		return
	var photo_card := photo.get_node_or_null("PhotographCard") as MeshInstance3D
	var photo_mesh := photo_card.mesh as BoxMesh if photo_card else null
	if not _check(photo_mesh != null and photo_mesh.size.y > photo_mesh.size.z * 10.0, "the photograph backing is not oriented as a readable upright card"):
		return
	var station_label := photo.get_node_or_null("StationName") as Label3D
	if not _check(station_label != null and station_label.position.y > -0.16 and station_label.position.y < 0.0, "the station name is not positioned on the photograph face"):
		return
	game.call("_close_story_card")
	player.global_position = photo.global_position + Vector3(0.0, 0.0, 0.22)
	game.call("_interact")
	if not _check(bool(game.get("story_card_open")) and str(game.get("story_body").text).contains("SUNSET STATION"), "inspecting the photograph did not reveal its station clue"):
		return
	game.call("_close_story_card")

	# Pause must freeze movement, expose settings, and persist look sensitivity.
	var before_pause_position := player.global_position
	game.call("_toggle_pause_menu")
	if not _check(bool(game.get("game_paused")) and (game.get("pause_overlay") as ColorRect).visible, "pause menu did not open as a modal overlay"):
		return
	game.call("_physics_process", 0.1)
	if not _check(player.global_position.distance_to(before_pause_position) < 0.001, "player moved while the pause menu was open"):
		return
	var sensitivity_slider := game.get("look_sensitivity_slider") as HSlider
	if not _check(sensitivity_slider != null, "pause menu is missing the look sensitivity setting"):
		return
	sensitivity_slider.value = 0.006
	if not _check(is_equal_approx(float(game.get("look_sensitivity")), 0.006), "look sensitivity slider did not update the active camera setting"):
		return
	var saved_settings := ConfigFile.new()
	if not _check(saved_settings.load("user://first_stage_settings.cfg") == OK and is_equal_approx(float(saved_settings.get_value("settings", "look_sensitivity", 0.0)), 0.006), "look sensitivity setting was not persisted"):
		return
	game.call("_toggle_pause_menu")
	if not _check(not bool(game.get("game_paused")) and not (game.get("pause_overlay") as ColorRect).visible, "resume did not close the pause menu"):
		return

	# The player must be able to leave the first carriage and activate the clock.
	game.call("_close_story_card")
	player.global_position = station_clock.global_position + Vector3(0.0, -2.2, 0.1)
	game.call("_interact")
	if not _check(bool(game.get("story_card_open")), "the clock carriage interaction did not open its story card"):
		return
	game.call("_close_story_card")
	if not _check(int(game.call("_inventory_count")) == 3, "inventory does not show the three completed story items"):
		return
	# Once the chest is open, the rear boundary must no longer trap the player in carriage one.
	player.position = Vector3(0.0, 0.1, -14.0)
	game.call("_physics_process", 0.0)
	if not _check(player.position.z < -5.1, "the player is still blocked from reaching the clock carriage"):
		return
	if not _check(str(game.call("_objective_text")).to_lower().contains("complete"), "completion objective was not displayed"):
		return

	# Verify that a relaunch restores the solved puzzle instead of losing progress.
	game.call("_save_progress")
	game.queue_free()
	await process_frame
	var resumed_game := packed_scene.instantiate() as Node3D
	root.add_child(resumed_game)
	await process_frame
	if not _check(is_equal_approx(float(resumed_game.get("look_sensitivity")), 0.006), "look sensitivity was not restored on relaunch"):
		return
	var resumed_slider := resumed_game.get("look_sensitivity_slider") as HSlider
	if not _check(resumed_slider != null and is_equal_approx(resumed_slider.value, 0.006), "settings slider did not reflect the saved look sensitivity"):
		return
	if not _check(bool(resumed_game.get("has_key")), "saved key progress was not restored"):
		return
	var resumed_hands := resumed_game.get("first_person_hands") as Node3D
	var resumed_held_key := resumed_game.get("held_key_prop") as Node3D
	if not _check(resumed_held_key != null and is_instance_valid(resumed_held_key), "saved key progress did not rebuild the held 3D key"):
		return
	if not _check(resumed_hands != null and resumed_held_key.get_parent() == resumed_hands, "resumed held key is detached from the first-person view model"):
		return
	if not _check(not resumed_hands.visible, "resumed exploration should hide hands without deleting the held key"):
		return
	if not _check(bool(resumed_game.get("letter_read")), "saved letter progress was not restored"):
		return
	if not _check(bool(resumed_game.get("chest_open")), "saved chest progress was not restored"):
		return
	var resumed_chest := resumed_game.get_node_or_null("MemoryChest") as Node3D
	var resumed_photo := resumed_chest.get_node_or_null("SunsetPhotograph") as Node3D if resumed_chest else null
	if not _check(resumed_photo != null and resumed_photo.visible, "saved chest progress did not restore the visible photograph reward"):
		return
	print("FIRST_SLICE_TESTS_PASSED: key -> letter -> memory chest -> sunset photograph -> save/resume")
	resumed_game.queue_free()
	await process_frame
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FIRST_SLICE_TEST_FAILED: " + message)
	quit(1)
	return false
