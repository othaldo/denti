class_name AdaptiveGraphics
extends RefCounted

const LOW_FPS := 20.0
const SAMPLE_SECONDS := 1.0
const LOW_FPS_WINDOWS := 3
const WARMUP_SECONDS := 3.0

var economy: bool = false
var warmup_elapsed: float = 0.0
var sample_elapsed: float = 0.0
var sample_frames: int = 0
var low_fps_windows: int = 0


func reset() -> void:
	economy = false
	suspend()


func suspend() -> void:
	warmup_elapsed = 0.0
	sample_elapsed = 0.0
	sample_frames = 0
	low_fps_windows = 0


# Use wall time between rendered frames: Godot may cap process delta on slow devices.
func observe_frame(frame_seconds: float) -> bool:
	if economy or frame_seconds <= 0.0:
		return false
	if warmup_elapsed < WARMUP_SECONDS:
		warmup_elapsed += frame_seconds
		return false
	sample_elapsed += frame_seconds
	sample_frames += 1
	if sample_elapsed < SAMPLE_SECONDS:
		return false
	var fps := float(sample_frames) / sample_elapsed
	low_fps_windows = low_fps_windows + 1 if fps < LOW_FPS and not is_equal_approx(fps, LOW_FPS) else 0
	sample_elapsed = 0.0
	sample_frames = 0
	if low_fps_windows < LOW_FPS_WINDOWS:
		return false
	economy = true
	return true
