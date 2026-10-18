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
