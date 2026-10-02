extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var expected_stats: Array[StringName] = [&"damage_bonus", &"armor", &"max_health", &"attack_speed", &"crit_chance",
		&"regen", &"speed_bonus", &"luck", &"melee_damage", &"ranged_damage"]
	var source := DentiUIIcons.STAT_ATLAS.get_image()
	if source == null or not source.detect_alpha():
		_fail("stat atlas is missing its transparent background")
		return
	var selected_pixels := 0
	var regions: Array[Rect2] = []
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	var upgrades: Array[UpgradeData] = game.UPGRADES
	game.free()
	for index in expected_stats.size():
		var upgrade: UpgradeData
		for candidate in upgrades:
			if candidate.stat == expected_stats[index]:
				upgrade = candidate
				break
		if upgrade == null or upgrade.icon_index != index:
			_fail("stat does not use its own expected icon: " + str(expected_stats[index]))
			return
		var icon := DentiUIIcons.stat(upgrade.icon_index) as AtlasTexture
		if icon.atlas != DentiUIIcons.STAT_ATLAS or not icon.filter_clip or icon.get_size() != Vector2(512, 512):
			_fail("stat icon lacks a square padded frame or texture filtering isolation")
			return
		for previous in regions:
			if previous.intersects(icon.region):
				_fail("stat motifs share an overlapping source region")
				return
		regions.append(icon.region)
		var motif := source.get_region(Rect2i(icon.region))
		var used := motif.get_used_rect()
		if used.size.x < 100 or used.size.y < 100 or used.position.x < 4 or used.position.y < 4 or used.end.x > motif.get_width() - 4 or used.end.y > motif.get_height() - 4:
			_fail("stat motif is empty or clipped at its source boundary: " + str(expected_stats[index]))
			return
		if icon.margin.position.x < 40 or icon.margin.position.y < 40:
			_fail("stat motif has insufficient room around its visible outline")
			return
		selected_pixels += _visible_pixels(motif)
	# Every painted source pixel must belong to a complete selected motif.
	if selected_pixels != _visible_pixels(source):
		_fail("stat source regions omit artwork or include the same painted pixel twice")
		return
	var dodge_upgrade: UpgradeData = load("res://data/upgrades/zahnflutsch.tres")
	var dodge_icon := DentiUIIcons.stat(dodge_upgrade.attribute_icon()) as AtlasTexture
	if dodge_upgrade.stat != &"dodge_chance" or dodge_icon.atlas != DentiUIIcons.DODGE_ATLAS or not dodge_icon.filter_clip or dodge_icon.get_size() != Vector2(512, 512):
		_fail("Zahnflutsch does not have its own isolated painted icon")
		return
	var dodge_image := dodge_icon.atlas.get_image().get_region(Rect2i(dodge_icon.region))
	var painted_bounds := dodge_image.get_used_rect()
	if painted_bounds.size.x < 100 or painted_bounds.size.y < 100 or painted_bounds.position.x < 40 or painted_bounds.position.y < 40 or painted_bounds.end.x > 472 or painted_bounds.end.y > 472:
		_fail("Zahnflutsch motif is clipped or lacks transparent padding")
		return
	print("Denti stat icons test passed")
	quit(0)


func _visible_pixels(image: Image) -> int:
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var count := 0
	for offset in range(3, bytes.size(), 4):
		if bytes[offset] > 0:
			count += 1
	return count


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
