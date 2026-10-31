extends RefCounted
## Shared material: analytic masks in known atlas cells, all other art passes through.
## No per-warning nodes, images, render targets or per-frame material allocation.

const SHADER := preload("res://scripts/vfx/warning_antialias.gdshader")
static var shared_material: ShaderMaterial

static func apply_to(canvas: CanvasItem) -> void:
	# Respect effects owned by the caller (including inherited materials).
	if canvas.material != null or canvas.use_parent_material: return
	if shared_material == null:
		shared_material = ShaderMaterial.new()
		shared_material.shader = SHADER
	canvas.material = shared_material
