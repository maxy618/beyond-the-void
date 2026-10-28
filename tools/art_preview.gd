extends SceneTree

## Renders every authored sprite to PNG contact sheets for visual review.

const Sprites = preload("res://scripts/world/pixel_sprites.gd")
const OUT := "res://build/reports/overhaul/art"

const BG := Color("#0b1418")
const CELL := Color("#16262c")

const PROP_ORDER := [
	"rock", "boulder", "crystal", "kelp", "fern", "bell", "moss",
	"grazer", "manta", "drone", "plate", "mast", "dish", "canopy",
	"counter", "engine", "reticle",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = Sprites.validate_maps()
	if errors.size() > 0:
		for error in errors:
			printerr("MAP_VALIDATE: " + error)
		printerr("MAP_VALIDATE FAILED: %d errors" % errors.size())
		quit(1)
		return
	var dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(dir)
	DirAccess.make_dir_recursive_absolute(dir.path_join("props"))
	DirAccess.make_dir_recursive_absolute(dir.path_join("player"))

	for name in PROP_ORDER:
		var image: Image = Sprites.prop_texture(name).get_image()
		_save_scaled(image, dir.path_join("props/%s.png" % name), 12)

	_prop_sheet(dir.path_join("props_contact.png"))
	_walk_sheet(dir.path_join("player_walk.png"))
	_pose_sheet(dir.path_join("player_poses.png"))
	print("ART_PREVIEW dir=%s" % dir)
	quit()

func _save_scaled(source: Image, path: String, scale: int) -> void:
	var image := source.duplicate() as Image
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
	image.save_png(path)

func _blit_centered(sheet: Image, source: Image, cx: int, cy: int, scale: int, pad: int = 6) -> void:
	var image := source.duplicate() as Image
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
	var x := cx - image.get_width() / 2
	var y := cy - image.get_height() / 2
	if x < pad or y < pad or x + image.get_width() > sheet.get_width() - pad or y + image.get_height() > sheet.get_height() - pad:
		return
	sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x, y))

func _frame(sheet: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px == x or py == y or px == x + w - 1 or py == y + h - 1:
				sheet.set_pixel(px, py, color)

func _prop_sheet(path: String) -> void:
	var cols := 4
	var cell_w := 190
	var cell_h := 170
	var rows := int(ceil(float(PROP_ORDER.size()) / float(cols)))
	var sheet := Image.create(cols * cell_w, rows * cell_h, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	for i in range(PROP_ORDER.size()):
		var col := i % cols
		var row := i / cols
		var x := col * cell_w
		var y := row * cell_h
		_frame(sheet, x, y, cell_w, cell_h, CELL)
		_blit_centered(sheet, Sprites.prop_texture(PROP_ORDER[i]).get_image(), x + cell_w / 2, y + cell_h / 2, 6)
	sheet.save_png(path)

func _walk_sheet(path: String) -> void:
	var dirs := ["down", "up", "left", "right"]
	var cell_w := 150
	var cell_h := 210
	var sheet := Image.create(4 * cell_w, 4 * cell_h, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	for row in range(dirs.size()):
		for col in range(4):
			var x := col * cell_w
			var y := row * cell_h
			_frame(sheet, x, y, cell_w, cell_h, CELL)
			_blit_centered(sheet, Sprites.player_texture(dirs[row], "walk", col).get_image(), x + cell_w / 2, y + cell_h / 2, 6)
	sheet.save_png(path)

func _pose_sheet(path: String) -> void:
	var dirs := ["down", "up", "left", "right"]
	var poses := ["idle", "jetpack", "mine"]
	var cell_w := 150
	var cell_h := 210
	var sheet := Image.create(poses.size() * cell_w, dirs.size() * cell_h, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	for row in range(dirs.size()):
		for col in range(poses.size()):
			var x := col * cell_w
			var y := row * cell_h
			_frame(sheet, x, y, cell_w, cell_h, CELL)
			_blit_centered(sheet, Sprites.player_texture(dirs[row], poses[col], 0).get_image(), x + cell_w / 2, y + cell_h / 2, 6)
	sheet.save_png(path)
