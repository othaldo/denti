class_name WeaponWorkingHead
extends Sprite2D

const MASK: Shader = preload("res://scripts/weapons/working_head.gdshader")


func configure(data: WeaponData) -> void:
	var source := AtlasTexture.new()
	var diameter := minf(data.sprite.get_size().x, data.sprite.get_size().y) * data.working_head_radius * 2.0
	var center := data.tip_anchor * data.sprite.get_size()
	var base := Vector2.ZERO
	if data.sprite is AtlasTexture:
		var atlas := data.sprite as AtlasTexture
		source.atlas = atlas.atlas
		base = atlas.region.position
	else:
		source.atlas = data.sprite
	source.region = Rect2(base + center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter)
	source.filter_clip = true
	texture = source
	position = WeaponMotion.tip_local(data)
	var mask := ShaderMaterial.new()
	mask.shader = MASK
	mask.set_shader_parameter("region_start", source.region.position / source.atlas.get_size())
	mask.set_shader_parameter("region_extent", source.region.size / source.atlas.get_size())
	material = mask
