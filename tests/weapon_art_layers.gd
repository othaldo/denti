extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for id in [&"cavity_grinder", &"prophylaxis_polisher"]:
		var data := WeaponCatalog.by_id(id)
		if data.held_sprite == null or data.held_sprite == data.sprite or data.working_head_texture == null:
			_fail("working head is baked into its rotating body: " + str(id))
			return
		var head := WeaponWorkingHead.new()
		head.configure(data)
		root.add_child(head)
		var projection := head.transform
		head.advance(PI * 0.5)
		if head.transform != projection or not is_equal_approx(head.face.rotation, PI * 0.5):
			_fail("rotating face changed the axle/ellipse perspective")
			return
		if head.position.distance_to(WeaponMotion.tip_local(data)) > 0.001:
			_fail("working face detached from contact anchor")
			return
		head.free()
	var sling := WeaponCatalog.by_id(&"amalgam_slingshot")
	var elastic := WeaponElastic.new()
	elastic.configure(sling)
	root.add_child(elastic)
	var left := elastic.left
	var right := elastic.right
	var drawn := elastic.pouch.position
	elastic.set_progress(0.0)
	if drawn.distance_to(elastic.pouch.position) < 10.0 or elastic.left != left or elastic.right != right:
		_fail("slingshot did not release its pouch from stationary fork tips")
		return
	var rest := WeaponMotion.pose(sling, 1, Vector2(50, 16), Vector2.RIGHT, -1.0, 0.0)
	var active := WeaponMotion.pose(sling, 1, Vector2(50, 16), Vector2.RIGHT, 0.5, 0.0)
	if rest.scale != active.scale or active.rotation != 0.0:
		_fail("drawing the slingshot warped its rigid grip")
		return
	elastic.free()
	for data in WeaponCatalog.ALL:
		for side in [-1.0, 1.0]:
			var home := Vector2(side * 50.0, 16.0)
			var idle := WeaponMotion.pose(data, 1, home, Vector2(side, 0), -1, 0)
			if Vector2(idle.position).distance_to(home) > 0.001:
				_fail("idle grip floated away from its hand: " + str(data.id))
				return
		if data.sprite is AtlasTexture and (data.sprite as AtlasTexture).atlas.resource_path == "res://assets/weapons/weapon_icons_refined.png":
			var image := data.sprite.get_image()
			var used := image.get_used_rect()
			if used.position.x < 2 or used.position.y < 2 or used.end.x > image.get_width() - 2 or used.end.y > image.get_height() - 2:
				_fail("refined icon touches its atlas cell border: " + str(data.id))
				return
	print("PASS weapon_art_layers")
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
