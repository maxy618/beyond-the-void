class_name BtvAudio
extends Node

## Bus graph, event registry, voice pools, positional emitters, loops and ducking.
## Cue material is synthesised by BtvAudioSynth (DRAFT quality, human listening gated).

const EVENTS_PATH := "res://content/audio/events.json"
const BUSES: Array[String] = ["Music", "SFX", "Ambience", "Dialogue", "UI", "Ship", "Combat"]
const VOICES_PER_BUS := 10
const POSITIONAL_VOICES := 16
const MAX_DISTANCE := 520.0

var events: Dictionary = {}
var bus_defaults: Dictionary = {}
var music: BtvMusicDirector

var _pools: Dictionary = {}
var _busy: Dictionary = {}
var _started: Dictionary = {}
var _last_played: Dictionary = {}
var _loops: Dictionary = {}
var _cache: Dictionary = {}
var _volumes: Dictionary = {}
var _muted: Dictionary = {}
var _now := 0.0
var _positional := 0
var _ducked: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_load_registry()
	music = BtvMusicDirector.new()
	music.name = "MusicDirector"
	add_child(music)
	apply_settings({})

func _process(delta: float) -> void:
	_now += delta

func _load_registry() -> void:
	var file := FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if file == null:
		push_warning("BtvAudio: missing " + EVENTS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("BtvAudio: registry is not an object")
		return
	events = parsed.get("events", {})
	bus_defaults = parsed.get("buses", {})

func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")

# ---------------------------------------------------------------- settings

func apply_settings(settings: Dictionary) -> void:
	for bus_name in BUSES:
		var key := "vol_" + bus_name.to_lower()
		var default_value: float = float(bus_defaults.get(bus_name, {}).get("default", 0.8))
		var value := clampf(float(settings.get(key, default_value)), 0.0, 1.0)
		var muted := bool(settings.get("mute_" + bus_name.to_lower(), false))
		_volumes[bus_name] = value
		_muted[bus_name] = muted
		_apply_bus(bus_name)
	music.set_enabled(bool(settings.get("music_enabled", true)))

func _apply_bus(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var value: float = float(_volumes.get(bus_name, 0.8))
	var muted: bool = bool(_muted.get(bus_name, false))
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(value, 0.0001, 1.0)))
	AudioServer.set_bus_mute(index, muted or value <= 0.001)

func set_bus_linear(bus_name: String, value: float) -> void:
	_volumes[bus_name] = clampf(value, 0.0, 1.0)
	_muted[bus_name] = value <= 0.001
	_apply_bus(bus_name)

func bus_linear(bus_name: String) -> float:
	return float(_volumes.get(bus_name, 0.8))

# ---------------------------------------------------------------- playback

func play(id: String, volume_db: float = 0.0, pitch: float = 1.0, bus_override: String = "") -> bool:
	var meta: Dictionary = events.get(id, {})
	if meta.is_empty():
		return false
	if _on_cooldown(id, meta):
		return false
	var bus_name := bus_override if not bus_override.is_empty() else str(meta.get("bus", "SFX"))
	if not _has_capacity(id, int(meta.get("max_instances", 3))):
		return false
	var stream := _stream(id)
	if stream == null:
		return false
	var player := _take_voice(bus_name, int(meta.get("priority", 5)), id)
	if player == null:
		return false
	var jitter := float(meta.get("pitch_jitter", 0.0))
	var final_pitch := pitch * (1.0 + randf_range(-jitter, jitter))
	player.stream = stream
	player.bus = bus_name
	player.volume_db = float(meta.get("gain_db", 0.0)) + volume_db
	player.pitch_scale = clampf(final_pitch, 0.2, 3.0)
	player.play()
	_mark_started(id)
	return true

func play_at(id: String, world_position: Vector2, parent: Node2D, volume_db: float = 0.0) -> bool:
	var meta: Dictionary = events.get(id, {})
	if meta.is_empty():
		return false
	if _on_cooldown(id, meta) or not _has_capacity(id, int(meta.get("max_instances", 3))):
		return false
	if parent == null or not is_instance_valid(parent):
		return false
	var stream := _stream(id)
	if stream == null:
		return false
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = str(meta.get("bus", "SFX"))
	player.volume_db = float(meta.get("gain_db", 0.0)) + volume_db
	player.max_distance = MAX_DISTANCE
	player.attenuation = 1.4
	player.global_position = world_position
	parent.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	_mark_started(id)
	_positional += 1
	return true

func start_loop(id: String, fade: float = 0.35, bus_override: String = "") -> void:
	if _loops.has(id):
		return
	var meta: Dictionary = events.get(id, {})
	var stream := _stream(id)
	if stream == null:
		return
	var bus_name := bus_override if not bus_override.is_empty() else str(meta.get("bus", "SFX"))
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	player.volume_db = -60.0
	add_child(player)
	player.play()
	var target := float(meta.get("gain_db", -8.0))
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target, fade)
	_loops[id] = player

func stop_loop(id: String, fade: float = 0.3) -> void:
	if not _loops.has(id):
		return
	var player: AudioStreamPlayer = _loops[id]
	_loops.erase(id)
	if not is_instance_valid(player):
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -60.0, fade)
	tween.tween_callback(player.queue_free)

func loop_active(id: String) -> bool:
	return _loops.has(id)

func stop_all(fade: float = 0.2) -> void:
	for id in _loops.keys():
		stop_loop(str(id), fade)
	for bus_name in _pools.keys():
		for player in _pools[bus_name]:
			if player.playing:
				player.stop()
	_busy.clear()
	_started.clear()
	if music != null:
		music.stop_all(fade)

func duck(bus_name: String, amount_db: float, duration: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	if _ducked.has(bus_name):
		_ducked[bus_name].kill()
	var base := linear_to_db(clampf(float(_volumes.get(bus_name, 0.8)), 0.0001, 1.0))
	AudioServer.set_bus_volume_db(index, base + amount_db)
	var tween := create_tween()
	tween.tween_interval(maxf(0.05, duration))
	tween.tween_callback(func() -> void:
		AudioServer.set_bus_volume_db(index, base)
		_ducked.erase(bus_name))
	_ducked[bus_name] = tween

func active_voice_count() -> int:
	var total := 0
	for bus_name in _busy.keys():
		total += _busy[bus_name].size()
	return total

func active_loop_ids() -> Array:
	return _loops.keys()

# ---------------------------------------------------------------- internals

func _stream(id: String) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var stream := BtvAudioSynth.cue(id)
	if stream != null:
		_cache[id] = stream
	return stream

func _on_cooldown(id: String, meta: Dictionary) -> bool:
	var cooldown := float(meta.get("cooldown", 0.0))
	if cooldown <= 0.0:
		return false
	var last: float = float(_last_played.get(id, -100.0))
	return _now - last < cooldown

func _has_capacity(id: String, cap: int) -> bool:
	var list: Array = _started.get(id, [])
	var living: Array = []
	for started in list:
		if _now - float(started) < 2.5:
			living.append(started)
	_started[id] = living
	return cap <= 0 or living.size() < cap

func _mark_started(id: String) -> void:
	var list: Array = _started.get(id, [])
	list.append(_now)
	_started[id] = list
	_last_played[id] = _now

func _take_voice(bus_name: String, priority: int, id: String) -> AudioStreamPlayer:
	if not _pools.has(bus_name):
		_pools[bus_name] = []
		_busy[bus_name] = {}
	var pool: Array = _pools[bus_name]
	if pool.size() < VOICES_PER_BUS:
		var player := AudioStreamPlayer.new()
		player.name = bus_name + "_" + str(pool.size())
		player.bus = bus_name
		player.finished.connect(_release.bind(bus_name, player))
		add_child(player)
		pool.append(player)
	for player in pool:
		if not _busy[bus_name].has(player):
			_busy[bus_name][player] = {"id": id, "priority": priority, "started": _now}
			return player
	var victim: AudioStreamPlayer = null
	var victim_priority := 999
	var oldest := -1.0
	for player in _busy[bus_name].keys():
		var entry: Dictionary = _busy[bus_name][player]
		var entry_priority := int(entry["priority"])
		if entry_priority < victim_priority or (entry_priority == victim_priority and float(entry["started"]) < oldest):
			victim = player
			victim_priority = entry_priority
			oldest = float(entry["started"])
	if victim == null or victim_priority >= priority:
		return null
	victim.stop()
	_busy[bus_name][victim] = {"id": id, "priority": priority, "started": _now}
	return victim

func _release(bus_name: String, player: AudioStreamPlayer) -> void:
	if _busy.has(bus_name):
		_busy[bus_name].erase(player)
