extends WeaponStrike
## Probe-only counters: no random draws and no changes to contacts or damage.

var metrics: Dictionary = {}
var open := false
var original_target := 0
var lost := false


func begin(amount: float, is_critical: bool, target: Enemy, max_contacts: int = 1) -> void:
	if open: flush()
	super.begin(amount, is_critical, target, max_contacts)
	open = true
	original_target = target.get_instance_id()
	lost = false
	_add("started")


func tick(weapon: WeaponInstance, from_progress: float, to_progress: float) -> void:
	if open and hit_ids.is_empty() and to_progress >= WeaponMotion.ACTIVE_START:
		var target := instance_from_id(original_target) as Enemy if original_target != 0 else null
		if not is_instance_valid(target) or target.is_queued_for_deletion() or target.health <= 0:
			lost = true
	super.tick(weapon, from_progress, to_progress)
	if open and to_progress >= WeaponMotion.ACTIVE_END:
		_add("completed")
		_add("contact_attacks" if not hit_ids.is_empty() else "no_contact_attacks")
		_add("contacts", hit_ids.size())
		_add("extra_contacts", maxi(hit_ids.size() - 1, 0))
		if lost:
			_add("lost_target")
			_add("lost_but_contacted" if not hit_ids.is_empty() else "lost_without_contact")
		open = false


func flush() -> void:
	if open:
		_add("interrupted")
		open = false


func _add(key: String, count: int = 1) -> void:
	metrics[key] = int(metrics.get(key, 0)) + count
