class_name ReleaseVersion
extends RefCounted


static func parse(value: String) -> Dictionary:
	var pattern := RegEx.create_from_string("^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(?:-([0-9A-Za-z]+(?:\\.[0-9A-Za-z]+)*))?$")
	var found := pattern.search(value)
	if found == null: return {}
	var suffix := found.get_string(4)
	for part in suffix.split("."):
		if part.is_valid_int() and part.length() > 1 and part.begins_with("0"): return {}
	return {"core": [int(found.get_string(1)), int(found.get_string(2)), int(found.get_string(3))], "suffix": suffix}


static func compare(left: String, right: String) -> int:
	var a := parse(left)
	var b := parse(right)
	if a.is_empty() or b.is_empty(): return 0
	for index in 3:
		if a.core[index] != b.core[index]: return 1 if a.core[index] > b.core[index] else -1
	if a.suffix == b.suffix: return 0
	if a.suffix.is_empty(): return 1
	if b.suffix.is_empty(): return -1
	var aa: PackedStringArray = a.suffix.split(".")
	var bb: PackedStringArray = b.suffix.split(".")
	for index in mini(aa.size(), bb.size()):
		if aa[index] == bb[index]: continue
		if aa[index].is_valid_int() and bb[index].is_valid_int():
			return 1 if int(aa[index]) > int(bb[index]) else -1
		if aa[index].is_valid_int() != bb[index].is_valid_int(): return -1 if aa[index].is_valid_int() else 1
		return 1 if aa[index] > bb[index] else -1
	return 1 if aa.size() > bb.size() else -1
