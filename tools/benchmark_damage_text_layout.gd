extends SceneTree

const SCENE := preload("res://scenes/ui/damage_number.tscn")
const ITERATIONS := 10000

class Uncached extends DamageNumberBatch:
	var previous_line := TextLine.new()
	func _text_layout(text: String, font: Font, font_size: int) -> TextLine:
		# The previous begin() path: reset and shape the popup's own buffer.
		previous_line.clear()
		previous_line.add_string(text, font, font_size)
		return previous_line

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cached := DamageNumberBatch.new()
	var previous := Uncached.new()
	root.add_child(cached)
	root.add_child(previous)
	for batch in [previous, cached]:
		batch.hide()
		batch.set_process(false)
	var numbers := [previous.acquire(SCENE), cached.acquire(SCENE)]
	var expected := -1.0
	for pass_index in 8:
		var number: DamageNumber = numbers[pass_index % 2]
		var checksum := 0.0
		seed(88817)
		var started := Time.get_ticks_usec()
		for index in ITERATIONS:
			number.show_amount(Vector2(200, 150), 120 + index % 7)
			checksum += number.render_line.get_line_width()
		var elapsed := Time.get_ticks_usec() - started
		if expected < 0:
			expected = checksum
		elif checksum != expected:
			push_error("Cached damage text changed glyph layout")
			quit(1)
			return
		if pass_index > 1:
			print(JSON.stringify({"cached": pass_index % 2 == 1, "pass": pass_index, "us_per_popup": float(elapsed) / ITERATIONS, "width_checksum": checksum}))
	previous.free()
	cached.free()
	numbers.clear()
	await process_frame
	quit()
