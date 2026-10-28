class_name BtvPixelSprites
extends RefCounted

## Runtime loader for authored PNG art. No sprite data lives in this file.
## The artist owns assets/art_src (editable sources) and assets/sprites (exports).
## Missing art returns a visible checker so gaps are obvious during development.

const ROOT := "res://assets/sprites/"
const MISSING := Color(1.0, 0.0, 1.0, 1.0)
const MISSING_DARK := Color(0.06, 0.06, 0.08, 1.0)

static var _cache: Dictionary = {}
static var _warned: Dictionary = {}

static func player_texture(direction: String, pose: String, frame: int) -> Texture2D:
	var key := "player/%s_%s_%d" % [direction, pose, frame]
	var texture := _load(key)
	if texture != null:
		return texture
	for fallback in [
		"player/%s_%s_0" % [direction, pose],
		"player/%s_idle_0" % direction,
		"player/down_idle_0",
	]:
		texture = _load(fallback)
		if texture != null:
			return texture
	return _missing(key)

static func prop_texture(name: String) -> Texture2D:
	var texture := _load("props/" + name)
	if texture != null:
		return texture
	return _missing("props/" + name)

static func ground_texture(biome: String, variant: int) -> Texture2D:
	for key in ["ground/%s_%d" % [biome, variant], "ground/%s_0" % biome, "ground/default_0"]:
		var texture := _load(key)
		if texture != null:
			return texture
	return _missing("ground/%s_%d" % [biome, variant])

static func water_texture(variant: int = 0) -> Texture2D:
	for key in ["water/%d" % variant, "water/0"]:
		var texture := _load(key)
		if texture != null:
			return texture
	return _missing("water/%d" % variant)

static func shadow_texture(width: int = 24, height: int = 10) -> Texture2D:
	var texture := _load("fx/shadow")
	if texture != null:
		return texture
	return _soft_shadow(width, height)

static func validate_maps() -> Array[String]:
	var errors: Array[String] = []
	for key in _warned.keys():
		errors.append("missing art: " + str(key))
	return errors

static func clear_cache() -> void:
	_cache.clear()
	_warned.clear()

static func _load(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := ROOT + key + ".png"
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		var resource := load(path)
		if resource is Texture2D:
			texture = resource
	_cache[key] = texture
	return texture

static func _missing(key: String) -> Texture2D:
	if not _warned.has(key):
		_warned[key] = true
		push_warning("BtvPixelSprites: missing art " + key)
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			image.set_pixel(x, y, MISSING if (x + y) % 2 == 0 else MISSING_DARK)
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

static func _soft_shadow(width: int, height: int) -> Texture2D:
	var w := maxi(4, width)
	var h := maxi(3, height)
	var cache_key := "fx/shadow_%d_%d" % [w, h]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var cx := (w - 1) * 0.5
	var cy := (h - 1) * 0.5
	for y in h:
		for x in w:
			var nx := (x - cx) / maxf(1.0, w * 0.5)
			var ny := (y - cy) / maxf(1.0, h * 0.5)
			var distance := sqrt(nx * nx + ny * ny)
			var alpha := clampf(1.0 - distance, 0.0, 1.0) * 0.55
			image.set_pixel(x, y, Color(0.0, 0.0, 0.0, alpha))
	var texture := ImageTexture.create_from_image(image)
	_cache[cache_key] = texture
	return texture
