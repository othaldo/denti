extends "res://tests/support/test_runtime.gd"
## Animated skill clouds are stateless, deterministic and cosmetic: the same
## age and seed always draw the same cloud, and the life cycle fades cleanly.


class Canvas extends Node2D:
	var style: SkillCloudStyle
	var age := 0.0
	var remaining := 1.0
	var drawn := false
	var lane := false
	func _draw() -> void:
		if lane:
			SkillPuffs.draw_lane(self, Vector2(20, 100), Vector2(220, 60), 40.0, style, age, remaining, 42)
			# Degenerate lanes must not break drawing.
			SkillPuffs.draw_lane(self, Vector2(50, 50), Vector2(50, 50), 40.0, style, age, remaining, 43)
		else:
			SkillPuffs.draw_cloud(self, Vector2(100, 100), 60.0, style, age, remaining, 42)
		drawn = true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var style: SkillCloudStyle = load("res://data/vfx/skill_clouds/poison.tres")
	check(style != null and style.puffs > 0, "Poison cloud style must load")

	# Life cycle: billows up, holds, dissolves to nothing.
	var start := SkillPuffs.lifecycle(style, 0.0, 2.5)
	var settled := SkillPuffs.lifecycle(style, 1.0, 1.5)
	var gone := SkillPuffs.lifecycle(style, 2.5, 0.0)
	check(is_zero_approx(start.y) and start.x < 0.5, "A fresh cloud starts small and invisible")
	check(is_equal_approx(settled.x, 1.0) and is_equal_approx(settled.y, 1.0), "A settled cloud has full size and opacity")
	check(is_zero_approx(gone.y), "An expired cloud is fully transparent")

	# Determinism: hashes depend only on their inputs.
	check(SkillPuffs.hash01(42, 3, 1) == SkillPuffs.hash01(42, 3, 1), "Puff layout must be deterministic")
	check(SkillPuffs.hash01(42, 3, 1) != SkillPuffs.hash01(43, 3, 1), "Different clouds must vary")
	for index in 50:
		var value := SkillPuffs.hash01(index * 977, index, 5)
		check(value >= 0.0 and value <= 1.0, "Hash values must stay in 0..1")
	check(SkillPuffs.seed_for(Vector2(10.2, 20.1)) == SkillPuffs.seed_for(Vector2(10.2, 20.1)), "Seed from position must be stable")

	# Sparing graphics draw fewer puffs, never none.
	SkillPuffs.economy = false
	var full := SkillPuffs.puff_count(style)
	SkillPuffs.economy = true
	var sparing := SkillPuffs.puff_count(style)
	SkillPuffs.economy = false
	check(sparing < full and sparing >= 2, "Economy mode must reduce puffs")
	check(SkillPuffs.puff_region(5) == SkillPuffs.puff_region(1), "Puff variants wrap around the atlas")
	check(SkillPuffs.ATLAS.get_size() == Vector2(SkillPuffs.PUFF_CELL * SkillPuffs.PUFF_VARIANTS, SkillPuffs.PUFF_CELL + SkillPuffs.SMALL_CELL), "Atlas layout must match the baker")

	# Drawing works through a real canvas across the whole life.
	var canvas := Canvas.new()
	canvas.style = style
	root.add_child(canvas)
	for id in ["poison", "ember", "frost", "poison_lane", "foam"]:
		var each: SkillCloudStyle = load("res://data/vfx/skill_clouds/%s.tres" % id)
		check(each != null, "Style %s must load" % id)
		canvas.style = each
		for lane in [false, true]:
			canvas.lane = lane
			for stage in [[0.05, 2.4], [1.0, 1.5], [2.4, 0.1], [2.5, 0.0]]:
				canvas.age = stage[0]
				canvas.remaining = stage[1]
				canvas.drawn = false
				canvas.queue_redraw()
				# Headless runs still dispatch canvas draw callbacks on the next frame.
				await process_frame
				await process_frame
				check(canvas.drawn, "%s must draw at age %s (lane %s)" % [id, stage[0], lane])

	# The assassin cloud uses the style and keeps its saved fields unchanged.
	var skills := AssassinSkills.new()
	check(skills.CLOUD_STYLE == style, "Assassin poison clouds use the poison style")
	skills.free()
	check(EmberSkills.CORE_STYLE.rise_sparkles, "Ember cores rise sparks, not bubbles")
	check(FrostSkills.WALL_STYLE != null and RinserSkills.FOAM_STYLE != null and ClassDashCut.FIELD_STYLE != null, "Frost, rinser and assassin lanes have styles")
	canvas.queue_free()
	finish_checks()
