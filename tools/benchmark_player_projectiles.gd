extends SceneTree

# Isolate spawn + retirement cost. The reference path creates and synchronously
# frees each shot, while the pool keeps the same sprites. Neither path measures
# flight, hits, GPU work or real-time FPS. Alternate paths after one warmup pair.
const SALVOS := 1000
const SHOTS := 9
const WEAPON: WeaponData = preload("res://data/weapons/trinity_brush.tres")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	paused = true
	var pool := PlayerProjectilePool.new()
	root.add_child(pool)
	pool.prepare(WEAPON, 4, SHOTS)
	var created := pool.created
	var salvo: Array[WeaponProjectile] = []
	for pass_index in 8:
		var started := Time.get_ticks_usec()
		for cycle in SALVOS:
			for number in SHOTS:
				var shot: WeaponProjectile
				if pass_index % 2 == 0:
					shot = PlayerProjectilePool.PROJECTILE.instantiate()
					pool.add_child(shot)
				else:
					shot = pool.acquire(WEAPON, 4)
				shot.launch(Vector2(600, 300), Vector2.RIGHT, 100, WEAPON, null, false, 4)
				salvo.append(shot)
			for shot in salvo:
				if pass_index % 2 == 0:
					shot.free()
				else:
					shot.retire()
			salvo.clear()
		var elapsed := Time.get_ticks_usec() - started
		if pool.created != created or pool.get_child_count() != 0 or pool.idle_count != SHOTS:
			push_error("benchmark lost or newly allocated pooled projectiles")
			pool.free()
			quit(1)
			return
		if pass_index > 1:
			print(JSON.stringify({"path": "pooled" if pass_index % 2 else "instantiate_free", "pass": pass_index, "shots_per_salvo": SHOTS, "ms_per_salvo": float(elapsed) / SALVOS / 1000}))
	pool.free()
	await process_frame
	quit()
