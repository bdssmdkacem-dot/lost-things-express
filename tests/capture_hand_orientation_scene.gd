extends Node3D

const ASSET_PATH := "res://assets/models/hand-posable.glb"
const OUT := "res://build/hand_orientation_review"

var hand: Node3D
var skeleton: Skeleton3D
var camera: Camera3D

func _ready() -> void:
	_run_capture()

func _run_capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var packed := load(ASSET_PATH) as PackedScene
	if packed == null:
		_fail("GLB import failed")
		return
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.075, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.84)
	env.ambient_light_energy = 0.75
	env_node.environment = env
	add_child(env_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-32.0, -28.0, 0.0)
	light.light_energy = 2.0
	add_child(light)
	camera = Camera3D.new()
	camera.fov = 42.0
	add_child(camera)
	hand = packed.instantiate() as Node3D
	if hand == null:
		_fail("imported scene root is not Node3D")
		return
	add_child(hand)
	await get_tree().process_frame
	await get_tree().process_frame
	var meshes := hand.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		_fail("no MeshInstance3D nodes")
		return
	var bounds := _mesh_bounds()
	if bounds.size.length() < 0.001:
		_fail("empty mesh bounds")
		return
	hand.position -= bounds.get_center()
	await get_tree().process_frame
	bounds = _mesh_bounds()
	var radius := maxf(bounds.size.length() * 0.72, 0.5)
	camera.near = 0.01
	camera.far = 100.0
	camera.position = bounds.get_center() + Vector3(0.0, 0.0, radius * 2.4)
	camera.look_at(bounds.get_center(), Vector3.UP)
	camera.make_current()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.38, 0.12)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.material_override = mat
		var resolved_skeleton := mesh_instance.get_node_or_null(mesh_instance.skeleton) as Skeleton3D if mesh_instance.skeleton != NodePath() else null
		print("HAND_SKIN_BIND_DIAGNOSTIC: skeleton_resolved=%s skeleton_global=%s bind_count=%d mesh_global=%s" % [
			str(resolved_skeleton != null),
			str(resolved_skeleton.global_transform) if resolved_skeleton != null else "<null>",
			mesh_instance.skin.get_bind_count() if mesh_instance.skin != null else -1,
			str(mesh_instance.global_transform)
		])
		if resolved_skeleton != null and mesh_instance.skin != null:
			for bind_index in range(mesh_instance.skin.get_bind_count()):
				var bind_bone := mesh_instance.skin.get_bind_bone(bind_index)
				print("HAND_SKIN_BIND: index=%d bone=%d bind_name=%s resolved_name=%s pose=%s" % [
					bind_index, bind_bone, mesh_instance.skin.get_bind_name(bind_index),
					resolved_skeleton.get_bone_name(bind_bone) if bind_bone >= 0 and bind_bone < resolved_skeleton.get_bone_count() else "<invalid>",
					str(mesh_instance.skin.get_bind_pose(bind_index))
				])
		print("HAND_MESH_DIAGNOSTIC: path=%s visible=%s mesh=%s surfaces=%d skin=%s skeleton_path=%s global=%s local_aabb=%s" % [
			str(mesh_instance.get_path()), str(mesh_instance.is_visible_in_tree()),
			str(mesh_instance.mesh), mesh_instance.mesh.get_surface_count() if mesh_instance.mesh != null else -1,
			str(mesh_instance.skin != null), str(mesh_instance.skeleton),
			str(mesh_instance.global_transform), str(mesh_instance.get_aabb())
		])
	print("HAND_CAMERA_DIAGNOSTIC: bounds=%s camera=%s looking_at=%s" % [str(bounds), str(camera.global_position), str(bounds.get_center())])
	# Diagnostic only: duplicate the imported surface without skinning to isolate whether
	# the blank render is caused by the imported mesh geometry or its Skin/Skeleton binding.
	var source_mesh := meshes[0] as MeshInstance3D
	var raw_mesh := ArrayMesh.new()
	if source_mesh.mesh != null:
		for surface_index in range(source_mesh.mesh.get_surface_count()):
			var arrays := source_mesh.mesh.surface_get_arrays(surface_index)
			raw_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var raw_material := StandardMaterial3D.new()
			raw_material.albedo_color = Color(0.95, 0.38, 0.12)
			raw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			raw_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			raw_mesh.surface_set_material(surface_index, raw_material)
	var raw_instance := MeshInstance3D.new()
	raw_instance.mesh = raw_mesh
	raw_instance.global_transform = source_mesh.global_transform
	add_child(raw_instance)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not await _save("unskinned_mesh_probe.png"):
		return
	raw_instance.queue_free()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var probe_mesh := SphereMesh.new()
	probe_mesh.radius = maxf(bounds.size.length() * 0.08, 0.025)
	probe_mesh.height = probe_mesh.radius * 2.0
	var probe := MeshInstance3D.new()
	probe.mesh = probe_mesh
	var probe_mat := StandardMaterial3D.new()
	probe_mat.albedo_color = Color(0.1, 1.0, 0.2)
	probe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	probe.material_override = probe_mat
	probe.position = bounds.get_center()
	add_child(probe)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not await _save("camera_probe.png"):
		return
	probe.queue_free()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for angle in [0, 90, 180, 270]:
		hand.rotation_degrees = Vector3(0.0, float(angle), 0.0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if not await _save("yaw_%03d.png" % angle):
			return
	var skeletons := hand.find_children("*", "Skeleton3D", true, false)
	skeleton = skeletons[0] as Skeleton3D if skeletons.size() == 1 else null
	if skeleton == null:
		_fail("expected exactly one Skeleton3D")
		return
	var i := skeleton.find_bone("index_01_r")
	var m := skeleton.find_bone("middle_01_r")
	var t := skeleton.find_bone("thumb_01_r")
	if min(i, min(m, t)) < 0:
		_fail("finger bones missing")
		return
	skeleton.set_bone_pose_rotation(i, Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))
	skeleton.set_bone_pose_rotation(m, Quaternion(Vector3.RIGHT, deg_to_rad(22.0)))
	skeleton.set_bone_pose_rotation(t, Quaternion(Vector3.UP, deg_to_rad(22.0)))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not await _save("test_joint_pose.png"):
		return
	print("HAND_ORIENTATION_CAPTURE_COMPLETE: scene-based main-viewport renders saved.")
	get_tree().quit(0)

func _mesh_bounds() -> AABB:
	var found := false
	var combined := AABB()
	for node in hand.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box := mi.global_transform * mi.get_aabb()
		combined = box if not found else combined.merge(box)
		found = true
	return combined

func _save(filename: String) -> bool:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("empty viewport image " + filename)
		return false
	var background := Color(0.075, 0.09, 0.12)
	var foreground := 0
	var colors := {}
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var px := image.get_pixel(x, y)
			colors[px.to_rgba32()] = true
			if Vector3(px.r, px.g, px.b).distance_to(Vector3(background.r, background.g, background.b)) > 0.06:
				foreground += 1
	var path := ProjectSettings.globalize_path(OUT.path_join(filename))
	if image.save_png(path) != OK:
		_fail("failed saving " + filename)
		return false
	print("HAND_CAPTURE_DIAGNOSTIC: %s colors=%d foreground=%d" % [filename, colors.size(), foreground])
	if colors.size() < 2 or foreground < 100:
		_fail("blank render " + filename)
		return false
	return true

func _fail(message: String) -> void:
	push_error("HAND_ORIENTATION_CAPTURE_FAILED: " + message)
	get_tree().quit(1)
