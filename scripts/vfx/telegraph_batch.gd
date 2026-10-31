extends RefCounted
## Two shared MultiMeshes per drawing owner, not one node/material per attack.
## Internal children never appear in gameplay enemy collections.

const SHADER := preload("res://scripts/vfx/telegraph.gdshader")
const META := &"denti_telegraph_batch"
const PADDING := 14.0
enum Shape { LANE, CIRCLE, SECTOR, CAPSULE, TIMER }
enum Phase { WARNING, ACTIVE, RELEASE }
static var mesh: QuadMesh
static var fill_material: ShaderMaterial
static var edge_material: ShaderMaterial
var fill: MultiMeshInstance2D
var edge: MultiMeshInstance2D
var count := 0
var capacity := 0
var transforms: Array[Transform2D] = []
var parameters: Array[Color] = []
var colors: Array[Color] = []
var densities: Array[float] = []

static func prepare() -> void:
	if mesh != null: return
	mesh = QuadMesh.new()
	mesh.size = Vector2(2, 2)
	fill_material = ShaderMaterial.new()
	fill_material.shader = SHADER
	fill_material.set_shader_parameter("edge_pass", false)
	edge_material = ShaderMaterial.new()
	edge_material.shader = SHADER
	edge_material.set_shader_parameter("edge_pass", true)

static func for_canvas(canvas: CanvasItem):
	if canvas.has_meta(META): return canvas.get_meta(META)
	var batch = load("res://scripts/vfx/telegraph_batch.gd").new()
	batch.attach(canvas)
	canvas.set_meta(META, batch)
	return batch

func attach(canvas: CanvasItem) -> void:
	prepare()
	fill = _layer(fill_material)
	edge = _layer(edge_material)
	fill.name = &"TelegraphFill"
	edge.name = &"TelegraphContour"
	fill.show_behind_parent = true
	canvas.add_child(fill, false, Node.INTERNAL_MODE_BACK)
	canvas.add_child(edge, false, Node.INTERNAL_MODE_BACK)
	# CanvasItem emits draw before invoking its script's _draw. Empty redraws
	# therefore clear obsolete warnings as reliably as populated redraws.
	canvas.draw.connect(begin)
	_grow(16)

func _layer(shader_material: ShaderMaterial) -> MultiMeshInstance2D:
	var node := MultiMeshInstance2D.new()
	node.material = shader_material
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	node.multimesh.use_colors = true
	node.multimesh.use_custom_data = true
	node.multimesh.mesh = mesh
	return node

func begin() -> void:
	count = 0
	fill.multimesh.visible_instance_count = 0
	edge.multimesh.visible_instance_count = 0

func _grow(size: int) -> void:
	capacity = size
	transforms.resize(size)
	parameters.resize(size)
	colors.resize(size)
	densities.resize(size)
	for layer in [fill, edge]: layer.multimesh.instance_count = size
	for index in count: _upload(index)
	fill.multimesh.visible_instance_count = count
	edge.multimesh.visible_instance_count = count

func _upload(index: int) -> void:
	for layer in [fill, edge]:
		layer.multimesh.set_instance_transform_2d(index, transforms[index])
		layer.multimesh.set_instance_custom_data(index, parameters[index])
	edge.multimesh.set_instance_color(index, colors[index])
	fill.multimesh.set_instance_color(index, Color(colors[index], colors[index].a * densities[index]))

func add(shape: int, first: float, second: float, progress: float, tint: Color, placement: Transform2D, phase: int = Phase.WARNING, density: float = 1.0, front_limit: float = 1.0) -> void:
	if first <= 0 or tint.a <= 0: return
	if count == capacity: _grow(capacity * 2)
	var extent := Vector2.ONE * (first + PADDING)
	if shape in [Shape.LANE, Shape.CAPSULE]:
		extent = Vector2(first * 0.5 + PADDING + (second if shape == Shape.CAPSULE else 0.0), second + PADDING)
		placement *= Transform2D(0, Vector2(first * 0.5, 0))
	elif shape == Shape.SECTOR:
		# A narrow cone needs only its forward bounding box, not a full disk.
		var left := first * minf(cos(second), 0.0)
		extent = Vector2((first - left) * 0.5 + PADDING, first * sin(minf(second, PI * 0.5)) + PADDING)
		placement *= Transform2D(0, Vector2((first + left) * 0.5, 0))
	transforms[count] = placement * Transform2D(0, extent, 0, Vector2.ZERO)
	# Integer part: shape + 8*phase; fractional half: 0..1 front limit.
	# Values stay below 21, retaining subpixel precision on long lanes.
	parameters[count] = Color(shape + phase * 8 + clampf(front_limit, 0, 1) * 0.5, clampf(progress, 0, 1), first, second)
	colors[count] = tint
	densities[count] = clampf(density, 0, 1)
	_upload(count)
	count += 1
	fill.multimesh.visible_instance_count = count
	edge.multimesh.visible_instance_count = count
