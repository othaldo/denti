extends SoundController
## Real-time SFX throttling consumes global combat RNG at hardware-dependent
## intervals. Muting the audio bus still does so; this audit suppresses SFX calls.
func play_cue(_cue: StringName) -> void:
	pass
