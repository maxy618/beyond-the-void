class_name Localization
extends RefCounted

## Locale-independent string table. All player-facing text comes from content packs.

var locale: String = "en"
var strings: Dictionary = {}
var errors: Array[String] = []

func load_manifest(manifest: Dictionary, content_root: String) -> bool:
	strings.clear()
	errors.clear()
	locale = "en"
	var entries: Array = manifest.get("localization", [])
	for entry in entries:
		var rel: String = str(entry.get("path", ""))
		if rel.is_empty():
			errors.append("localization entry without path")
			continue
		var data: Dictionary = _read_json(content_root.path_join(rel))
		if data.is_empty():
			errors.append("cannot read localization file: " + rel)
			continue
		var loc: String = str(data.get("locale", "en"))
		if loc != "en":
			continue
		var table = data.get("strings", {})
		if typeof(table) != TYPE_DICTIONARY:
			errors.append("localization strings must be an object: " + rel)
			continue
		for key in table.keys():
			strings[str(key)] = str(table[key])
	return errors.is_empty()

func t(key: String, args: Dictionary = {}) -> String:
	var text: String = str(strings.get(key, "⟦" + key + "⟧"))
	for arg_key in args.keys():
		text = text.replace("{" + str(arg_key) + "}", str(args[arg_key]))
	return text

func has(key: String) -> bool:
	return strings.has(key)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed = json.data
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
