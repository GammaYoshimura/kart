extends SceneTree

var _passed_cases: int = 0
var _failed_cases: int = 0
var _assertions: int = 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var test_paths: PackedStringArray = PackedStringArray()
	_discover_tests("res://tests", test_paths)
	test_paths.sort()
	for path: String in test_paths:
		_run_case(path)
	print("Tests: %d passed, %d failed; %d assertions." % [_passed_cases, _failed_cases, _assertions])
	quit(1 if _failed_cases > 0 else 0)

func _discover_tests(path: String, results: PackedStringArray) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_discover_tests(full_path, results)
			elif entry.begins_with("test_") and entry.ends_with(".gd") and entry not in ["test_case.gd", "test_runner.gd"]:
				results.append(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _run_case(path: String) -> void:
	var script: Script = ResourceLoader.load(path) as Script
	if script == null:
		push_error("Could not load test script: %s" % path)
		_failed_cases += 1
		return
	var test_case: Variant = script.new()
	if not test_case is RefCounted or not test_case.has_method("assert_true"):
		push_error("Test script must extend GdTestCase: %s" % path)
		_failed_cases += 1
		return
	for method: Dictionary in test_case.get_method_list():
		var method_name: String = str(method["name"])
		if method_name.begins_with("test_"):
			test_case.call(method_name)
	_assertions += int(test_case.get("assertion_count"))
	var failures: PackedStringArray = test_case.get("failures")
	if failures.is_empty():
		_passed_cases += 1
		print("PASS %s (%d assertions)" % [path, int(test_case.get("assertion_count"))])
	else:
		_failed_cases += 1
		for failure: String in failures:
			push_error("FAIL %s: %s" % [path, failure])
