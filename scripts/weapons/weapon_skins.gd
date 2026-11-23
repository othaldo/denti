class_name WeaponSkins
extends RefCounted

## Resources load on equipment/preview changes, never during the frame loop.
const CACHE_LIMIT := 12
const STAFF_ELEMENTS := preload("res://scripts/weapons/extraction_staff_element.gdshader")
const STAFF_WATER_COLOR := Color(0.16, 0.45, 1.0)
static var _skins: Dictionary[String, WeaponSkinData] = {}
static var _staff_materials: Dictionary[StringName, ShaderMaterial] = {}


static func with_element(data: WeaponData, element: StringName) -> WeaponData:
	if data.id == &"extraction_staff":
		if data.element_skin == element: return data
		var staff := data.duplicate() as WeaponData
		staff.element_skin = element
		return staff
	if not data.element_skins.has(str(element)):
		return data
	var path := str(data.element_skins[str(element)])
	if not _skins.has(path):
		if _skins.size() >= CACHE_LIMIT:
			_skins.erase(_skins.keys()[0])
		_skins[path] = load(path) as WeaponSkinData
	var result := data.duplicate() as WeaponData
	_skins[path].apply_to(result)
	result.element_skin = element
	return result


static func staff_material(data: WeaponData) -> ShaderMaterial:
	if data.id != &"extraction_staff": return null
	var element := data.element_skin
	if element == &"": return null
	if not _staff_materials.has(element):
		var definition := WeaponAffixes.by_id(element)
		if definition == null or not definition.elemental: return null
		var material := ShaderMaterial.new()
		material.shader = STAFF_ELEMENTS
		# Match the blue water icon and keep it distinct from the pale ice crystal.
		material.set_shader_parameter("element_color", STAFF_WATER_COLOR if element == &"wet" else definition.color)
		_staff_materials[element] = material
	return _staff_materials[element]
