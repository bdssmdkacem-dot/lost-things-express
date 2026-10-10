extends SceneTree

const OUTPUT_DIR := "res://build/visual_review"

func _initialize() -> void:
	call_deferred("_capture_first_stage")

func _capture_first_stage() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("VISUAL_CAPTURE_FAILED: main scene could not be loaded")
		quit(1)
		return

	var game := packed.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	if not _save_viewport_image("01_train_intro.png"):
		return

	game.call("_enter_stage_one")
	game.call("_close_story_card")
	await create_timer(0.35).timeout
	if not _save_viewport_image("02_carriage_opening.png"):
		return

	var player := game.get("player") as CharacterBody3D
	var key := game.get_node_or_null("BrassKey") as Node3D
	var letter := game.get_node_or_null("TornLetter") as Node3D
	var chest := game.get_node_or_null("MemoryChest") as Node3D
	if player == null or key == null or letter == null or chest == null:
		push_error("VISUAL_CAPTURE_FAILED: one or more story props are missing")
		quit(1)
		return

	player.global_position = key.global_position + Vector3(0.0, 0.0, 0.35)
	game.call("_interact")
	game.call("_close_story_card")
	await create_timer(0.85).timeout

	player.global_position = letter.global_position + Vector3(0.0, 0.0, 0.20)
	game.call("_interact")
	await create_timer(0.85).timeout
	if not _save_viewport_image("03_physical_letter.png"):
		return
	game.call("_interact")

	player.global_position = chest.global_position + Vector3(0.0, 0.0, 0.35)
	game.call("_interact")
	await create_timer(1.0).timeout
	game.call("_close_story_card")
	await create_timer(0.25).timeout
	if not _save_viewport_image("04_chest_reveal.png"):
		return

	game.call("_toggle_pause_menu")
	await create_timer(0.2).timeout
	if not _save_viewport_image("05_pause_settings.png"):
		return

	print("VISUAL_CAPTURE_COMPLETE: intro, carriage, physical letter, chest reveal, pause/settings")
	game.queue_free()
	await process_frame
	quit(0)

func _save_viewport_image(filename: String) -> bool:
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_CAPTURE_FAILED: viewport image is empty for " + filename)
		quit(1)
		return false
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(filename))
	var error := image.save_png(output_path)
	if error != OK:
		push_error("VISUAL_CAPTURE_FAILED: could not save " + filename + " (error %d)" % error)
		quit(1)
		return false
	print("VISUAL_CAPTURE_SAVED: " + output_path + " size=%dx%d" % [image.get_width(), image.get_height()])
	return true
