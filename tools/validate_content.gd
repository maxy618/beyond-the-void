extends SceneTree

## Static content validation entry point. Exit code 0 only when the pack is valid.

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var registry := ContentRegistry.new()
	var ok := registry.load_all("res://content")
	print("pack=", registry.pack_id, " version=", registry.content_version)
	print("counts=", registry.counts())
	for warning in registry.warnings:
		print("WARNING: ", warning)
	for error in registry.errors:
		print("ERROR: ", error)
	var report := {
		"schema_version": 1,
		"generated_at_unix": int(Time.get_unix_time_from_system()),
		"engine_version": str(Engine.get_version_info().get("string", "")),
		"pack_id": registry.pack_id,
		"content_version": registry.content_version,
		"pack_schema_version": registry.pack_schema_version,
		"generator_version": registry.generator_version,
		"ok": ok,
		"counts": registry.counts(),
		"warnings": registry.warnings,
		"errors": registry.errors,
		"duration_ms": Time.get_ticks_msec() - started,
	}
	var path := "res://build/reports/content_validation.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/reports"))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("CONTENT_OK=", ok)
	quit(0 if ok else 1)
