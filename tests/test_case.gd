class_name GdTestCase
extends RefCounted

var assertion_count: int = 0
var failures: PackedStringArray = PackedStringArray()

func assert_eq(actual: Variant, expected: Variant, context: String = "") -> void:
	assertion_count += 1
	if actual != expected:
		_fail("Expected %s, got %s" % [str(expected), str(actual)], context)

func assert_ne(actual: Variant, expected: Variant, context: String = "") -> void:
	assertion_count += 1
	if actual == expected:
		_fail("Expected values to differ: %s" % str(actual), context)

func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.0001, context: String = "") -> void:
	assertion_count += 1
	if absf(actual - expected) > tolerance:
		_fail("Expected %f ± %f, got %f" % [expected, tolerance, actual], context)

func assert_Almost_eq(actual: float, expected: float, tolerance: float = 0.0001, context: String = "") -> void:
	assert_almost_eq(actual, expected, tolerance, context)

func assert_vec3_approx(actual: Vector3, expected: Vector3, tolerance: float = 0.0001, context: String = "") -> void:
	assertion_count += 1
	if actual.distance_to(expected) > tolerance:
		_fail("Expected %s ± %f, got %s" % [str(expected), tolerance, str(actual)], context)

func assert_true(value: bool, context: String = "") -> void:
	assertion_count += 1
	if not value:
		_fail("Expected true", context)

func assert_false(value: bool, context: String = "") -> void:
	assertion_count += 1
	if value:
		_fail("Expected false", context)

func _fail(message: String, context: String) -> void:
	failures.append("%s%s" % [message, " (%s)" % context if not context.is_empty() else ""])
