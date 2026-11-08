extends SceneTree

const MAX_MODEL_TRIANGLES: int = 150_000
const MAX_TEXTURE_DIMENSION: int = 2048

var _violations: int = 0

func _initialize() -> void:
	_scan_directory("res://assets")
	if _violations == 0:
		print("Asset audit passed: no assets exceed the Android budgets.")
	else:
		push_error("Asset audit found %d budget violation(s)." % _violations)
	quit(1 if _violations > 0 else 0)

func _scan_directory(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		push_error("Cannot open asset directory: %s" % path)
		_violations += 1
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var full_path: String = path.path_join(entry)
		if directory.current_is_dir():
			_scan_directory(full_path)
		else:
			_audit_file(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _audit_file(path: String) -> void:
	var extension: String = path.get_extension().to_lower()
	if extension in ["png", "webp", "tga", "jpg", "jpeg"]:
		var image: Image = Image.new()
		var image_error: Error = image.load(ProjectSettings.globalize_path(path))
		if image_error != OK:
			_report("Texture could not be read: %s" % path)
		elif image.get_width() > MAX_TEXTURE_DIMENSION or image.get_height() > MAX_TEXTURE_DIMENSION:
			_report("Texture exceeds %d px: %s (%dx%d)" % [MAX_TEXTURE_DIMENSION, path, image.get_width(), image.get_height()])
	elif extension in ["glb", "gltf", "fbx", "obj"]:
		var packed_scene: PackedScene = ResourceLoader.load(path) as PackedScene
		if packed_scene == null:
			_report("Model could not be imported as a scene: %s" % path)
			return
		var instance: Node = packed_scene.instantiate()
		var triangle_count: int = _count_triangles(instance)
		instance.free()
		if triangle_count > MAX_MODEL_TRIANGLES:
			_report("Model exceeds %d triangles: %s (%d)" % [MAX_MODEL_TRIANGLES, path, triangle_count])

func _count_triangles(node: Node) -> int:
	var triangle_count: int = 0
	if node is MeshInstance3D and node.mesh != null:
		triangle_count += node.mesh.get_faces().size() / 3
	for child: Node in node.get_children():
		triangle_count += _count_triangles(child)
	return triangle_count

func _report(message: String) -> void:
	push_warning(message)
	_violations += 1
