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
	var active_environment := game.get("world_environment") as WorldEnvironment
	var status_hud := game.get("status_label") as Label
	var interact_hud := game.get("interact_button") as Button
	if not _check(active_environment != null and active_environment.environment == game.get("intro_environment"), "opening train did not activate its dedicated lighting environment"):
		return
	if not _check(game.find_children("*", "WorldEnvironment", true, false).size() == 1, "scene contains conflicting WorldEnvironment nodes"):
		return
	if not _check(status_hud != null and interact_hud != null and not status_hud.visible and not interact_hud.visible, "gameplay HUD remained visible behind the opening story card"):
		return

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
	if not _check(intro_root.find_child("LocomotiveConnectingRod_L", true, false) != null and intro_root.find_child("LocomotiveConnectingRod_R", true, false) != null, "the establishing locomotive is missing its wheel connecting rods"):
		return
	if not _check(intro_root.find_children("SoftSteamPuff_*", "MeshInstance3D", true, false).size() == 3, "the establishing locomotive is missing its restrained steam plume"):
		return
	if not _check(intro_root.find_child("Smokebox front door", true, false) != null or intro_root.find_child("Circular locomotive smokebox door", true, false) != null, "the locomotive front still reads as a plain boiler without a crafted smokebox"):
		return
	if intro_root.get_node_or_null("ProductionLocomotive") != null:
		var production_boiler := intro_root.find_child("Pressure boiler | enamel barrel", true, false) as MeshInstance3D
		if production_boiler != null:
			var boiler_bounds := production_boiler.mesh.get_aabb().size
			if not _check(boiler_bounds.z > boiler_bounds.y * 2.0, "the production locomotive boiler axis is sideways instead of following the rails"):
				return
	if not _check(intro_root.get_child_count() >= 300, "the establishing vista is missing its complete railway and world asset set"):
		return
	if not _check(intro_root.get_node_or_null("ConnectedWorldTerrain_00_L") != null, "the opening vista is missing the terrain beside the railway"):
		return
	if not _check(intro_root.get_node_or_null("Stone railway viaduct span 00") != null, "the railway is missing its visible viaduct link"):
		return
	game.call("_enter_stage_one")
	if not _check(not bool(game.get("world_intro_active")) and camera.current, "entering stage one did not switch to the carriage camera"):
		return
	if not _check(active_environment.environment == game.get("carriage_environment"), "entering stage one did not restore the carriage lighting environment"):
		return
	game.call("_close_story_card")
	if not _check(status_hud.visible and interact_hud.visible, "closing the story card did not restore the gameplay HUD"):
		return

	# Exercise the same multi-touch path used on Android: left-side movement,
	# right-side camera look, and release cleanup.
	var viewport_width := game.get_viewport().get_visible_rect().size.x
	var viewport_height := game.get_viewport().get_visible_rect().size.y
	var yaw_before_touch := float(game.get("yaw"))
	var pitch_before_touch := float(game.get("pitch"))
	var look_press := InputEventScreenTouch.new()
	look_press.index = 4
	look_press.position = Vector2(viewport_width * 0.58, viewport_height * 0.52)
	look_press.pressed = true
	game.call("_input", look_press)
	if not _check(int(game.get("touch_look_id")) == 4, "right-side Android touch did not begin camera look"):
		return
	var look_drag := InputEventScreenDrag.new()
	look_drag.index = 4
	look_drag.position = look_press.position + Vector2(36.0, -18.0)
	look_drag.relative = Vector2(36.0, -18.0)
	game.call("_input", look_drag)
	if not _check(not is_equal_approx(float(game.get("yaw")), yaw_before_touch) and not is_equal_approx(float(game.get("pitch")), pitch_before_touch), "right-side touch drag did not rotate the camera"):
		return
	var look_release := InputEventScreenTouch.new()
	look_release.index = 4
	look_release.position = look_drag.position
	look_release.pressed = false
	game.call("_input", look_release)
	if not _check(int(game.get("touch_look_id")) == -1, "camera touch remained latched after finger release"):
		return

	var move_press := InputEventScreenTouch.new()
	move_press.index = 5
	move_press.position = Vector2(viewport_width * 0.20, viewport_height * 0.58)
	move_press.pressed = true
	game.call("_input", move_press)
	var move_drag := InputEventScreenDrag.new()
	move_drag.index = 5
	move_drag.position = move_press.position + Vector2(0.0, -72.0)
	move_drag.relative = Vector2(0.0, -72.0)
	game.call("_input", move_drag)
	if not _check(int(game.get("touch_move_id")) == 5 and (game.get("touch_move_vector") as Vector2).y > 0.5, "left-side Android touch did not drive the movement control"):
		return
	var move_release := InputEventScreenTouch.new()
	move_release.index = 5
	move_release.position = move_drag.position
	move_release.pressed = false
	game.call("_input", move_release)
	if not _check(int(game.get("touch_move_id")) == -1 and (game.get("touch_move_vector") as Vector2).is_zero_approx(), "movement touch did not reset cleanly after release"):
		return

	if not _check(hands.get_child_count() >= 16, "first-person hands are missing sleeves, cuffs, palms, fingers, or thumbs"):
		return
	if not _check(hands.get_node_or_null("Thumb_L") != null and hands.get_node_or_null("Thumb_R") != null, "both visible thumbs must be present for a readable hand silhouette"):
		return
	var left_sleeve := hands.get_node_or_null("Sleeve_L") as MeshInstance3D
	var left_sleeve_mesh := left_sleeve.mesh as CapsuleMesh if left_sleeve != null else null
	if not _check(left_sleeve_mesh != null and left_sleeve_mesh.radius <= 0.065, "first-person sleeves are too bulky for the physical letter pose"):
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
	if not _check(physical_message != null and physical_message.text.contains("DO NOT LET THE CLOCK") and physical_message.text.contains("FINISH."), "the fresh clock warning is missing from the physical paper"):
		return
	if not _check(physical_message.position.z > 0.0, "letter ink is on the hidden back face instead of the camera-facing paper surface"):
		return
	if not _check(str((game.get("interact_button") as Button).text).contains("CLOSE LETTER"), "the physical letter has no clear close action"):
		return
	await create_timer(0.80).timeout
	var thumb_left := hands.get_node_or_null("Thumb_L") as MeshInstance3D
	var thumb_right := hands.get_node_or_null("Thumb_R") as MeshInstance3D
	if not _check(thumb_left != null and thumb_right != null and absf(thumb_left.position.x) < 0.31 and absf(thumb_right.position.x) < 0.31, "both thumbs did not move inward to grip the letter edges"):
		return
	game.call("_interact")
	if not _check(not bool(game.get("letter_inspecting")) and not hands.visible and game.get("held_letter_prop") == null, "closing the letter did not restore normal exploration"):
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
	if not _check(photo_mesh != null and photo_mesh.size.y > photo_mesh.size.x and photo_mesh.size.z < 0.02, "the photograph backing is not a portrait-format upright keepsake"):
		return
	if not _check(str(photo.get_meta("station_photo_source", "")) == "art/reference/file_00000000a27081f4a16c023a7b226ef1.png", "the station photograph is not tied to the supplied source reference"):
		return
	var source_photo := photo.get_node_or_null("StationPhotoFromUserReference") as MeshInstance3D
	var source_photo_material := source_photo.material_override as StandardMaterial3D if source_photo else null
	if not _check(source_photo_material != null and source_photo_material.albedo_texture != null, "the physical photo card did not load the station photograph from the supplied reference"):
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
	if not _check(not status_hud.visible and not interact_hud.visible, "gameplay HUD was not hidden behind the pause menu"):
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
	if not _check(status_hud.visible and interact_hud.visible, "resuming did not restore the gameplay HUD"):
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
