class_name WaveProfileCatalog
extends RefCounted

const PROFILES: Array[WaveProfileData] = [
	preload("res://data/wave_profiles/swarm.tres"),
	preload("res://data/wave_profiles/crossfire.tres"),
	preload("res://data/wave_profiles/rush.tres"),
	preload("res://data/wave_profiles/sugar_flood.tres"),
]


static func by_id(id: StringName) -> WaveProfileData:
	for profile in PROFILES:
		if profile.id == id:
			return profile
	return null


static func roll_for_wave(wave_number: int, avoid_id: StringName = &"") -> StringName:
	if wave_number <= 0:
		return &""
	var pool: Array[WaveProfileData] = []
	for profile in PROFILES:
		if wave_number >= profile.first_wave and profile.id != avoid_id:
			pool.append(profile)
	if pool.is_empty():
		for profile in PROFILES:
			if wave_number >= profile.first_wave:
				pool.append(profile)
	return pool.pick_random().id if not pool.is_empty() else &""
