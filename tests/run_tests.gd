extends SceneTree

## First-party headless test runner: Godot --headless --script res://tests/run_tests.gd

const SUITES := [
	"res://scripts/tests/test_content.gd",
	"res://scripts/tests/test_inventory_crafting.gd",
	"res://scripts/tests/test_market.gd",
	"res://scripts/tests/test_ecology.gd",
	"res://scripts/tests/test_quest_dialogue.gd",
	"res://scripts/tests/test_build_ship.gd",
	"res://scripts/tests/test_save.gd",
	"res://scripts/tests/test_worldgen.gd",
	"res://scripts/tests/test_input.gd",
	"res://scripts/tests/test_e2e.gd",
]

const REPORT_DIR := "res://build/reports"

var registry: ContentRegistry = null
var all_results: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var started := Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	registry = ContentRegistry.new()
	if not registry.load_all("res://content"):
		var message := "content pack failed to load: " + str(registry.errors)
		print("TEST_RUN_ABORTED " + message)
		_write_json(REPORT_DIR + "/unit_tests.json", _report([], started, message))
		quit(2)
		return

	for suite_path in SUITES:
		var script = load(suite_path)
		if script == null or not (script is GDScript) or not script.can_instantiate():
			all_results.append({"suite": suite_path, "test": "<load>", "category": "unit", "status": "error", "message": "could not load suite", "assertions": 0, "duration_ms": 0})
			print("ERROR could not load suite " + suite_path)
			continue
		var suite = script.new()
		suite.bind(registry, registry.loc)
		var methods: Array = []
		for method in suite.get_method_list():
			var method_name := str(method.get("name", ""))
			if method_name.begins_with("test_") and not method_name in methods:
				methods.append(method_name)
		methods.sort()
		for method_name in methods:
			var case_started := Time.get_ticks_msec()
			suite.begin_case(method_name)
			suite.call(method_name)
			var duration := Time.get_ticks_msec() - case_started
			var status := "passed"
			var message := ""
			if not suite.failures.is_empty():
				status = "failed"
				var messages: Array = []
				for failure in suite.failures:
					messages.append(str(failure.get("message", "")))
				message = "; ".join(messages)
			elif suite.assertions == 0:
				status = "error"
				message = "test made no assertions"
			all_results.append({
				"suite": str(suite_path),
				"test": str(method_name),
				"category": suite.category(),
				"status": status,
				"message": message,
				"assertions": suite.assertions,
				"duration_ms": duration,
			})
			print("%s %s::%s%s" % [status.to_upper(), str(suite_path).get_file(), method_name, ("" if message.is_empty() else " - " + message)])

	var unit: Array = []
	var integration: Array = []
	for result in all_results:
		if result.get("category", "unit") == "integration":
			integration.append(result)
		else:
			unit.append(result)
	_write_json(REPORT_DIR + "/unit_tests.json", _report(unit, started, ""))
	_write_json(REPORT_DIR + "/integration_tests.json", _report(integration, started, ""))
	var e2e := _report(integration, started, "")
	e2e["scenario"] = "vertical_slice"
	_write_json(REPORT_DIR + "/e2e_vertical_slice.json", e2e)
	_write_junit(REPORT_DIR + "/unit_tests.xml", unit)

	var passed := 0
	var failed := 0
	var errors := 0
	for result in all_results:
		match str(result.get("status", "")):
			"passed": passed += 1
			"failed": failed += 1
			_: errors += 1
	var summary := "TESTS run=%d passed=%d failed=%d errors=%d duration_ms=%d" % [all_results.size(), passed, failed, errors, Time.get_ticks_msec() - started]
	print(summary)
	quit(0 if failed == 0 and errors == 0 else 1)

func _report(results: Array, started: int, error: String) -> Dictionary:
	var passed := 0
	var failed := 0
	for result in results:
		if str(result.get("status", "")) == "passed":
			passed += 1
		else:
			failed += 1
	return {
		"schema_version": 1,
		"generated_at_unix": int(Time.get_unix_time_from_system()),
		"engine_version": str(Engine.get_version_info().get("string", "")),
		"project": "res://project.godot",
		"duration_ms": Time.get_ticks_msec() - started,
		"total": results.size(),
		"passed": passed,
		"failed": failed,
		"abort_reason": error,
		"results": results,
	}

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("cannot write report " + path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _write_junit(path: String, results: Array) -> void:
	var failures := 0
	for result in results:
		if str(result.get("status", "")) != "passed":
			failures += 1
	var lines: Array = [
		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
		"<testsuites name=\"beyond-the-void\" tests=\"%d\" failures=\"%d\">" % [results.size(), failures],
		"  <testsuite name=\"first-party\" tests=\"%d\" failures=\"%d\">" % [results.size(), failures],
	]
	for result in results:
		var suite_name := str(result.get("suite", "")).get_file().get_basename()
		var test_name := str(result.get("test", ""))
		lines.append("    <testcase classname=\"%s\" name=\"%s\" time=\"%.3f\">" % [_xml(suite_name), _xml(test_name), float(result.get("duration_ms", 0)) / 1000.0])
		if str(result.get("status", "")) != "passed":
			lines.append("      <failure message=\"%s\">%s</failure>" % [_xml(str(result.get("message", ""))), _xml(str(result.get("message", "")))])
		lines.append("    </testcase>")
	lines.append("  </testsuite>")
	lines.append("</testsuites>")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines))
		file.close()

func _xml(value: String) -> String:
	return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")
