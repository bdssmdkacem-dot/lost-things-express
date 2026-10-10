extends SceneTree

func _initialize() -> void:
	call_deferred("_run_first_slice")

func _run_first_slice() -> void:
	# Keep this test deterministic even if it is rerun in a reused editor profile.
	var save_path := ProjectSettings.globalize_path("user://first_stage_progress.cfg")
	if FileAccess.file_exists("user://first_stage_progress.cfg"):
		DirAccess.remove_absolute(save_path)
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
	if not _check(player != null, "player was not created"):
		return
	if not _check(key != null and letter != null and chest != null, "one or more story props are missing"):
		return

	# A chest must not open until both clues have been found and understood.
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(not bool(game.get("chest_open")), "chest opened without the brass key"):
		return

	# Find the key on the floor.
	player.global_position = key.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(bool(game.get("has_key")), "interacting with the brass key did not collect it"):
		return
	await process_frame

	# The key alone is insufficient: the letter must be read first.
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(not bool(game.get("chest_open")), "chest opened before the letter was read"):
		return

	player.global_position = letter.global_position + Vector3(0.0, 0.0, 0.20)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(bool(game.get("letter_read")), "interacting with the torn letter did not mark it read"):
		return

	# With both prerequisites met, the chest should open and its lid should move.
	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	# _interact must refresh proximity itself, as it does on a real button tap.
	game.call("_interact")
	if not _check(bool(game.get("chest_open")), "chest did not open after key and letter"):
		return
	# The chest lid now opens with a short cinematic tween.
	await create_timer(0.85).timeout
	var lid := chest.get_node_or_null("Lid") as Node3D
	if not _check(lid != null and is_equal_approx(lid.rotation.x, deg_to_rad(-72.0)), "chest lid did not reach the open position"):
		return
	if not _check(int(game.call("_inventory_count")) == 3, "inventory does not show the three completed story items"):
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
	if not _check(bool(resumed_game.get("has_key")), "saved key progress was not restored"):
		return
	if not _check(bool(resumed_game.get("letter_read")), "saved letter progress was not restored"):
		return
	if not _check(bool(resumed_game.get("chest_open")), "saved chest progress was not restored"):
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
