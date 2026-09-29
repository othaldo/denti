#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${DENTI_GODOT_BIN:-}" ]]; then
	godot_bin="$DENTI_GODOT_BIN"
elif [[ -x /usr/local/bin/godot ]]; then
	godot_bin=/usr/local/bin/godot
else
	godot_bin="$(command -v godot)"
fi
printf 'Godot: %s (%s)\n' "$godot_bin" "$("$godot_bin" --version)"

class_cache="$project_dir/.godot/global_script_class_cache.cfg"
if [[ ! -f "$class_cache" ]]; then
	printf 'Godot class cache missing; importing project once...\n'
	"$godot_bin" --headless --path "$project_dir" --editor --quit
fi

if [[ "${1:-}" == "--probe" ]]; then
	shift
	exec "$godot_bin" --path "$project_dir" --script res://tools/performance_probe.gd "$@"
fi

exec "$godot_bin" --path "$project_dir" "$@"
