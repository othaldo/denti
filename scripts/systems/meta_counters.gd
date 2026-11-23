class_name MetaCounters
extends RefCounted
## Lifetime counters that feed meta unlocks. Every run adds to them; they are
## never reset, so even a lost run brings visible progress.

const KEYS: Array[String] = ["kills", "bosses", "elites", "coins", "deaths", "runs"]
## Plural labels for progress texts ("2.312 / 5.000 Kills").
const LABELS := {"kills": "Kills", "bosses": "Bosse", "elites": "Elites", "coins": "Münzen", "deaths": "Tode", "runs": "Runs"}


static func label(key: StringName) -> String:
	return LABELS.get(str(key), str(key))


## "5.000" with German thousands separators.
static func number(value: int) -> String:
	var digits := str(absi(value))
	var result := ""
	while digits.length() > 3:
		result = "." + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + result
