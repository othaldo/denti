extends SceneTree

# Art preparation only: the large source sheet is never loaded in combat.
const SOURCE := "res://assets/loot/drop_art_source.png"
const OUTPUTS := ["res://assets/loot/xp_crystal.png", "res://assets/loot/gold_tooth_coin.png"]
const HEIGHTS := [36, 38] # 18 / 19 px in game, with the existing 2x texture scale.

func _initialize() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Missing generated loot artwork")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	for index in 2:
		var cell := source.get_region(Rect2i(index * source.get_width() / 2, 0, source.get_width() / 2, source.get_height()))
		# Find the solid silhouette, excluding distant nearly transparent glow.
		var low := cell.get_size()
		var high := Vector2i.ZERO
		for y in cell.get_height():
			for x in cell.get_width():
				if cell.get_pixel(x, y).a >= 0.3:
					low = low.min(Vector2i(x, y))
					high = high.max(Vector2i(x, y))
		var bounds := Rect2i(low, high - low + Vector2i.ONE).grow(4).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
		var art := cell.get_region(bounds)
		var height: int = HEIGHTS[index]
		art.resize(roundi(float(art.get_width()) / art.get_height() * height), height, Image.INTERPOLATE_LANCZOS)
		var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		# A small contact shadow travels with the sprite, without another node.
		for y in range(45, 52):
			for x in range(15, 49):
				var p := Vector2((x - 31.5) / 17.0, (y - 48.0) / 3.5)
				var alpha := maxf(0.0, 1.0 - p.length_squared()) * 0.18
				image.set_pixel(x, y, Color(0.12, 0.16, 0.2, alpha))
		var at := Vector2i((64 - art.get_width()) / 2, (64 - height) / 2)
		image.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), at)
		var error := image.save_png(OUTPUTS[index])
		if error != OK:
			push_error("Could not save loot sprite: " + OUTPUTS[index])
			quit(1)
			return
		print("Prepared loot sprite: ", OUTPUTS[index], " art ", art.get_size(), " on ", image.get_size())
	quit()
