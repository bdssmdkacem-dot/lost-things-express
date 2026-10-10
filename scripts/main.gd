extends Node3D
## First playable foundation. Geometry is temporary; the art direction is locked in docs/ART_DIRECTION.md.

const WALK_SPEED := 3.0
const LOOK_SENSITIVITY := 0.004
const INTERACT_DISTANCE := 3.0

var player: CharacterBody3D
var camera: Camera3D
var first_person_hands: Node3D
var hand_action_tween: Tween
var status_label: Label
var objective_label: Label
var prompt_label: Label
var interact_button: Button
var inventory_button: Button
var inventory_label: Label
var inventory_open := false
var yaw := 0.0
var pitch := -0.04
var touch_move_id := -1
var touch_look_id := -1
var touch_move_origin := Vector2.ZERO
var touch_move_vector := Vector2.ZERO
var mouse_look := false
var has_key := false
var letter_read := false
var chest_open := false
var nearby_object: Node3D

var story_overlay: ColorRect
var story_title: Label
var story_body: Label
var story_continue: Button
var story_card_open := false

func _ready() -> void:
	_setup_input_map()
	_build_world()
	_build_player()
	_build_ui()
	_load_progress()
	if chest_open:
		_set_status("Welcome back. The photograph points to Sunset Station.")
	else:
		_set_status("The train has arrived at a station that appears on no map.")
		_show_story_card("THE STATION THAT FORGOT ITS NAME", "The train never stopped at ordinary stations. Tonight, it had forgotten even the name of its destination.\n\nExplore the carriage. Something important has been left behind.", "BEGIN EXPLORING")

func _setup_input_map() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)

func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	InputMap.action_add_event(action_name, key_event)

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.025, 0.07, 0.12)
	sky_material.sky_horizon_color = Color(0.25, 0.22, 0.20)
	sky_material.ground_bottom_color = Color(0.025, 0.035, 0.04)
	sky_material.ground_horizon_color = Color(0.12, 0.10, 0.09)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.58, 0.52, 0.47)
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -25, 0)
	sun.light_color = Color(1.0, 0.72, 0.43)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)

	# Runtime practical lights guarantee readable velvet and wood on mobile renderers,
	# even if a glTF importer drops Blender's authored area-light data.
	for light_spec in [
		[Vector3(-1.45, 2.65, -3.6), Color(1.0, 0.56, 0.30), 2.2, 5.6],
		[Vector3(1.45, 2.65, 0.0), Color(1.0, 0.68, 0.43), 2.6, 6.0],
		[Vector3(-1.45, 2.65, 3.5), Color(1.0, 0.56, 0.30), 2.2, 5.6],
		[Vector3(0.0, 2.5, 0.0), Color(0.48, 0.70, 1.0), 0.7, 4.8],
	]:
		var fill := OmniLight3D.new()
		fill.name = "CarriageLight_%02d" % get_child_count()
		fill.position = light_spec[0]
		fill.light_color = light_spec[1]
		fill.light_energy = light_spec[2]
		fill.omni_range = light_spec[3]
		fill.shadow_enabled = false
		add_child(fill)

	# Prefer the reviewed Blender carriage asset; keep the procedural shell only as a safe fallback.
	var carriage_path := "res://assets/models/train_carriage.glb"
	if ResourceLoader.exists(carriage_path):
		var carriage_resource := load(carriage_path)
		if carriage_resource is PackedScene:
			var carriage_instance := (carriage_resource as PackedScene).instantiate()
			carriage_instance.name = "ProductionCarriage"
			add_child(carriage_instance)
			# The imported mesh is visual-only; separate invisible collision keeps movement reliable.
			_collision_box("Carriage floor collision", Vector3(0, -0.12, 0), Vector3(5.6, 0.24, 11.8))
			_collision_box("Carriage left boundary", Vector3(-2.78, 1.6, 0), Vector3(0.12, 3.2, 11.8))
			_collision_box("Carriage right boundary", Vector3(2.78, 1.6, 0), Vector3(0.12, 3.2, 11.8))
			_collision_box("Carriage rear left pier", Vector3(-2.32, 1.65, -5.85), Vector3(1.16, 3.3, 0.12))
			_collision_box("Carriage rear right pier", Vector3(2.32, 1.65, -5.85), Vector3(1.16, 3.3, 0.12))
			_collision_box("Carriage rear doorway lintel", Vector3(0, 2.98, -5.85), Vector3(3.48, 0.64, 0.12))
			for seat_z in [-3.6, -0.5, 2.8]:
				for side in [-1.0, 1.0]:
					_collision_box("Seat collision", Vector3(side * 1.78, 0.76, seat_z), Vector3(1.35, 1.48, 1.24))
			_collision_box("Carriage front boundary", Vector3(0, 1.6, 5.85), Vector3(5.6, 3.2, 0.12))
		else:
			push_warning("Carriage GLB exists but did not import as a PackedScene; using fallback geometry.")
			_build_procedural_carriage()
	else:
		push_warning("Carriage GLB missing; using fallback geometry.")
		_build_procedural_carriage()

	_create_interactable("Brass Key", Vector3(-0.45, 0.12, -1.1), Color(0.95, 0.62, 0.16), "key")
	# Place the letter visibly on the aisle-side edge of an ivory-marble table.
	_create_interactable("Torn Letter", Vector3(1.95, 0.83, 1.15), Color(0.86, 0.77, 0.59), "letter")
	_create_interactable("Memory Chest", Vector3(0.0, 0.45, -4.45), Color(0.33, 0.12, 0.055), "chest", Vector3(0.95, 0.75, 0.65))

func _build_procedural_carriage() -> void:
	# Carriage shell. These simple meshes validate scale and mechanics only.
	_box("Floor", Vector3(0, -0.12, 0), Vector3(5.8, 0.24, 12.0), Color(0.16, 0.075, 0.045))
	_box("Ceiling", Vector3(0, 3.5, 0), Vector3(5.8, 0.18, 12.0), Color(0.09, 0.045, 0.032))
	_box("Left wall", Vector3(-2.85, 1.65, 0), Vector3(0.18, 3.3, 12.0), Color(0.12, 0.055, 0.035))
	_box("Right wall", Vector3(2.85, 1.65, 0), Vector3(0.18, 3.3, 12.0), Color(0.12, 0.055, 0.035))
	_box("Rear wall left pier", Vector3(-2.32, 1.65, -5.95), Vector3(1.16, 3.3, 0.18), Color(0.10, 0.045, 0.03))
	_box("Rear wall right pier", Vector3(2.32, 1.65, -5.95), Vector3(1.16, 3.3, 0.18), Color(0.10, 0.045, 0.03))
	_box("Rear wall doorway lintel", Vector3(0, 2.98, -5.95), Vector3(3.48, 0.64, 0.18), Color(0.10, 0.045, 0.03))
	_box("Doorway left walnut jamb", Vector3(-1.74, 1.34, -5.80), Vector3(0.13, 2.68, 0.16), Color(0.30, 0.105, 0.045), false)
	_box("Doorway right walnut jamb", Vector3(1.74, 1.34, -5.80), Vector3(0.13, 2.68, 0.16), Color(0.30, 0.105, 0.045), false)
	_box("Next compartment floor", Vector3(0, -0.10, -9.15), Vector3(5.56, 0.20, 6.35), Color(0.075, 0.026, 0.016), false)
	_box("Next compartment ceiling", Vector3(0, 3.38, -9.15), Vector3(5.56, 0.18, 6.35), Color(0.075, 0.026, 0.016), false)
	_box("Next compartment left wall", Vector3(-2.78, 1.62, -9.15), Vector3(0.16, 3.24, 6.35), Color(0.12, 0.055, 0.035), false)
	_box("Next compartment right wall", Vector3(2.78, 1.62, -9.15), Vector3(0.16, 3.24, 6.35), Color(0.12, 0.055, 0.035), false)
	_box("Next compartment distant wall", Vector3(0, 1.62, -12.32), Vector3(5.56, 3.24, 0.18), Color(0.075, 0.026, 0.016), false)
	_box("Next compartment clock frame", Vector3(0, 2.32, -12.19), Vector3(1.12, 0.92, 0.10), Color(0.30, 0.105, 0.045), false)
	_box("Next compartment clock face", Vector3(0, 2.32, -12.12), Vector3(0.45, 0.45, 0.04), Color(0.72, 0.59, 0.37), false)
	_box("Front wall", Vector3(0, 1.65, 5.95), Vector3(5.8, 3.3, 0.18), Color(0.10, 0.045, 0.03))

	for x in [-2.72, 2.72]:
		for y in [0.2, 3.05]:
			_box("Brass trim", Vector3(x, y, 0), Vector3(0.045, 0.045, 11.7), Color(0.70, 0.37, 0.10))

	for side in [-1.0, 1.0]:
		for z in [-4.0, -1.8, 0.4, 2.6, 4.7]:
			_box("Window glass", Vector3(side * 2.745, 2.05, z), Vector3(0.025, 1.05, 1.35), Color(0.055, 0.20, 0.28), false)
			for y in [1.48, 2.62]:
				_box("Window brass frame", Vector3(side * 2.70, y, z), Vector3(0.12, 0.07, 1.48), Color(0.63, 0.32, 0.09), false)
			for zz in [z - 0.72, z + 0.72]:
				_box("Window brass frame", Vector3(side * 2.70, 2.05, zz), Vector3(0.12, 1.18, 0.07), Color(0.63, 0.32, 0.09), false)

	for z in [-3.6, -0.5, 2.8]:
		_box("Velvet seat", Vector3(-1.78, 0.58, z), Vector3(1.25, 0.65, 1.2), Color(0.30, 0.075, 0.065), false)
		_box("Seat back", Vector3(-1.78, 1.12, z - 0.48), Vector3(1.25, 0.85, 0.20), Color(0.34, 0.09, 0.07), false)
		_box("Velvet seat", Vector3(1.78, 0.58, z), Vector3(1.25, 0.65, 1.2), Color(0.30, 0.075, 0.065), false)
		_box("Seat back", Vector3(1.78, 1.12, z - 0.48), Vector3(1.25, 0.85, 0.20), Color(0.34, 0.09, 0.07), false)

	_add_lantern(Vector3(-2.2, 2.85, -3.8))
	_add_lantern(Vector3(2.2, 2.85, 0.0))
	_add_lantern(Vector3(-2.2, 2.85, 3.7))


func _collision_box(label: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.1, 4.8)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.55
	collision.shape = capsule
	collision.position.y = 0.78
	player.add_child(collision)

	camera = Camera3D.new()
	camera.position = Vector3(0, 1.45, 0)
	camera.rotation.x = pitch
	camera.current = true
	player.add_child(camera)
	_build_first_person_hands()


# First-person arms are a camera-attached view model. This is intentionally
# isolated from player movement, camera look, collision, and touch input.
func _build_first_person_hands() -> void:
	first_person_hands = Node3D.new()
	first_person_hands.name = "FirstPersonHands"
	first_person_hands.position = Vector3.ZERO
	camera.add_child(first_person_hands)

	var sleeve_material := StandardMaterial3D.new()
	sleeve_material.albedo_color = Color(0.035, 0.13, 0.15)
	sleeve_material.roughness = 0.78
	var cuff_material := StandardMaterial3D.new()
	cuff_material.albedo_color = Color(0.67, 0.43, 0.17)
	cuff_material.metallic = 0.35
	cuff_material.roughness = 0.42
	var skin_material := StandardMaterial3D.new()
	skin_material.albedo_color = Color(0.72, 0.48, 0.32)
	skin_material.roughness = 0.86

	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.name = "Sleeve_%s" % ("L" if side < 0.0 else "R")
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.105
		arm_mesh.height = 0.48
		arm.mesh = arm_mesh
		arm.material_override = sleeve_material
		arm.position = Vector3(side * 0.30, -0.43, -0.62)
		arm.rotation_degrees = Vector3(0.0, 0.0, side * -24.0)
		first_person_hands.add_child(arm)

		var cuff := MeshInstance3D.new()
		cuff.name = "BrassCuff_%s" % ("L" if side < 0.0 else "R")
		var cuff_mesh := CylinderMesh.new()
		cuff_mesh.top_radius = 0.105
		cuff_mesh.bottom_radius = 0.105
		cuff_mesh.height = 0.055
		cuff.mesh = cuff_mesh
		cuff.material_override = cuff_material
		cuff.position = Vector3(side * 0.30, -0.285, -0.67)
		cuff.rotation_degrees.z = side * -24.0
		first_person_hands.add_child(cuff)

		var palm := MeshInstance3D.new()
		palm.name = "Hand_%s" % ("L" if side < 0.0 else "R")
		var palm_mesh := SphereMesh.new()
		palm_mesh.radius = 0.105
		palm_mesh.height = 0.16
		palm.mesh = palm_mesh
		palm.material_override = skin_material
		palm.position = Vector3(side * 0.30, -0.20, -0.71)
		first_person_hands.add_child(palm)

		# Four short fingers make the silhouette read as a hand at phone size.
		for finger_index in range(4):
			var finger := MeshInstance3D.new()
			finger.name = "Finger_%s_%d" % ["L" if side < 0.0 else "R", finger_index]
			var finger_mesh := CapsuleMesh.new()
			finger_mesh.radius = 0.022
			finger_mesh.height = 0.095
			finger.mesh = finger_mesh
			finger.material_override = skin_material
			finger.position = Vector3(side * 0.30 + (finger_index - 1.5) * 0.042, -0.245, -0.79)
			finger.rotation_degrees.x = -18.0
			first_person_hands.add_child(finger)

		# A separate angled thumb gives each hand a readable, grasp-ready silhouette.
		var thumb := MeshInstance3D.new()
		thumb.name = "Thumb_%s" % ("L" if side < 0.0 else "R")
		var thumb_mesh := CapsuleMesh.new()
		thumb_mesh.radius = 0.024
		thumb_mesh.height = 0.09
		thumb.mesh = thumb_mesh
		thumb.material_override = skin_material
		thumb.position = Vector3(side * 0.30 + side * 0.09, -0.205, -0.755)
		thumb.rotation_degrees = Vector3(-12.0, 0.0, side * 34.0)
		first_person_hands.add_child(thumb)

func _play_hand_action(action: String) -> void:
	if not is_instance_valid(first_person_hands):
		return
	if hand_action_tween and hand_action_tween.is_running():
		hand_action_tween.kill()
	first_person_hands.position = Vector3.ZERO
	first_person_hands.rotation = Vector3.ZERO
	hand_action_tween = create_tween()
	hand_action_tween.set_parallel(true)
	match action:
		"take":
			hand_action_tween.tween_property(first_person_hands, "position", Vector3(0.0, 0.13, -0.34), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			hand_action_tween.tween_property(first_person_hands, "rotation:x", deg_to_rad(-10.0), 0.22)
		"read":
			hand_action_tween.tween_property(first_person_hands, "position", Vector3(0.0, 0.20, -0.26), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			hand_action_tween.tween_property(first_person_hands, "rotation:x", deg_to_rad(-7.0), 0.28)
		"open":
			hand_action_tween.tween_property(first_person_hands, "position", Vector3(0.0, 0.16, -0.40), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			hand_action_tween.tween_property(first_person_hands, "rotation:x", deg_to_rad(-14.0), 0.32)
	hand_action_tween.set_parallel(false)
	hand_action_tween.tween_interval(0.12)
	hand_action_tween.tween_property(first_person_hands, "position", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	hand_action_tween.parallel().tween_property(first_person_hands, "rotation", Vector3.ZERO, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	status_label = Label.new()
	status_label.anchor_left = 0.04
	status_label.anchor_top = 0.04
	status_label.anchor_right = 0.78
	status_label.anchor_bottom = 0.18
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	status_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.72))
	status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	status_label.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.027, 0.065, 0.082, 0.96), Color(0.72, 0.47, 0.19, 0.98), 12, 12))
	root.add_child(status_label)

	objective_label = Label.new()
	objective_label.anchor_left = 0.04
	objective_label.anchor_top = 0.20
	objective_label.anchor_right = 0.78
	objective_label.anchor_bottom = 0.29
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 15)
	objective_label.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	objective_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	objective_label.add_theme_constant_override("shadow_offset_x", 1)
	objective_label.add_theme_constant_override("shadow_offset_y", 1)
	objective_label.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.025, 0.075, 0.078, 0.96), Color(0.30, 0.55, 0.43, 0.98), 10, 10))
	root.add_child(objective_label)

	prompt_label = Label.new()
	prompt_label.anchor_left = 0.18
	prompt_label.anchor_top = 0.76
	prompt_label.anchor_right = 0.76
	prompt_label.anchor_bottom = 0.88
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.73))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	prompt_label.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.027, 0.065, 0.082, 0.94), Color(0.72, 0.47, 0.19, 0.96), 12, 8))
	root.add_child(prompt_label)

	interact_button = Button.new()
	interact_button.text = "INTERACT"
	interact_button.anchor_left = 0.80
	interact_button.anchor_top = 0.78
	interact_button.anchor_right = 0.96
	interact_button.anchor_bottom = 0.92
	interact_button.text = "✦  INTERACT"
	interact_button.add_theme_font_size_override("font_size", 18)
	interact_button.add_theme_color_override("font_color", Color(1.0, 0.91, 0.70))
	interact_button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.86))
	interact_button.add_theme_color_override("font_pressed_color", Color(0.15, 0.08, 0.025))
	interact_button.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.10, 0.055, 0.022, 0.98), Color(0.72, 0.47, 0.19, 1.0), 16, 8))
	interact_button.add_theme_stylebox_override("hover", _ui_panel_style(Color(0.24, 0.13, 0.035, 0.98), Color(1.0, 0.78, 0.35, 1.0), 16, 8))
	interact_button.add_theme_stylebox_override("pressed", _ui_panel_style(Color(0.85, 0.56, 0.18, 1.0), Color(1.0, 0.85, 0.48, 1.0), 16, 8))
	interact_button.add_theme_stylebox_override("disabled", _ui_panel_style(Color(0.045, 0.035, 0.025, 0.80), Color(0.28, 0.23, 0.16, 0.8), 16, 8))
	interact_button.pressed.connect(_interact)
	root.add_child(interact_button)

	inventory_button = Button.new()
	inventory_button.text = "BAG · 0"
	inventory_button.anchor_left = 0.82
	inventory_button.anchor_top = 0.04
	inventory_button.anchor_right = 0.96
	inventory_button.anchor_bottom = 0.12
	inventory_button.add_theme_font_size_override("font_size", 16)
	inventory_button.add_theme_color_override("font_color", Color(1.0, 0.89, 0.67))
	inventory_button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.86))
	inventory_button.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.027, 0.065, 0.082, 0.96), Color(0.72, 0.47, 0.19, 0.98), 12, 7))
	inventory_button.add_theme_stylebox_override("hover", _ui_panel_style(Color(0.12, 0.075, 0.025, 0.97), Color(0.93, 0.69, 0.31, 1.0), 12, 7))
	inventory_button.add_theme_stylebox_override("pressed", _ui_panel_style(Color(0.40, 0.24, 0.07, 1.0), Color(1.0, 0.80, 0.38, 1.0), 12, 7))
	inventory_button.pressed.connect(_toggle_inventory)
	root.add_child(inventory_button)

	inventory_label = Label.new()
	inventory_label.anchor_left = 0.66
	inventory_label.anchor_top = 0.14
	inventory_label.anchor_right = 0.96
	inventory_label.anchor_bottom = 0.34
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	inventory_label.add_theme_font_size_override("font_size", 17)
	inventory_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.66))
	inventory_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.015, 0.01, 0.9))
	inventory_label.add_theme_constant_override("shadow_offset_x", 2)
	inventory_label.add_theme_constant_override("shadow_offset_y", 2)
	inventory_label.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.025, 0.055, 0.068, 0.97), Color(0.55, 0.38, 0.20, 0.96), 10, 10))
	inventory_label.visible = false
	root.add_child(inventory_label)

	var hint := Label.new()
	hint.text = "LEFT: MOVE  •  RIGHT: LOOK"
	hint.anchor_left = 0.03
	hint.anchor_top = 0.94
	hint.anchor_right = 0.68
	hint.anchor_bottom = 0.99
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.95, 0.91, 0.81))
	hint.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.025, 0.055, 0.068, 0.94), Color(0.42, 0.34, 0.23, 0.88), 8, 5))
	root.add_child(hint)
	_build_story_overlay(root)

func _ui_panel_style(fill: Color, edge: Color, corner_radius: int, inset: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = inset
	style.content_margin_right = inset
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _build_story_overlay(root: Control) -> void:
	story_overlay = ColorRect.new()
	story_overlay.name = "StoryOverlay"
	story_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_overlay.color = Color(0.008, 0.018, 0.028, 0.82)
	story_overlay.visible = false
	story_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(story_overlay)

	var card := PanelContainer.new()
	card.name = "StoryCard"
	card.anchor_left = 0.12
	card.anchor_top = 0.23
	card.anchor_right = 0.88
	card.anchor_bottom = 0.75
	card.add_theme_stylebox_override("panel", _ui_panel_style(Color(0.027, 0.065, 0.082, 0.99), Color(0.72, 0.47, 0.19, 1.0), 18, 18))
	story_overlay.add_child(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)

	story_title = Label.new()
	story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_title.add_theme_font_size_override("font_size", 23)
	story_title.add_theme_color_override("font_color", Color(1.0, 0.76, 0.39))
	story_title.add_theme_constant_override("line_spacing", 5)
	content.add_child(story_title)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color(0.67, 0.43, 0.20, 0.9))
	content.add_child(divider)

	story_body = Label.new()
	story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_body.add_theme_font_size_override("font_size", 20)
	story_body.add_theme_color_override("font_color", Color(0.96, 0.91, 0.81))
	story_body.add_theme_constant_override("line_spacing", 6)
	content.add_child(story_body)

	story_continue = Button.new()
	story_continue.custom_minimum_size = Vector2(0, 54)
	story_continue.add_theme_font_size_override("font_size", 18)
	story_continue.add_theme_color_override("font_color", Color(1.0, 0.90, 0.66))
	story_continue.add_theme_stylebox_override("normal", _ui_panel_style(Color(0.12, 0.22, 0.20, 1.0), Color(0.72, 0.47, 0.19, 1.0), 12, 10))
	story_continue.add_theme_stylebox_override("pressed", _ui_panel_style(Color(0.78, 0.48, 0.12, 1.0), Color(1.0, 0.84, 0.42, 1.0), 12, 10))
	story_continue.pressed.connect(_close_story_card)
	content.add_child(story_continue)

func _show_story_card(title_text: String, body_text: String, button_text: String) -> void:
	if not is_instance_valid(story_overlay):
		return
	story_title.text = title_text
	story_body.text = body_text
	story_continue.text = button_text
	story_overlay.visible = true
	story_card_open = true
	var fade := create_tween()
	story_overlay.modulate.a = 0.0
	fade.tween_property(story_overlay, "modulate:a", 1.0, 0.22)

func _close_story_card() -> void:
	if not is_instance_valid(story_overlay):
		return
	story_overlay.visible = false
	story_card_open = false

func _process(_delta: float) -> void:
	_update_nearby()
	objective_label.text = _objective_text()
	interact_button.disabled = nearby_object == null
	prompt_label.text = "Inspect: " + str(nearby_object.get_meta("display_name", "object")) if nearby_object else ""
	inventory_button.text = "BAG · %d" % _inventory_count()
	inventory_label.visible = inventory_open
	inventory_label.text = _inventory_text()

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)
	input_vector += touch_move_vector
	input_vector = input_vector.limit_length(1.0)
	var direction := (player.transform.basis * Vector3(input_vector.x, 0, -input_vector.y)).normalized()
	player.velocity.x = direction.x * WALK_SPEED
	player.velocity.z = direction.z * WALK_SPEED
	player.velocity.y = 0.0
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -2.25, 2.25)
	player.position.z = clampf(player.position.z, -5.1, 5.1)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.35:
			mouse_look = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			mouse_look = false

	if event is InputEventMouseMotion and mouse_look:
		_apply_look(event.relative)

	if event is InputEventScreenTouch:
		var width := get_viewport().get_visible_rect().size.x
		if event.pressed and ((is_instance_valid(interact_button) and interact_button.get_global_rect().has_point(event.position)) or (is_instance_valid(inventory_button) and inventory_button.get_global_rect().has_point(event.position))):
			return
		if event.pressed:
			if event.position.x < width * 0.45 and touch_move_id == -1:
				touch_move_id = event.index
				touch_move_origin = event.position
				touch_move_vector = Vector2.ZERO
			elif touch_look_id == -1:
				touch_look_id = event.index
		else:
			if event.index == touch_move_id:
				touch_move_id = -1
				touch_move_vector = Vector2.ZERO
			if event.index == touch_look_id:
				touch_look_id = -1

	if event is InputEventScreenDrag:
		if event.index == touch_move_id:
			var drag: Vector2 = (event.position - touch_move_origin) / 90.0
			touch_move_vector = Vector2(clampf(drag.x, -1.0, 1.0), clampf(-drag.y, -1.0, 1.0))
		elif event.index == touch_look_id:
			_apply_look(event.relative)

func _apply_look(relative: Vector2) -> void:
	yaw -= relative.x * LOOK_SENSITIVITY
	pitch = clampf(pitch - relative.y * LOOK_SENSITIVITY, -0.75, 0.65)
	player.rotation.y = yaw
	camera.rotation.x = pitch

func _update_nearby() -> void:
	nearby_object = null
	var nearest := INTERACT_DISTANCE
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		# Floor-plane distance is more forgiving on mobile; vertical offset has only a small penalty.
		var horizontal := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(node.global_position.x, node.global_position.z))
		var distance := horizontal + absf(player.global_position.y - node.global_position.y) * 0.25
		if distance < nearest:
			nearest = distance
			nearby_object = node

func _interact() -> void:
	# Refresh at tap time so the button never acts on a stale target between frames.
	_update_nearby()
	if nearby_object == null:
		_set_status("Move a little closer to the object, then tap INTERACT.")
		return
	var kind: String = nearby_object.get_meta("kind", "")
	match kind:
		"key":
			if not has_key:
				has_key = true
				_play_hand_action("take")
				nearby_object.queue_free()
				_set_status("The brass key is warm, as if someone held it only moments ago.")
				_show_story_card("THE BRASS KEY", "The little key is still warm. Whoever carried it must have left this carriage only moments ago.\n\nNew clue added to your bag.", "CONTINUE")
			else:
				_set_status("You already have the key.")
		"letter":
			_play_hand_action("read")
			letter_read = true
			nearby_object.set_meta("display_name", "Letter read")
			_set_status("The letter contains a message about returning what was forgotten.")
			_show_story_card("A MESSAGE LEFT BEHIND", "“When the clock strikes three times, return what the traveler forgot.”\n\nThe letter is written on old parchment. The memory chest may hold the answer.", "CLOSE LETTER")
		"chest":
			if chest_open:
				_show_story_card("SUNSET STATION", "The photograph shows a station glowing beneath a copper sunset. It is more than a memory — it is a clue to a place missing from every map.", "CLOSE PHOTOGRAPH")
			elif not has_key:
				_set_status("The chest is locked. Find the brass key.")
				_show_story_card("A LOCKED MEMORY", "A brass lock holds the chest shut. Search the carriage for a key.", "KEEP SEARCHING")
			elif not letter_read:
				_set_status("You need to understand the letter before opening the chest.")
				_show_story_card("A LOCKED MEMORY", "The chest seems to wait for more than a key. Read the torn letter on the side table first.", "READ THE LETTER")
			else:
				chest_open = true
				_play_hand_action("open")
				nearby_object.set_meta("display_name", "Open chest")
				var lid := nearby_object.get_node_or_null("Lid") as Node3D
				if lid:
					var lid_tween := create_tween()
					lid_tween.tween_property(lid, "rotation:x", deg_to_rad(-72.0), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_set_status("The chest opens. A photograph reveals the lost destination: Sunset Station.")
				_show_story_card("A MEMORY RETURNS", "The photograph was not just a keepsake. It points to Sunset Station — a place that does not appear on any map.\n\nSTAGE ONE COMPLETE", "CONTINUE")
		_:
			_set_status("Nothing happens here yet.")
	_save_progress()

func _save_progress() -> void:
	# Persist the first-stage puzzle so closing the app does not erase progress.
	var config := ConfigFile.new()
	config.set_value("progress", "has_key", has_key)
	config.set_value("progress", "letter_read", letter_read)
	config.set_value("progress", "chest_open", chest_open)
	var error := config.save("user://first_stage_progress.cfg")
	if error != OK:
		push_warning("Could not save first-stage progress (error %d)." % error)

func _load_progress() -> void:
	var path := "user://first_stage_progress.cfg"
	if not FileAccess.file_exists(path):
		return
	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("Saved first-stage progress could not be read; starting a new puzzle.")
		return
	has_key = bool(config.get_value("progress", "has_key", false))
	letter_read = bool(config.get_value("progress", "letter_read", false))
	chest_open = bool(config.get_value("progress", "chest_open", false))
	if has_key:
		var key := get_node_or_null("BrassKey")
		if key:
			key.queue_free()
	var letter := get_node_or_null("TornLetter")
	if letter and letter_read:
		letter.set_meta("display_name", "Letter read")
	var chest := get_node_or_null("MemoryChest")
	if chest and chest_open:
		chest.set_meta("display_name", "Open chest")
		var lid := chest.get_node_or_null("Lid") as Node3D
		if lid:
			lid.rotation.x = deg_to_rad(-72.0)

func _toggle_inventory() -> void:
	inventory_open = not inventory_open

func _inventory_count() -> int:
	var count := 0
	if has_key:
		count += 1
	if letter_read:
		count += 1
	if chest_open:
		count += 1
	return count

func _inventory_text() -> String:
	var lines := ["INVENTORY"]
	lines.append("• Brass key" if has_key else "• Brass key — not found")
	lines.append("• Torn letter (read)" if letter_read else "• Torn letter — unread")
	lines.append("• Sunset photograph" if chest_open else "• Memory chest reward — undiscovered")
	return "\n".join(lines)

func _objective_text() -> String:
	if chest_open:
		return "Objective complete: Get ready to leave Sunset Station."
	if not has_key:
		return "Objective: Find the brass key near the seats."
	if not letter_read:
		return "Objective: Read the letter on the side table."
	return "Objective: Unlock the memory chest with the key."

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message

func _box(label: String, pos: Vector3, size: Vector3, color: Color, solid := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	add_child(body)

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.35 if label.to_lower().contains("brass") else 0.05
	material.roughness = 0.42
	visual.material_override = material
	body.add_child(visual)

	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	else:
		body.collision_layer = 0
		body.collision_mask = 0
	return body

func _create_interactable(label: String, pos: Vector3, color: Color, kind: String, size := Vector3(0.32, 0.16, 0.24)) -> Node3D:
	var item := Node3D.new()
	item.name = label.replace(" ", "")
	item.position = pos
	item.set_meta("kind", kind)
	item.set_meta("display_name", label)
	item.add_to_group("interactables")
	add_child(item)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.78 if kind == "key" else (0.12 if kind == "letter" else 0.32)
	material.roughness = 0.24 if kind == "key" else (0.82 if kind == "letter" else 0.34)

	if kind == "key":
		# Build an unmistakable three-dimensional brass key, not a floating ring icon.
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.055
		ring_mesh.outer_radius = 0.105
		var ring := MeshInstance3D.new()
		ring.name = "KeyRing"
		ring.mesh = ring_mesh
		ring.material_override = material
		ring.position = Vector3(-0.14, 0.02, 0.0)
		ring.rotation_degrees = Vector3(90.0, 0.0, 22.0)
		item.add_child(ring)

		var shaft_mesh := BoxMesh.new()
		shaft_mesh.size = Vector3(0.27, 0.035, 0.035)
		var shaft := MeshInstance3D.new()
		shaft.name = "KeyShaft"
		shaft.mesh = shaft_mesh
		shaft.material_override = material
		shaft.position = Vector3(0.09, 0.02, 0.0)
		item.add_child(shaft)

		for tooth_spec in [Vector2(0.16, -0.025), Vector2(0.245, -0.025)]:
			var tooth_mesh := BoxMesh.new()
			tooth_mesh.size = Vector3(0.04, 0.075, 0.042)
			var tooth := MeshInstance3D.new()
			tooth.mesh = tooth_mesh
			tooth.material_override = material
			tooth.position = Vector3(tooth_spec.x, tooth_spec.y, 0.0)
			item.add_child(tooth)

		var key_glow := OmniLight3D.new()
		key_glow.name = "BrassKeyWarmth"
		key_glow.light_color = Color(1.0, 0.68, 0.25)
		key_glow.light_energy = 0.22
		key_glow.omni_range = 0.9
		key_glow.position = Vector3(-0.1, 0.08, 0.0)
		key_glow.shadow_enabled = false
		item.add_child(key_glow)

	elif kind == "letter":
		# Slightly tilt the parchment toward the player and add visible ink strokes.
		item.rotation_degrees.x = -10.0
		var paper_mesh := BoxMesh.new()
		paper_mesh.size = Vector3(0.40, 0.025, 0.29)
		var paper := MeshInstance3D.new()
		paper.name = "Parchment"
		paper.mesh = paper_mesh
		paper.material_override = material
		item.add_child(paper)

		var ink := StandardMaterial3D.new()
		ink.albedo_color = Color(0.20, 0.12, 0.075)
		ink.roughness = 0.9
		var ink_widths := [0.27, 0.32, 0.24, 0.18]
		for line_index in range(4):
			var ink_mesh := BoxMesh.new()
			ink_mesh.size = Vector3(ink_widths[line_index], 0.003, 0.007)
			var ink_line := MeshInstance3D.new()
			ink_line.name = "LetterInkLine_%d" % (line_index + 1)
			ink_line.mesh = ink_mesh
			ink_line.material_override = ink
			ink_line.position = Vector3(-0.015, 0.014, -0.075 + line_index * 0.045)
			item.add_child(ink_line)

		var folded_corner_mesh := BoxMesh.new()
		folded_corner_mesh.size = Vector3(0.055, 0.004, 0.045)
		var folded_corner := MeshInstance3D.new()
		folded_corner.name = "FoldedCorner"
		folded_corner.mesh = folded_corner_mesh
		var folded_material := StandardMaterial3D.new()
		folded_material.albedo_color = Color(0.72, 0.61, 0.43)
		folded_material.roughness = 0.9
		folded_corner.material_override = folded_material
		folded_corner.position = Vector3(0.16, 0.015, -0.115)
		folded_corner.rotation_degrees.y = 10.0
		item.add_child(folded_corner)

	else:
		# The body has real brass straps, a front clasp, feet and a hinged lid.
		var chest_mesh := BoxMesh.new()
		chest_mesh.size = size
		var chest_body := MeshInstance3D.new()
		chest_body.name = "ChestBody"
		chest_body.mesh = chest_mesh
		chest_body.material_override = material
		item.add_child(chest_body)

		var trim_material := StandardMaterial3D.new()
		trim_material.albedo_color = Color(0.78, 0.48, 0.16)
		trim_material.metallic = 0.82
		trim_material.roughness = 0.22
		for band_x in [-size.x * 0.32, size.x * 0.32]:
			var band_mesh := BoxMesh.new()
			band_mesh.size = Vector3(0.04, size.y * 0.82, 0.025)
			var band := MeshInstance3D.new()
			band.mesh = band_mesh
			band.material_override = trim_material
			band.position = Vector3(band_x, 0.0, size.z * 0.5 + 0.015)
			item.add_child(band)

		var clasp_mesh := BoxMesh.new()
		clasp_mesh.size = Vector3(0.15, 0.14, 0.04)
		var clasp := MeshInstance3D.new()
		clasp.name = "BrassClasp"
		clasp.mesh = clasp_mesh
		clasp.material_override = trim_material
		clasp.position = Vector3(0.0, -0.02, size.z * 0.5 + 0.025)
		item.add_child(clasp)

		for foot_x in [-size.x * 0.38, size.x * 0.38]:
			for foot_z in [-size.z * 0.38, size.z * 0.38]:
				var foot_mesh := BoxMesh.new()
				foot_mesh.size = Vector3(0.09, 0.08, 0.09)
				var foot := MeshInstance3D.new()
				foot.mesh = foot_mesh
				foot.material_override = trim_material
				foot.position = Vector3(foot_x, -size.y * 0.5 - 0.015, foot_z)
				item.add_child(foot)

		var hinge := Node3D.new()
		hinge.name = "Lid"
		hinge.position = Vector3(0, size.y * 0.52, -size.z * 0.42)
		item.add_child(hinge)

		var lid_mesh := BoxMesh.new()
		lid_mesh.size = Vector3(size.x, 0.16, size.z)
		var lid_visual := MeshInstance3D.new()
		lid_visual.name = "LidVisual"
		lid_visual.mesh = lid_mesh
		lid_visual.position = Vector3(0, 0, size.z * 0.42)
		lid_visual.material_override = material
		hinge.add_child(lid_visual)

		var lid_trim_mesh := BoxMesh.new()
		lid_trim_mesh.size = Vector3(size.x * 0.90, 0.025, 0.025)
		var lid_trim := MeshInstance3D.new()
		lid_trim.mesh = lid_trim_mesh
		lid_trim.material_override = trim_material
		lid_trim.position = Vector3(0.0, 0.09, size.z * 0.42)
		hinge.add_child(lid_trim)

	var glow := OmniLight3D.new()
	glow.name = "InteractionGlow"
	glow.light_color = Color(1.0, 0.72, 0.36) if kind == "chest" else color
	glow.light_energy = 0.18 if kind == "letter" else 0.30
	glow.omni_range = 1.35
	glow.position.y = 0.25
	glow.shadow_enabled = false
	item.add_child(glow)
	return item

func _add_lantern(pos: Vector3) -> void:
	var body := _box("Lantern", pos, Vector3(0.22, 0.34, 0.22), Color(0.65, 0.28, 0.06), false)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.52, 0.18)
	light.light_energy = 1.25
	light.omni_range = 5.0
	light.shadow_enabled = false
	body.add_child(light)