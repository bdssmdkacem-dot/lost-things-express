extends Node3D
## First playable foundation. Geometry is temporary; the art direction is locked in docs/ART_DIRECTION.md.

const WALK_SPEED := 3.0
const LOOK_SENSITIVITY := 0.004
const INTERACT_DISTANCE := 2.2

var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var objective_label: Label
var prompt_label: Label
var interact_button: Button
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

func _ready() -> void:
	_setup_input_map()
	_build_world()
	_build_player()
	_build_ui()
	_set_status("The train has arrived at a station that appears on no map.")

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
	environment.ambient_light_color = Color(0.40, 0.46, 0.52)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -25, 0)
	sun.light_color = Color(1.0, 0.72, 0.43)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)

	# Carriage shell. These simple meshes validate scale and mechanics only.
	_box("Floor", Vector3(0, -0.12, 0), Vector3(5.8, 0.24, 12.0), Color(0.16, 0.075, 0.045))
	_box("Ceiling", Vector3(0, 3.5, 0), Vector3(5.8, 0.18, 12.0), Color(0.09, 0.045, 0.032))
	_box("Left wall", Vector3(-2.85, 1.65, 0), Vector3(0.18, 3.3, 12.0), Color(0.12, 0.055, 0.035))
	_box("Right wall", Vector3(2.85, 1.65, 0), Vector3(0.18, 3.3, 12.0), Color(0.12, 0.055, 0.035))
	_box("Rear wall", Vector3(0, 1.65, -5.95), Vector3(5.8, 3.3, 0.18), Color(0.10, 0.045, 0.03))
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

	_create_interactable("Brass Key", Vector3(-0.45, 0.55, -1.1), Color(0.95, 0.62, 0.16), "key")
	_create_interactable("Torn Letter", Vector3(0.55, 0.48, 1.0), Color(0.82, 0.72, 0.52), "letter")
	_create_interactable("Memory Chest", Vector3(0.0, 0.45, -4.45), Color(0.33, 0.12, 0.055), "chest", Vector3(0.95, 0.75, 0.65))

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
	status_label.anchor_bottom = 0.16
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.58))
	root.add_child(status_label)

	objective_label = Label.new()
	objective_label.anchor_left = 0.04
	objective_label.anchor_top = 0.16
	objective_label.anchor_right = 0.78
	objective_label.anchor_bottom = 0.24
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color(0.91, 0.89, 0.82))
	root.add_child(objective_label)

	prompt_label = Label.new()
	prompt_label.anchor_left = 0.18
	prompt_label.anchor_top = 0.76
	prompt_label.anchor_right = 0.76
	prompt_label.anchor_bottom = 0.88
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color(1, 0.91, 0.73))
	root.add_child(prompt_label)

	interact_button = Button.new()
	interact_button.text = "INTERACT"
	interact_button.anchor_left = 0.80
	interact_button.anchor_top = 0.78
	interact_button.anchor_right = 0.96
	interact_button.anchor_bottom = 0.92
	interact_button.add_theme_font_size_override("font_size", 22)
	interact_button.pressed.connect(_interact)
	root.add_child(interact_button)

	var hint := Label.new()
	hint.text = "Drag the left side to move • drag the right side to look"
	hint.anchor_left = 0.15
	hint.anchor_top = 0.94
	hint.anchor_right = 0.80
	hint.anchor_bottom = 0.99
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.84, 0.81))
	root.add_child(hint)

func _process(_delta: float) -> void:
	_update_nearby()
	objective_label.text = _objective_text()
	interact_button.disabled = nearby_object == null
	prompt_label.text = "Inspect: " + str(nearby_object.get_meta("display_name", "object")) if nearby_object else ""

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
			var drag := (event.position - touch_move_origin) / 90.0
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
		if not is_instance_valid(node):
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance < nearest:
			nearest = distance
			nearby_object = node

func _interact() -> void:
	if nearby_object == null:
		return
	var kind: String = nearby_object.get_meta("kind", "")
	match kind:
		"key":
			if not has_key:
				has_key = true
				nearby_object.queue_free()
				_set_status("You found a brass key. Who does it belong to?")
			else:
				_set_status("You already have the key.")
		"letter":
			letter_read = true
			nearby_object.set_meta("display_name", "Letter read")
			_set_status("The letter reads: “When the clock strikes three times, return what the traveler forgot.”")
		"chest":
			if chest_open:
				_set_status("Inside the chest is a small memory: a photograph of a station at sunset.")
			elif not has_key:
				_set_status("The chest is locked. Find the brass key.")
			elif not letter_read:
				_set_status("You need to understand the letter before opening the chest.")
			else:
				chest_open = true
				nearby_object.set_meta("display_name", "Open chest")
				var lid := nearby_object.get_node_or_null("Lid") as Node3D
				if lid:
					lid.rotation.x = deg_to_rad(-72.0)
				_set_status("The chest opens! Inside is an old photograph and a new destination: Sunset Station.")
		_:
			_set_status("Nothing happens here yet.")

func _objective_text() -> String:
	if chest_open:
		return "Objective complete: Get ready to leave Sunset Station."
	if not has_key:
		return "Objective: Find the brass key near the seats."
	if not letter_read:
		return "Objective: Read the letter to uncover the chest’s secret."
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

	var visual := MeshInstance3D.new()
	var mesh: Mesh
	if kind == "key":
		var ring := TorusMesh.new()
		ring.inner_radius = 0.07
		ring.outer_radius = 0.12
		mesh = ring
	elif kind == "letter":
		var paper := BoxMesh.new()
		paper.size = Vector3(0.36, 0.025, 0.25)
		mesh = paper
	else:
		var chest_mesh := BoxMesh.new()
		chest_mesh.size = size
		mesh = chest_mesh
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.65 if kind == "key" else 0.12
	material.roughness = 0.3
	visual.material_override = material
	item.add_child(visual)

	if kind == "chest":
		var lid := MeshInstance3D.new()
		lid.name = "Lid"
		var lid_mesh := BoxMesh.new()
		lid_mesh.size = Vector3(size.x, 0.16, size.z)
		lid.mesh = lid_mesh
		lid.position = Vector3(0, size.y * 0.52, -size.z * 0.42)
		lid.material_override = material
		item.add_child(lid)

	var glow := OmniLight3D.new()
	glow.light_color = color
	glow.light_energy = 0.35
	glow.omni_range = 1.5
	glow.position.y = 0.25
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
