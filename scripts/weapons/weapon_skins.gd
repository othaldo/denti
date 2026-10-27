class_name WeaponSkins
extends RefCounted

## Resources load on equipment/preview changes, never during the frame loop.
const CACHE_LIMIT := 12
static var _skins: Dictionary[String, WeaponSkinData] = {}


static func with_element(data: WeaponData, element: StringName) -> WeaponData:
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
