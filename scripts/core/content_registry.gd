class_name ContentRegistry
extends RefCounted

## Loads the versioned external content pack. No gameplay state lives here.

const MANIFEST_PATH := "manifests/base_content.json"

var content_root: String = "res://content"
var manifest: Dictionary = {}
var manifest_files: Array = []
var pack_id: String = ""
var content_version: String = ""
var pack_schema_version: int = 0
var generator_version: int = 0
var loc: Localization = null
var errors: Array[String] = []
var warnings: Array[String] = []
var load_ok: bool = false

var items: Dictionary = {}
var recipes: Dictionary = {}
var species: Dictionary = {}
var hulls: Dictionary = {}
var ship_modules: Dictionary = {}
var markets: Dictionary = {}
var quests: Dictionary = {}
var dialogues: Dictionary = {}
var buildings: Dictionary = {}
var planets: Dictionary = {}
var systems: Dictionary = {}
var settlements: Dictionary = {}
var ecologies: Dictionary = {}
var multitool_modes: Dictionary = {}

var _buckets: Dictionary = {}
var _id_kind: Dictionary = {}
var _file_versions: Dictionary = {}

func load_all(root: String = "res://content") -> bool:
	content_root = root
	_reset()
	var manifest_data: Dictionary = _read_json(root.path_join(MANIFEST_PATH))
	if manifest_data.is_empty():
		errors.append("manifest missing or unreadable: " + root.path_join(MANIFEST_PATH))
		load_ok = false
		return false
	manifest = manifest_data
	pack_id = str(manifest.get("pack_id", ""))
	content_version = str(manifest.get("content_version", ""))
	pack_schema_version = int(manifest.get("schema_version", 0))
	generator_version = int(manifest.get("generator_version", 0))
	if pack_id.is_empty() or content_version.is_empty():
		errors.append("manifest requires pack_id and content_version")
	if pack_schema_version != 1:
		errors.append("unsupported manifest schema_version %d" % pack_schema_version)

	loc = Localization.new()
	if not loc.load_manifest(manifest, root):
		errors.append_array(loc.errors)

	var files: Array = manifest.get("files", [])
	if files.is_empty():
		errors.append("manifest contains no content files")
	for entry in files:
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("manifest file entry must be an object")
			continue
		var rel: String = str(entry.get("path", ""))
		var kind: String = str(entry.get("type", ""))
		var added_ids: Array = entry.get("added_ids", [])
		if rel.is_empty() or kind.is_empty():
			errors.append("manifest file entry needs path and type")
			continue
		var data: Dictionary = _read_json(root.path_join(rel))
		if data.is_empty():
			errors.append("unreadable content file: " + rel)
			continue
		if int(data.get("schema_version", 0)) != 1:
			errors.append("unsupported schema_version in " + rel)
		_file_versions[rel] = str(data.get("content_version", ""))
		var records = data.get("records", [])
		if typeof(records) != TYPE_ARRAY:
			errors.append("records must be an array in " + rel)
			continue
		manifest_files.append({"path": rel, "type": kind, "added_ids": added_ids})
		for record in records:
			if typeof(record) != TYPE_DICTIONARY:
				errors.append("record must be an object in " + rel)
				continue
			_store(kind, record, rel)

	var validator := ContentValidator.new()
	if not validator.validate(self):
		errors.append_array(validator.errors)
	warnings.append_array(validator.warnings)
	for declared in manifest_files:
		for content_id in declared.get("added_ids", []):
			if not _declares_resolved(str(declared.get("type", "")), str(content_id)):
				errors.append("manifest declares missing ID %s in %s" % [content_id, declared.get("path", "")])
	load_ok = errors.is_empty()
	return load_ok

func _reset() -> void:
	manifest = {}
	manifest_files.clear()
	pack_id = ""
	content_version = ""
	loc = null
	errors.clear()
	warnings.clear()
	load_ok = false
	items.clear()
	recipes.clear()
	species.clear()
	hulls.clear()
	ship_modules.clear()
	markets.clear()
	quests.clear()
	dialogues.clear()
	buildings.clear()
	planets.clear()
	systems.clear()
	settlements.clear()
	ecologies.clear()
	multitool_modes.clear()
	_buckets.clear()
	_id_kind.clear()
	_file_versions.clear()
	_buckets = {
		"items": items,
		"recipes": recipes,
		"species": species,
		"hulls": hulls,
		"ship_modules": ship_modules,
		"markets": markets,
		"quests": quests,
		"dialogues": dialogues,
		"buildings": buildings,
		"planets": planets,
		"systems": systems,
		"settlements": settlements,
		"ecologies": ecologies,
		"multitool_modes": multitool_modes,
	}

func _store(kind: String, record: Dictionary, rel: String) -> void:
	var bucket_name: String = kind
	if kind == "flora" or kind == "fauna":
		bucket_name = "species"
		if not record.has("kind"):
			record["kind"] = kind
	elif kind == "hulls":
		bucket_name = "hulls"
	elif kind == "ship_modules":
		bucket_name = "ship_modules"
	elif kind == "multitool_modes":
		bucket_name = "multitool_modes"
	elif kind == "ecologies":
		bucket_name = "ecologies"
	elif kind == "settlements":
		bucket_name = "settlements"
	elif kind == "buildings":
		bucket_name = "buildings"
	elif kind == "systems":
		bucket_name = "systems"
	elif kind == "planets":
		bucket_name = "planets"
	elif kind == "items":
		bucket_name = "items"
	elif kind == "recipes":
		bucket_name = "recipes"
	elif kind == "markets":
		bucket_name = "markets"
	elif kind == "quests":
		bucket_name = "quests"
	elif kind == "dialogues":
		bucket_name = "dialogues"
	else:
		errors.append("unknown content type '%s' in %s" % [kind, rel])
		return
	var bucket: Dictionary = _buckets.get(bucket_name, {})
	var content_id: String = str(record.get("content_id", ""))
	if content_id.is_empty():
		errors.append("record without content_id in " + rel)
		return
	if bucket.has(content_id):
		errors.append("duplicate content_id: " + content_id)
		return
	if _id_kind.has(content_id):
		errors.append("content_id reused across types: " + content_id)
		return
	bucket[content_id] = record
	_id_kind[content_id] = bucket_name

func _declares_resolved(kind: String, content_id: String) -> bool:
	var bucket_name: String = kind
	if kind == "flora" or kind == "fauna":
		bucket_name = "species"
	var bucket: Dictionary = _buckets.get(bucket_name, {})
	return bucket.has(content_id)

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_recipe(id: String) -> Dictionary:
	return recipes.get(id, {})

func get_species(id: String) -> Dictionary:
	return species.get(id, {})

func get_hull(id: String) -> Dictionary:
	return hulls.get(id, {})

func get_ship_module(id: String) -> Dictionary:
	return ship_modules.get(id, {})

func get_market(id: String) -> Dictionary:
	return markets.get(id, {})

func get_quest(id: String) -> Dictionary:
	return quests.get(id, {})

func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})

func get_building(id: String) -> Dictionary:
	return buildings.get(id, {})

func get_planet(id: String) -> Dictionary:
	return planets.get(id, {})

func get_system(id: String) -> Dictionary:
	return systems.get(id, {})

func get_settlement(id: String) -> Dictionary:
	return settlements.get(id, {})

func get_ecology(id: String) -> Dictionary:
	return ecologies.get(id, {})

func get_mode(id: String) -> Dictionary:
	return multitool_modes.get(id, {})

func has_record(kind: String, content_id: String) -> bool:
	return _id_kind.has(content_id)

func records_of(bucket_name: String) -> Dictionary:
	return _buckets.get(bucket_name, {})

func counts() -> Dictionary:
	var out: Dictionary = {}
	for key in _buckets.keys():
		out[key] = (_buckets[key] as Dictionary).size()
	return out

func pack_versions() -> Dictionary:
	var files: Dictionary = {}
	for path in _file_versions.keys():
		files[path] = _file_versions[path]
	return {"pack_id": pack_id, "content_version": content_version, "files": files}

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		errors.append("JSON parse error in %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("JSON root must be an object: " + path)
		return {}
	return parsed
