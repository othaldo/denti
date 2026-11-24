extends "res://tests/support/test_runtime.gd"

const PREPARED = preload("res://scripts/enemies/prepared_enemy_sprites.gd")
const TYPES: Array[EnemyData] = [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.POISON_GERM, WaveController.GUM_BITER, WaveController.ACID_CROWN, WaveController.HUNT_GERM]
const SOURCES := ["plaque", "bacteria", "sugar", "acid_spitter", "poison_germ", "gum_biter", "acid_spitter", "bacteria"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var atlas := PREPARED.ATLAS.get_image()
	for path: String in PREPARED.REGIONS:
		var original: Image = load(path).get_image()
		original.convert(Image.FORMAT_RGBA8)
		var packed := atlas.get_region(Rect2i(PREPARED.REGIONS[path]))
		if packed.get_size() != original.get_size() or packed.get_data() != original.get_data():
			check(false, "enemy atlas changed source pixels or dimensions: %s" % path)
	for number in TYPES.size():
		var path := "res://assets/enemies/%s.png" % SOURCES[number]
		var texture := TYPES[number].sprite as AtlasTexture
		if texture == null or texture.atlas != PREPARED.ATLAS or texture.region != PREPARED.REGIONS[path] or texture.get_size() != PREPARED.REGIONS[path].size or not texture.filter_clip:
			check(false, "enemy resource lost its full-size shared-atlas cell: %s" % TYPES[number].display_name)
	# Boss images retain their own textures and animated presentation.
	for data in [WaveController.CAVITY_COUNT, WaveController.CAVITY_PRINCE, WaveController.CAVITY_KING, WaveController.CAVITY_EMPEROR]:
		if data.sprite is AtlasTexture:
			check(false, "enemy atlas unexpectedly changed a boss image")
	if failures.is_empty():
		print("Denti enemy sprite atlas test passed")
	finish_checks()
