class_name BtvAudioSynth
extends RefCounted

## Procedural audio source bank. Every cue is synthesised from oscillators and
## filtered noise so the game ships with real sound before final recordings.
## Quality status is DRAFT: technical playback is verified, listening is human-gated.

const RATE := 22050
const MUSIC_BARS := 2

const MUSIC_STATES := {
	"TITLE":       {"root": 41, "scale": [0, 3, 5, 7, 10], "bpm": 50, "layers": ["pad", "pulse"], "bright": 0.32},
	"CRASH":       {"root": 33, "scale": [0, 1, 5, 6, 8], "bpm": 48, "layers": ["pad", "pulse"], "bright": 0.15},
	"SURVIVAL":    {"root": 41, "scale": [0, 2, 3, 7, 10], "bpm": 62, "layers": ["pad", "pulse"], "bright": 0.3},
	"EXPLORE_CALM":{"root": 48, "scale": [0, 2, 3, 7, 9], "bpm": 66, "layers": ["pad", "arp", "pulse"], "bright": 0.55},
	"DISCOVERY":   {"root": 50, "scale": [0, 2, 4, 7, 9], "bpm": 70, "layers": ["pad", "arp"], "bright": 0.8},
	"CRAFT":       {"root": 43, "scale": [0, 2, 5, 7, 10], "bpm": 72, "layers": ["pad", "pulse"], "bright": 0.45},
	"RELAY":       {"root": 46, "scale": [0, 3, 5, 7, 10], "bpm": 64, "layers": ["pad", "arp"], "bright": 0.7},
	"TAKEOFF":     {"root": 38, "scale": [0, 2, 3, 7, 10], "bpm": 84, "layers": ["pad", "pulse", "arp"], "bright": 0.6},
	"SPACE":       {"root": 40, "scale": [0, 3, 7, 10, 14], "bpm": 54, "layers": ["pad", "arp"], "bright": 0.4},
	"APPROACH":    {"root": 44, "scale": [0, 2, 3, 7, 9], "bpm": 58, "layers": ["pad", "pulse"], "bright": 0.5},
	"ENTRY":       {"root": 36, "scale": [0, 1, 3, 6, 8], "bpm": 88, "layers": ["pad", "pulse"], "bright": 0.25},
	"LANDING":     {"root": 41, "scale": [0, 2, 5, 7, 9], "bpm": 60, "layers": ["pad"], "bright": 0.35},
	"COMBAT":      {"root": 34, "scale": [0, 1, 3, 6, 10], "bpm": 116, "layers": ["pulse", "arp"], "bright": 0.55},
	"DANGER":      {"root": 31, "scale": [0, 1, 4, 6, 8], "bpm": 96, "layers": ["pulse", "pad"], "bright": 0.2},
	"BLACK_HOLE":  {"root": 28, "scale": [0, 1, 5, 6, 11], "bpm": 42, "layers": ["pad", "arp"], "bright": 0.3},
	"SETTLEMENT":  {"root": 47, "scale": [0, 2, 4, 7, 11], "bpm": 68, "layers": ["pad", "arp"], "bright": 0.65},
	"REVELATION":  {"root": 43, "scale": [0, 3, 5, 8, 10], "bpm": 52, "layers": ["pad", "arp"], "bright": 0.9},
	"PAUSE":       {"root": 45, "scale": [0, 2, 3, 7, 10], "bpm": 50, "layers": ["pad"], "bright": 0.25}
}

# ---------------------------------------------------------------- public API

static func cue(id: String) -> AudioStreamWAV:
	match id:
		"ui.click": return _click(-9.0)
		"ui.hover": return _tone(1320.0, 0.035, 0.16, 14.0)
		"ui.back": return _two_tone(520.0, 380.0, 0.07, 0.2)
		"ui.error": return _buzz(150.0, 0.18, 0.26)
		"ui.open": return _two_tone(440.0, 660.0, 0.09, 0.2)
		"ui.close": return _two_tone(660.0, 440.0, 0.09, 0.2)
		"ui.saveload": return _chime([392.0, 587.0, 784.0], 0.5, 0.22)
		"step.grass": return _step(1500.0, 0.085, 0.30, 0.16)
		"step.stone": return _step(3200.0, 0.065, 0.34, 0.1)
		"step.sand": return _step(800.0, 0.11, 0.26, 0.2)
		"step.water": return _splash()
		"step.metal": return _metal_step()
		"sprint.step": return _step(2400.0, 0.07, 0.42, 0.08)
		"land": return _impact(0.18, 0.55)
		"exhausted": return _buzz(220.0, 0.22, 0.2)
		"jetpack.ignite": return _ignite()
		"jetpack.loop": return _thrust_loop(0.9, 620.0, 0.30)
		"jetpack.empty": return _empty_jet()
		"jetpack.land": return _impact(0.12, 0.4)
		"tool.switch": return _two_tone(760.0, 980.0, 0.05, 0.18)
		"scan.charge": return _charge()
		"scan.pulse": return _ping(1180.0, 0.35, 0.22)
		"scan.success": return _chime([784.0, 1046.0, 1318.0], 0.4, 0.2)
		"scan.fail": return _sweep(400.0, 180.0, 0.22, 0.2)
		"gather": return _gather()
		"mining.loop": return _mining_loop()
		"depleted": return _buzz(190.0, 0.2, 0.16)
		"craft": return _chime([330.0, 494.0, 659.0], 0.6, 0.24)
		"craft.fail": return _buzz(140.0, 0.3, 0.2)
		"pickup": return _two_tone(880.0, 1320.0, 0.09, 0.16)
		"coin": return _chime([1318.0, 1760.0], 0.18, 0.14)
		"hit": return _hit(0.16, 0.5)
		"hit.shield": return _shield()
		"shot.laser": return _laser()
		"explosion": return _explosion()
		"death": return _death()
		"warn": return _sweep(680.0, 420.0, 0.3, 0.24)
		"dialogue.blip": return _tone(620.0, 0.045, 0.10, 22.0)
		"dialogue.open": return _two_tone(520.0, 700.0, 0.14, 0.16)
		"ship.ignite": return _ship_ignite()
		"ship.thrust": return _thrust_loop(1.1, 340.0, 0.34)
		"ship.brake": return _sweep(900.0, 300.0, 0.45, 0.22)
		"ship.takeoff": return _ship_takeoff()
		"ship.land": return _ship_land()
		"entry.rumble": return _entry_loop()
		"ship.warn": return _alarm()
		"amb.wind": return ambience("amb.wind")
		"amb.water": return ambience("amb.water")
		"amb.crystal": return ambience("amb.crystal")
		"amb.spore": return ambience("amb.spore")
		"amb.settlement": return ambience("amb.settlement")
		"amb.space": return ambience("amb.space")
		"amb.blackhole": return ambience("amb.blackhole")
		"weather.rain": return ambience("weather.rain")
		"weather.sand": return ambience("weather.sand")
	return null

static func ambience(id: String) -> AudioStreamWAV:
	match id:
		"amb.wind":
			return _wind_loop()
		"amb.water":
			return _water_loop()
		"amb.crystal":
			return _crystal_loop()
		"amb.spore":
			return _spore_loop()
		"amb.settlement":
			return _settlement_loop()
		"amb.space":
			return _space_loop()
		"amb.blackhole":
			return _blackhole_loop()
		"weather.rain":
			return _rain_loop()
		"weather.sand":
			return _sand_loop()
	return null

static func music_layer(state: String, layer: String) -> AudioStreamWAV:
	var spec: Dictionary = MUSIC_STATES.get(state, MUSIC_STATES["EXPLORE_CALM"])
	if not (layer in spec["layers"]):
		return null
	var beat := 60.0 / float(spec["bpm"])
	var bar := beat * 4.0
	var seconds := bar * MUSIC_BARS
	var count := int(RATE * seconds)
	var data := _buf(count)
	var root: int = spec["root"]
	var scale: Array = spec["scale"]
	var bright: float = spec["bright"]
	match layer:
		"pad":
			_pad_layer(data, root, scale, seconds, bright)
		"pulse":
			_pulse_layer(data, beat, bright)
		"arp":
			_arp_layer(data, root, scale, scale.size() * 2, beat, bright)
	_loopify(data, 0.03)
	if layer == "pad":
		_normalize(data, 0.55)
	_normalize(data, 0.62)
	return _wav(data, true)

# ---------------------------------------------------------------- tool kit

static func _buf(count: int) -> PackedFloat32Array:
	var data := PackedFloat32Array()
	data.resize(count)
	return data

static func _wav(data: PackedFloat32Array, looped: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for index in data.size():
		bytes.encode_s16(index * 2, int(clampf(data[index], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = data.size()
	return stream

static func _normalize(data: PackedFloat32Array, peak: float) -> void:
	var top := 0.0001
	for value in data:
		top = maxf(top, absf(value))
	var gain := peak / top
	for index in data.size():
		data[index] *= gain

static func _loopify(data: PackedFloat32Array, fade_seconds: float) -> void:
	var fade := mini(int(RATE * fade_seconds), data.size() / 4)
	var size := data.size()
	for index in fade:
		var k := float(index) / float(fade)
		data[index] = data[index] * k + data[size - fade + index] * (1.0 - k)

static func _noise(count: int, seed_value: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var data := _buf(count)
	for index in count:
		data[index] = rng.randf_range(-1.0, 1.0)
	return data

static func _lowpass(data: PackedFloat32Array, cutoff: float) -> void:
	var alpha := clampf(1.0 - exp(-TAU * cutoff / RATE), 0.001, 1.0)
	var last := 0.0
	for index in data.size():
		last += alpha * (data[index] - last)
		data[index] = last

static func _highpass(data: PackedFloat32Array, cutoff: float) -> void:
	var alpha := clampf(1.0 - exp(-TAU * cutoff / RATE), 0.001, 1.0)
	var last_in := 0.0
	var last_out := 0.0
	for index in data.size():
		last_out = alpha * (last_out + data[index] - last_in)
		last_in = data[index]
		data[index] = last_out

static func _tone(freq: float, duration: float, gain: float, decay: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var env := exp(-t * decay * 4.0)
		data[index] = sin(TAU * freq * t) * env * gain
	return _wav(data)

static func _two_tone(first: float, second: float, duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _buf(count)
	var half := count / 2
	for index in count:
		var t := float(index) / RATE
		var freq := first if index < half else second
		var env := exp(-fmod(float(index), float(half)) / float(half) * 3.2)
		data[index] = sin(TAU * freq * t) * env * gain
	return _wav(data)

static func _chime(freqs: Array, duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var value := 0.0
		for slot in freqs.size():
			var start := t - float(slot) * duration * 0.18
			if start < 0.0:
				continue
			value += sin(TAU * float(freqs[slot]) * t) * exp(-start * 7.0)
		data[index] = value / maxf(1.0, float(freqs.size()) * 0.6) * gain
	return _wav(data)

static func _click(gain: float) -> AudioStreamWAV:
	var count := int(RATE * 0.03)
	var data := _buf(count)
	for index in count:
		var k := float(index) / float(count)
		var sq := 1.0 if sin(TAU * 1400.0 * float(index) / RATE) > 0.0 else -1.0
		data[index] = sq * exp(-k * 9.0) * gain * 0.4
	return _wav(data)

static func _buzz(freq: float, duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var k := float(index) / float(count)
		var value := sin(TAU * freq * t) + 0.4 * sin(TAU * freq * 2.7 * t)
		data[index] = value * sin(PI * k) * gain * 0.5
	return _wav(data)

static func _sweep(from: float, to: float, duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(from, to, k) / RATE
		data[index] = sin(phase) * sin(PI * k) * gain
	return _wav(data)

static func _impact(duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var noise := _noise(count, 0x41A7)
	_lowpass(noise, 900.0)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(120.0, 42.0, k) / RATE
		var body := sin(phase) * exp(-k * 7.0)
		data[index] = (body + noise[index] * 0.5 * exp(-k * 9.0)) * gain
	return _wav(data)

static func _step(cutoff: float, duration: float, gain: float, smooth: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _noise(count, int(cutoff) + 17)
	_lowpass(data, cutoff)
	var last := 0.0
	for index in count:
		var k := float(index) / float(count)
		last = lerpf(data[index], last, smooth)
		data[index] = last * exp(-k * 8.0) * gain
	return _wav(data)

static func _splash() -> AudioStreamWAV:
	var count := int(RATE * 0.16)
	var data := _noise(count, 0x9911)
	_highpass(data, 700.0)
	_lowpass(data, 4200.0)
	for index in count:
		var k := float(index) / float(count)
		data[index] = data[index] * (1.0 - k) * 0.35 + sin(TAU * (500.0 + 900.0 * k) * float(index) / RATE) * exp(-k * 6.0) * 0.12
	return _wav(data)

static func _metal_step() -> AudioStreamWAV:
	var count := int(RATE * 0.14)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var env := exp(-t * 28.0)
		data[index] = (sin(TAU * 1760.0 * t) * 0.5 + sin(TAU * 2630.0 * t) * 0.3) * env * 0.28
	return _wav(data)

static func _mining_loop() -> AudioStreamWAV:
	var duration := 0.6
	var count := int(RATE * duration)
	var data := _noise(count, 0x4D11)
	_lowpass(data, 1500.0)
	_highpass(data, 180.0)
	for index in count:
		var t := float(index) / RATE
		var pulse := exp(-fmod(t, 0.15) * 26.0)
		var phase := TAU * lerpf(190.0, 120.0, t / duration) * t
		data[index] = data[index] * 0.22 * pulse + sin(phase) * 0.12 * pulse
	_loopify(data, 0.03)
	return _wav(data, true)

static func _gather() -> AudioStreamWAV:
	var count := int(RATE * 0.26)
	var data := _noise(count, 0x77AB)
	_lowpass(data, 1900.0)
	for index in count:
		var k := float(index) / float(count)
		var tick := sin(TAU * 900.0 * float(index) / RATE) * exp(-k * 12.0)
		data[index] = data[index] * 0.2 * exp(-k * 4.0) + tick * 0.18
	return _wav(data)

static func _hit(duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var noise := _noise(count, 0x1357)
	_lowpass(noise, 1600.0)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(180.0, 70.0, k) / RATE
		data[index] = (sin(phase) * exp(-k * 8.0) + noise[index] * exp(-k * 12.0) * 0.6) * gain
	return _wav(data)

static func _shield() -> AudioStreamWAV:
	var count := int(RATE * 0.32)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var env := exp(-t * 9.0)
		data[index] = (sin(TAU * 880.0 * t) * 0.3 + sin(TAU * 1320.0 * t) * 0.2 + sin(TAU * 2210.0 * t) * 0.1) * env
	return _wav(data)

static func _laser() -> AudioStreamWAV:
	var count := int(RATE * 0.18)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(1600.0, 280.0, k) / RATE
		var sq := 1.0 if sin(phase) > 0.0 else -1.0
		data[index] = sq * exp(-k * 6.0) * 0.22
	return _wav(data)

static func _explosion() -> AudioStreamWAV:
	var count := int(RATE * 0.9)
	var data := _noise(count, 0x2BAD)
	_lowpass(data, 700.0)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(90.0, 30.0, k) / RATE
		data[index] = data[index] * exp(-k * 4.0) * 0.6 + sin(phase) * exp(-k * 6.0) * 0.5
	return _wav(data)

static func _death() -> AudioStreamWAV:
	var count := int(RATE * 1.1)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(340.0, 60.0, k) / RATE
		data[index] = sin(phase) * exp(-k * 3.0) * 0.3
	return _wav(data)

static func _charge() -> AudioStreamWAV:
	var count := int(RATE * 0.5)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(240.0, 1100.0, k) / RATE
		var trem := 0.65 + 0.35 * sin(TAU * 26.0 * float(index) / RATE)
		data[index] = sin(phase) * trem * sin(PI * k) * 0.22
	return _wav(data)

static func _ping(freq: float, duration: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _buf(count)
	var delay := int(RATE * 0.09)
	for index in count:
		var t := float(index) / RATE
		var value := sin(TAU * freq * t) * exp(-t * 11.0)
		if index >= delay:
			var t2 := float(index - delay) / RATE
			value += sin(TAU * freq * t2) * exp(-t2 * 9.0) * 0.35
		data[index] = value * gain
	return _wav(data)

static func _ignite() -> AudioStreamWAV:
	var count := int(RATE * 0.5)
	var data := _noise(count, 0x5A11)
	_highpass(data, 250.0)
	_lowpass(data, 2400.0)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(70.0, 140.0, k) / RATE
		data[index] = data[index] * sin(PI * k) * 0.25 + sin(phase) * exp(-k * 3.0) * 0.35
	return _wav(data)

static func _thrust_loop(duration: float, cutoff: float, gain: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var data := _noise(count, 0x75C0)
	_lowpass(data, cutoff)
	_highpass(data, 60.0)
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		phase += TAU * 52.0 / RATE
		var flutter := 0.85 + 0.15 * sin(TAU * 7.0 * t)
		data[index] = (data[index] * 0.8 + sin(phase) * 0.25) * flutter * gain
	_loopify(data, 0.05)
	return _wav(data, true)

static func _empty_jet() -> AudioStreamWAV:
	var count := int(RATE * 0.4)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(420.0, 90.0, k) / RATE
		var gate := 1.0 if fmod(float(index) / RATE, 0.09) < 0.05 else 0.25
		data[index] = sin(phase) * gate * exp(-k * 2.0) * 0.2
	return _wav(data)

static func _ship_ignite() -> AudioStreamWAV:
	var count := int(RATE * 1.2)
	var data := _noise(count, 0x6A11)
	_lowpass(data, 500.0)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(36.0, 64.0, k) / RATE
		data[index] = data[index] * sin(PI * k) * 0.3 + sin(phase) * sin(PI * k) * 0.4
	return _wav(data)

static func _ship_takeoff() -> AudioStreamWAV:
	var count := int(RATE * 1.4)
	var data := _noise(count, 0x3C0A)
	_lowpass(data, 800.0)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(30.0, 110.0, k * k) / RATE
		data[index] = data[index] * 0.25 + sin(phase) * 0.45 * pow(k, 0.5)
	return _wav(data)

static func _ship_land() -> AudioStreamWAV:
	var count := int(RATE * 0.8)
	var data := _noise(count, 0x1200)
	_lowpass(data, 420.0)
	var phase := 0.0
	for index in count:
		var k := float(index) / float(count)
		phase += TAU * lerpf(90.0, 32.0, k) / RATE
		data[index] = (data[index] * 0.4 + sin(phase) * 0.5) * exp(-k * 4.0)
	return _wav(data)

static func _entry_loop() -> AudioStreamWAV:
	var count := int(RATE * 1.2)
	var data := _noise(count, 0x9A10)
	_lowpass(data, 650.0)
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		phase += TAU * 44.0 / RATE
		var flutter := 0.75 + 0.25 * sin(TAU * 5.5 * t)
		data[index] = (data[index] * 0.85 + sin(phase) * 0.35) * flutter * 0.4
	_loopify(data, 0.05)
	return _wav(data, true)

static func _alarm() -> AudioStreamWAV:
	var count := int(RATE * 0.6)
	var data := _buf(count)
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		var gate := 1.0 if fmod(t, 0.3) < 0.2 else 0.0
		phase += TAU * 760.0 / RATE
		data[index] = sin(phase) * gate * 0.18
	return _wav(data)

# ---------------------------------------------------------------- ambience

static func _wind_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _noise(count, 0x3111)
	_lowpass(data, 520.0)
	var phase := 0.0
	for index in count:
		var t := float(index) / RATE
		phase += TAU * 0.13 / RATE
		var gust := 0.45 + 0.55 * (0.5 + 0.5 * sin(phase * 3.0))
		data[index] = data[index] * gust * 0.55 + sin(TAU * 58.0 * t) * 0.05
	_loopify(data, 0.25)
	return _wav(data, true)

static func _water_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _noise(count, 0x4222)
	_lowpass(data, 1500.0)
	_highpass(data, 300.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5150
	var bubbles := _buf(count)
	for index in count:
		data[index] *= 0.22
	var next := int(RATE * 0.25)
	while next < count:
		var start := next
		var freq := rng.randf_range(420.0, 980.0)
		for index in range(start, mini(start + int(RATE * 0.08), count)):
			var t := float(index - start) / RATE
			bubbles[index] += sin(TAU * freq * t) * exp(-t * 40.0) * 0.10
		next += int(RATE * rng.randf_range(0.18, 0.4))
	for index in count:
		data[index] += bubbles[index]
	_loopify(data, 0.2)
	return _wav(data, true)

static func _crystal_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var shimmer := 0.5 + 0.5 * sin(TAU * 0.17 * t)
		data[index] = (sin(TAU * 528.0 * t) * 0.05 + sin(TAU * 792.0 * t) * 0.035 + sin(TAU * 1056.0 * t) * 0.02) * shimmer
	_loopify(data, 0.2)
	return _wav(data, true)

static func _spore_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _noise(count, 0x6100)
	_lowpass(data, 320.0)
	for index in count:
		var t := float(index) / RATE
		data[index] = data[index] * 0.3 + sin(TAU * 41.0 * t) * 0.04
	_loopify(data, 0.25)
	return _wav(data, true)

static func _settlement_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _noise(count, 0x7200)
	_lowpass(data, 900.0)
	for index in count:
		var t := float(index) / RATE
		data[index] = data[index] * 0.12 + sin(TAU * 50.0 * t) * 0.03 + sin(TAU * 100.0 * t) * 0.015
	_loopify(data, 0.2)
	return _wav(data, true)

static func _space_loop() -> AudioStreamWAV:
	var duration := 6.0
	var count := int(RATE * duration)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var drift := 0.6 + 0.4 * sin(TAU * 0.09 * t)
		data[index] = (sin(TAU * 36.0 * t) * 0.10 + sin(TAU * 54.0 * t) * 0.05 + sin(TAU * 81.0 * t) * 0.025) * drift
	_loopify(data, 0.3)
	return _wav(data, true)

static func _blackhole_loop() -> AudioStreamWAV:
	var duration := 6.0
	var count := int(RATE * duration)
	var data := _buf(count)
	for index in count:
		var t := float(index) / RATE
		var swell := 0.55 + 0.45 * sin(TAU * 0.07 * t)
		data[index] = (sin(TAU * 24.0 * t) * 0.14 + sin(TAU * 36.0 * t) * 0.04) * swell + sin(TAU * 720.0 * t) * 0.004
	_loopify(data, 0.3)
	return _wav(data, true)

static func _rain_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _noise(count, 0x8300)
	_highpass(data, 900.0)
	_lowpass(data, 5200.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x6161
	var next := 0
	while next < count:
		var start := next
		for index in range(start, mini(start + int(RATE * 0.02), count)):
			var t := float(index - start) / RATE
			data[index] += sin(TAU * rng.randf_range(1200.0, 2600.0) * t) * exp(-t * 80.0) * 0.05
		next += int(RATE * rng.randf_range(0.03, 0.09))
	for index in count:
		data[index] *= 0.28
	_loopify(data, 0.15)
	return _wav(data, true)

static func _sand_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var data := _noise(count, 0x9400)
	_highpass(data, 400.0)
	_lowpass(data, 2200.0)
	for index in count:
		var t := float(index) / RATE
		var gust := 0.5 + 0.5 * sin(TAU * 0.11 * t + sin(TAU * 0.037 * t) * 2.0)
		data[index] *= 0.3 * (0.35 + 0.65 * gust)
	_loopify(data, 0.2)
	return _wav(data, true)

# ---------------------------------------------------------------- music

static func _pad_layer(data: PackedFloat32Array, root: int, scale: Array, seconds: float, bright: float) -> void:
	var chord := [0, 3, 4]
	var count := data.size()
	for index in count:
		var t := float(index) / RATE
		var value := 0.0
		for slot in chord.size():
			var degree: int = scale[chord[slot] % scale.size()]
			var freq := _midi(root + degree + (12 if slot == 2 else 0))
			var detune := 1.0 + 0.0015 * sin(TAU * (0.07 + 0.02 * slot) * t)
			value += sin(TAU * freq * detune * t) * (0.34 - 0.05 * slot)
			value += sin(TAU * freq * 2.0 * t) * 0.05 * bright
		var swell := 0.55 + 0.45 * sin(TAU * 0.055 * t)
		data[index] = value * swell * 0.3

static func _pulse_layer(data: PackedFloat32Array, beat: float, bright: float) -> void:
	var count := data.size()
	var step := beat * 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xB7E4
	var index := 0
	while index < count:
		var start := index
		var accent := 1.0 if int(round(float(start) / RATE / step)) % 4 == 0 else 0.6
		var phase := 0.0
		for offset in mini(int(RATE * 0.18), count - start):
			var t := float(offset) / RATE
			phase += TAU * lerpf(70.0, 40.0, t / 0.18) / RATE
			var env := exp(-t * 22.0)
			var noise := rng.randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.08 * bright
			data[start + offset] += (sin(phase) * 0.32 + noise) * env * accent
		index = start + int(RATE * step)

static func _arp_layer(data: PackedFloat32Array, root: int, scale: Array, steps: int, beat: float, bright: float) -> void:
	var count := data.size()
	var step := beat * 0.5
	var pattern := [0, 2, 1, 3, 2, 4, 3, 1]
	var index := 0
	var note := 0
	while index < count:
		var start := index
		var degree: int = scale[pattern[note % pattern.size()] % scale.size()]
		var octave := 12 if (note % 8) >= 5 else 0
		var freq := _midi(root + 12 + degree + octave)
		for offset in mini(int(RATE * 0.4), count - start):
			var t := float(offset) / RATE
			var env := exp(-t * 7.0)
			var wave := sin(TAU * freq * t) + 0.2 * sin(TAU * freq * 2.0 * t)
			data[start + offset] += wave * env * 0.10 * (0.6 + 0.4 * bright)
		index = start + int(RATE * step)
		note += 1

static func _midi(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)
