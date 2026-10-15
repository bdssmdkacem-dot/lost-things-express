extends SceneTree

const ASSET_PATH := "res://assets/models/hand-posable.glb"
const OUT := "res://build/hand_orientation_review"


func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var packed := load(ASSET_PATH) as PackedScene
	if packed == null:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: GLB import failed")
		quit(1)
		return

	# Render directly in the SceneTree root viewport. A detached SubViewport can
	# return a uniform clear-color image under headless/Xvfb even when the rig is valid.

	var stage := Node3D.new()
	stage.name = "HandOrientationStage"
	root.add_child(stage)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.075, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.84)
	env.ambient_light_energy = 0.75
	env_node.environment = env
	stage.add_child(env_node)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-32.0, -28.0, 0.0)
	light.light_energy = 2.0
	stage.add_child(light)

	var camera := Camera3D.new()
	camera.fov = 42.0
	stage.add_child(camera)

	var hand := packed.instantiate() as Node3D
	if hand == null:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: root of imported scene is not Node3D")
		quit(1)
		return
	stage.add_child(hand)
	await process_frame
	await process_frame

	var bounds := _mesh_bounds(hand)
	if bounds.size.length() < 0.001:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: imported hand mesh has empty bounds")
		quit(1)
		return
	var center := bounds.get_center()
	var radius := maxf(bounds.size.length() * 0.72, 0.5)
	camera.position = center + Vector3(0.0, 0.0, radius * 2.4)
	camera.look_at(center, Vector3.UP)
	camera.make_current()

	for angle in [0, 90, 180, 270]:
		hand.rotation_degrees = Vector3(0.0, float(angle), 0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		await create_timer(0.3).timeout
		if not _save("yaw_%03d.png" % angle):
			return

	var skeletons := hand.find_children("*", "Skeleton3D", true, false)
	if skeletons.size() != 1:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: expected exactly one skeleton")
		quit(1)
		return
	var skeleton := skeletons[0] as Skeleton3D
	var index_bone := skeleton.find_bone("index_01_r")
	var middle_bone := skeleton.find_bone("middle_01_r")
	var thumb_bone := skeleton.find_bone("thumb_01_r")
	if min(index_bone, middle_bone, thumb_bone) < 0:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: expected finger bones missing")
		quit(1)
		return
	skeleton.set_bone_pose_rotation(index_bone, Quaternion(Vector3.RIGHT, deg_to_rad(28.0)))
	skeleton.set_bone_pose_rotation(middle_bone, Quaternion(Vector3.RIGHT, deg_to_rad(22.0)))
	skeleton.set_bone_pose_rotation(thumb_bone, Quaternion(Vector3.UP, deg_to_rad(22.0)))
	await process_frame
	await RenderingServer.frame_post_draw
	await create_timer(0.3).timeout
	if not _save("test_joint_pose.png"):
		return
	print("HAND_ORIENTATION_CAPTURE_COMPLETE: four views and one joint pose saved for visual review.")
	quit(0)

func _mesh_bounds(root_node: Node3D) -> AABB:
	var found := false
	var combined := AABB()
	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var transformed := mesh_instance.global_transform * mesh_instance.get_aabb()
		if not found:
			combined = transformed
			found = true
		else:
			combined = combined.merge(transformed)
	return combined

func _save(filename: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: empty main viewport image " + filename)
		quit(1)
		return false
	var sampled_colors := {}
	var non_background_pixels := 0
	var background := Color(0.075, 0.09, 0.12)
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var color: Color = image.get_pixel(x, y)
			sampled_colors[color.to_rgba32()] = true
			if Vector3(color.r, color.g, color.b).distance_to(Vector3(background.r, background.g, background.b)) > 0.06:
				non_background_pixels += 1
	if sampled_colors.size() < 20 or non_background_pixels < 100:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: image appears blank (" + str(sampled_colors.size()) + " colors, " + str(non_background_pixels) + " foreground samples): " + filename)
		quit(1)
		return false
	var path := ProjectSettings.globalize_path(OUT.path_join(filename))
	var err := image.save_png(path)
	if err != OK:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: could not save " + filename)
		quit(1)
		return false
	print("HAND_ORIENTATION_CAPTURE_SAVED: " + path + " (" + str(sampled_colors.size()) + " colors)")
	return true
