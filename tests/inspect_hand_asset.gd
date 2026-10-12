extends SceneTree

const ASSET_PATH := "res://assets/models/hand-posable.glb"
const REPORT_PATH := "res://build/hand_inspection/hand-rig-report.txt"

func _initialize() -> void:
	call_deferred("_inspect")

func _inspect() -> void:
	var report := PackedStringArray()
	report.append("CC0 anatomical hand import inspection")
	report.append("Asset: " + ASSET_PATH)
	var packed := load(ASSET_PATH) as PackedScene
	if packed == null:
		report.append("ERROR: GLB did not import as PackedScene")
		_write_report(report)
		push_error(report[-1])
		quit(1)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	report.append("Root node: %s (%s)" % [instance.name, instance.get_class()])
	_walk(instance, report, 0)
	var skeletons := instance.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		report.append("ERROR: no Skeleton3D was imported")
		_write_report(report)
		push_error(report[-1])
		quit(1)
		return
	for candidate in skeletons:
		var skeleton := candidate as Skeleton3D
		report.append("")
		report.append("SKELETON: %s | bones=%d" % [skeleton.get_path(), skeleton.get_bone_count()])
		for i in range(skeleton.get_bone_count()):
			var rest := skeleton.get_bone_rest(i)
			var parent := skeleton.get_bone_parent(i)
			report.append("bone[%02d] name=%s parent=%d:%s origin=%s axisX=%s axisY=%s axisZ=%s" % [
				i,
				skeleton.get_bone_name(i),
				parent,
				skeleton.get_bone_name(parent) if parent >= 0 else "<root>",
				str(rest.origin),
				str(rest.basis.x.normalized()),
				str(rest.basis.y.normalized()),
				str(rest.basis.z.normalized())
			])
	if skeletons.size() != 1:
		report.append("WARNING: expected one Skeleton3D, found %d" % skeletons.size())
	_write_report(report)
	print("\n".join(report))
	quit(0)

func _walk(node: Node, report: PackedStringArray, depth: int) -> void:
	if depth <= 4:
		report.append("%s%s (%s)" % ["  ".repeat(depth), node.name, node.get_class()])
	for child in node.get_children():
		_walk(child, report, depth + 1)

func _write_report(report: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/hand_inspection"))
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(report) + "\n")
