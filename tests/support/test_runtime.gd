extends SceneTree

var _finish_requested: bool = false
var _finish_code: int = 0
var _owned_stats: Array[PlayerStats] = []


func new_stats() -> PlayerStats:
	var stats := PlayerStats.new()
	_owned_stats.append(stats)
	return stats


func finish(exit_code: int = 0) -> void:
	_finish_code = maxi(_finish_code, exit_code)
	if _finish_requested:
		return
	_finish_requested = true
	call_deferred("_finish_test")


func _finish_test() -> void:
	paused = true
	_stop_audio(root)
	# --fixed-fps can complete two frames before the audio thread consumes stop.
	OS.delay_msec(100)
	for stats in _owned_stats:
		if is_instance_valid(stats) and not stats.is_inside_tree():
			stats.free()
	_owned_stats.clear()
	for child in root.get_children():
		if child.name != &"GameSession":
			child.process_mode = Node.PROCESS_MODE_DISABLED
			child.queue_free()
	# Audio playback and queued UI callbacks release resources on the next frame.
	await process_frame
	await process_frame
	# Frees from earlier scene replacements also reach the audio mixer asynchronously.
	OS.delay_msec(100)
	quit(_finish_code)


func _stop_audio(node: Node) -> void:
	if node is MusicController:
		node.stop_music()
	elif node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		node.stop()
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		node.stream = null
	for child in node.get_children():
		_stop_audio(child)


# Existing gameplay fixtures retain their original three starting loadouts.
# Exercise the real preview + explicit confirmation flow before combat.
func choose_panel(panel: ChoicePanel, index: int) -> void:
	if panel.mode == &"starter":
		var legacy_ids := [&"magic_toothbrush", &"turbo_drill", &"water_jet"]
		var selected := panel.starter_options[index].id
		if index < legacy_ids.size() and WeaponCatalog.by_id(legacy_ids[index]) in panel.starter_options:
			selected = legacy_ids[index]
		for option in panel.starter_options.size():
			if panel.starter_options[option].id == selected:
				panel.starter_selection.select_weapon(option)
				panel.starter_selection.confirm_selection()
				return
	else:
		panel._on_choice_pressed(index)
