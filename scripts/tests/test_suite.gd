class_name BtvTestSuite
extends RefCounted

## Minimal first-party test base. No editor, autoloads, or plugin required.

var registry: ContentRegistry = null
var loc: Localization = null
var failures: Array = []
var assertions: int = 0
var current_test: String = ""

func bind(content_registry: ContentRegistry, localization: Localization) -> void:
	registry = content_registry
	loc = localization

func begin_case(test_name: String) -> void:
	current_test = test_name
	failures.clear()
	assertions = 0

func category() -> String:
	return "unit"

func check(condition: bool, message: String) -> bool:
	assertions += 1
	if not condition:
		failures.append({"test": current_test, "message": message})
		return false
	return true

func equal(actual, expected, message: String) -> bool:
	assertions += 1
	if actual != expected:
		failures.append({"test": current_test, "message": "%s (expected %s, got %s)" % [message, str(expected), str(actual)]})
		return false
	return true

func near(actual: float, expected: float, tolerance: float, message: String) -> bool:
	assertions += 1
	if absf(actual - expected) > tolerance:
		failures.append({"test": current_test, "message": "%s (expected %s +/- %s, got %s)" % [message, str(expected), str(tolerance), str(actual)]})
		return false
	return true

func not_null(value, message: String) -> bool:
	return check(value != null, message)

func new_session(seed_value: int = 424242) -> GameSession:
	var session := GameSession.new(registry)
	session.new_game(seed_value)
	return session

func new_player(seed_value: int = 424242) -> GameSession:
	var session := new_session(seed_value)
	var landed := session.land_on("planet.vela")
	if not check(bool(landed.get("ok", false)), "landing on Vela should succeed: " + str(landed)):
		return null
	return session
