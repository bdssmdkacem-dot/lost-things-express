extends SceneTree

const ASSET_PATH := "res://assets/models/hand-posable.glb"
const REQUIRED_BONES := [
	"hand_r",
	"index_01_r", "index_02_r", "index_03_r",
	"middle_01_r", "middle_02_r", "middle_03_r",
	"ring_01_r", "ring_02_r", "ring_03_r",
	"pinky_01_r", "pinky_02_r", "pinky_03_r",
	"thumb_01_r", "thumb_02_r", "thumb_03_r",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(ASSET_PATH) as PackedScene
	if not _check(packed != null, "anatomical hand GLB did not import as PackedScene"):
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame

	var skeletons := instance.find_children("*", "Skeleton3D", true, false)
	if not _check(skeletons.size() == 1, "expected exactly one Skeleton3D in the hand asset"):
		return
	var skeleton := skeletons[0] as Skeleton3D
	if not _check(skeleton.get_bone_count() == REQUIRED_BONES.size(), "unexpected bone count; update the rig mapping only after review"):
		return

	var indices: Dictionary = {}
	for bone_name in REQUIRED_BONES:
		var index := skeleton.find_bone(bone_name)
		if not _check(index >= 0, "required named bone is missing: " + bone_name):
			return
		indices[bone_name] = index

	for finger in ["index", "middle", "ring", "pinky", "thumb"]:
		for segment in range(1, 4):
			var name := "%s_%02d_r" % [finger, segment]
			var bone_index: int = indices[name]
			var expected_parent: int = indices["hand_r"] if segment == 1 else indices["%s_%02d_r" % [finger, segment - 1]]
			if not _check(skeleton.get_bone_parent(bone_index) == expected_parent, "%s is not parented to the expected joint" % name):
				return

	# Verify imported rest transforms are finite and normalized before any game pose is applied.
	for i in range(skeleton.get_bone_count()):
		var basis := skeleton.get_bone_rest(i).basis
		if not _check(is_finite(basis.x.length()) and is_finite(basis.y.length()) and is_finite(basis.z.length()), "bone rest transform contains a non-finite axis"):
			return
		if not _check(absf(basis.x.length() - 1.0) < 0.03 and absf(basis.y.length() - 1.0) < 0.03 and absf(basis.z.length() - 1.0) < 0.03, "bone rest axes are not normalized; investigate imported scale/orientation"):
			return

	# Exercise one distal joint without committing a pose; reset it and ensure the rig remains usable.
	var distal: int = indices["index_03_r"]
	skeleton.set_bone_pose_rotation(distal, Quaternion(Vector3.RIGHT, deg_to_rad(18.0)))
	await process_frame
	if not _check(skeleton.get_bone_pose_rotation(distal).is_equal_approx(Quaternion(Vector3.RIGHT, deg_to_rad(18.0))), "distal joint pose could not be applied"):
		return
	skeleton.set_bone_pose_rotation(distal, Quaternion.IDENTITY)
	await process_frame
	if not _check(skeleton.get_bone_pose_rotation(distal).is_equal_approx(Quaternion.IDENTITY), "distal joint pose could not be reset"):
		return

	var skinned_meshes := instance.find_children("*", "MeshInstance3D", true, false)
	if not _check(not skinned_meshes.is_empty(), "the hand asset has no mesh instances"):
		return
	var has_skin := false
	for node in skinned_meshes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.skin != null and mesh_instance.skeleton != NodePath():
			has_skin = true
	if not _check(has_skin, "no MeshInstance3D exposes both a Skin resource and a skeleton path"):
		return

	print("HAND_RIG_SMOKE_TEST_PASS: named bones, parent chains, normalized rest axes, reversible joint pose, and skin binding.")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("HAND_RIG_SMOKE_TEST_FAILED: " + message)
	quit(1)
	return false
