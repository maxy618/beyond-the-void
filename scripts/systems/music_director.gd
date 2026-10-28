class_name BtvMusicDirector
extends Node

## State-driven music. Layers are synthesised loops, switched on bar boundaries
## with short crossfades. Combat/danger states outrank exploration states.

signal state_changed(state: String)

const PRIORITY := {
	"PAUSE": 100,
	"CRASH": 90,
	"ENTRY": 80,
	"DANGER": 70,
	"COMBAT": 65,
	"BLACK_HOLE": 60,
	"REVELATION": 55,
	"TAKEOFF": 50,
	"LANDING": 45,
	"DISCOVERY": 40,
	"RELAY": 35,
	"APPROACH": 30,
	"SPACE": 25,
	"SETTLEMENT": 22,
	"CRAFT": 20,
	"SURVIVAL": 18,
	"EXPLORE_CALM": 15,
	"TITLE": 50
}
const FADE := 0.6
const SILENT_DB := -60.0

var state := ""
var _pending := ""
var _bar_clock := 0.0
var _bar_length := 4.0
var _players: Dictionary = {}
var _cache: Dictionary = {}
var _enabled := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_state(next: String) -> void:
	if next == state or next == _pending:
		return
	if not BtvAudioSynth.MUSIC_STATES.has(next):
		return
	if state != "" and not _outranks(next, state):
		return
	_pending = next

func force_state(next: String) -> void:
	if not BtvAudioSynth.MUSIC_STATES.has(next):
		return
	_pending = next
	if state == "":
		_apply(next)

func current_state() -> String:
	return state

func _outranks(candidate: String, current: String) -> bool:
	return int(PRIORITY.get(candidate, 0)) >= int(PRIORITY.get(current, 0))

func _process(delta: float) -> void:
	if not _enabled:
		return
	if _pending.is_empty():
		_bar_clock += delta
		return
	if state == "":
		_apply(_pending)
		return
	_bar_clock += delta
	if _bar_clock >= _bar_length * 0.5:
		_apply(_pending)

func _apply(next: String) -> void:
	var previous := state
	state = next
	_pending = ""
	var spec: Dictionary = BtvAudioSynth.MUSIC_STATES[next]
	_bar_length = 4.0 * 60.0 / float(spec["bpm"])
	_bar_clock = 0.0
	var layers: Array = spec["layers"]
	for layer in layers:
		var stream := _stream(next, str(layer))
		if stream == null:
			continue
		var player: AudioStreamPlayer = _players.get(layer)
		if player == null:
			player = AudioStreamPlayer.new()
			player.name = "Layer_" + str(layer)
			player.bus = "Music"
			player.volume_db = SILENT_DB
			add_child(player)
			_players[layer] = player
		player.stream = stream
		player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", 0.0, FADE)
	for layer in _players.keys():
		if layer in layers:
			continue
		var stale: AudioStreamPlayer = _players[layer]
		var fade := create_tween()
		fade.tween_property(stale, "volume_db", SILENT_DB, FADE)
		fade.tween_callback(stale.stop)
	if previous != next:
		state_changed.emit(next)

func _stream(next: String, layer: String) -> AudioStream:
	var key := next + "/" + layer
	if _cache.has(key):
		return _cache[key]
	var stream := BtvAudioSynth.music_layer(next, layer)
	if stream != null:
		_cache[key] = stream
	return stream

func stop_all(fade: float = 0.4) -> void:
	for player in _players.values():
		var tween := create_tween()
		tween.tween_property(player, "volume_db", SILENT_DB, fade)
		tween.tween_callback(player.stop)
	state = ""
	_pending = ""

func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		stop_all(0.2)
