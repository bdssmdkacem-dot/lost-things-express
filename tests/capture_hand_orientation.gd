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
	camera.position = Vector3(0.0, 0.0, 2.8)
	stage.add_child(camera)
	var hand := packed.instantiate() as Node3D
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
	await create_timer(0.25).timeout
	for angle in [0, 90, 180, 270]:
		hand.rotation_degrees = Vector3(0.0, float(angle), 0.0)
		await process_frame
		await RenderingServer.frame_post_draw
		await create_timer(0.15).timeout
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
		var local := mesh_instance.get_aabb()
		var transformed := mesh_instance.global_transform * local
		if not found:
			combined = transformed
			found = true
		else:
			combined = combined.merge(transformed)
	return combined

func _save(filename: String) -> bool:
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: empty viewport image " + filename)
		quit(1)
		return false
	var path := ProjectSettings.globalize_path(OUT.path_join(filename))
	var err := image.save_png(path)
	if err != OK:
		push_error("HAND_ORIENTATION_CAPTURE_FAILED: could not save " + filename)
		quit(1)
		return false
	print("HAND_ORIENTATION_CAPTURE_SAVED: " + path)
	return true
