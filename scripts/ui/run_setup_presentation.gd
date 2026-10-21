class_name RunSetupPresentation
extends RefCounted

# Visible painted bounds (alpha >= 16/255), with a 3-source-pixel fringe.
# UI framing only: original PNGs, atlas cells and combat/grip coordinates stay
# intact. Faint stray pixels in the old sheets must not size/offset the art.
const ICON_BOUNDS := {
	&"magic_toothbrush": Rect2(354, 8, 378, 1520),
	&"turbo_drill": Rect2(46, 9, 1178, 1247),
	&"floss_whip": Rect2(38, 54, 1192, 1156),
	&"water_jet": Rect2(39, 33, 434, 445),
	&"crown_launcher": Rect2(34, 47, 444, 418),
	&"enamel_mirror": Rect2(105, 34, 891, 1467),
	&"plaque_scaler": Rect2(77, 61, 930, 1417),
	&"mouthwash_mortar": Rect2(33, 47, 445, 417),
	&"toothpick_spear": Rect2(50, 64, 297, 301),
	&"cavity_grinder": Rect2(24, 47, 390, 375),
	&"interdental_brush": Rect2(67, 58, 300, 316),
	&"fluoride_sprayer": Rect2(74, 34, 364, 444),
	&"water_turbine": Rect2(33, 59, 446, 393),
	&"uv_lamp": Rect2(43, 60, 343, 296),
	&"amalgam_slingshot": Rect2(50, 34, 413, 444),
	&"floss_garrote": Rect2(37, 58, 328, 261),
	&"prophylaxis_polisher": Rect2(53, 58, 349, 409),
	&"fluoride_rocket": Rect2(28, 49, 340, 307),
}
static var _icons: Dictionary = {}

static func weapon_icon(weapon: WeaponData) -> Texture2D:
	var source := weapon.sprite
	if source == null or not ICON_BOUNDS.has(weapon.id): return source
	if _icons.has(source): return _icons[source]
	var frame := AtlasTexture.new()
	var bounds: Rect2 = ICON_BOUNDS[weapon.id]
	if source is AtlasTexture:
		frame.atlas = source.atlas
		frame.region = Rect2(source.region.position + bounds.position, bounds.size)
	else:
		frame.atlas = source
		frame.region = bounds
	frame.filter_clip = true
	_icons[source] = frame
	return frame

static func values(weapon: WeaponData) -> Array[String]:
	return [str(roundi(weapon.damage_at_tier(1))), ("%.2f" % weapon.interval_at_tier(1)).replace(".", ",") + " s", str(roundi(weapon.range_at_tier(1)))]

static func details(weapon: WeaponData) -> String:
	var description := weapon.description.trim_prefix(weapon.roots_text() + " · ")
	var extra := " · ".join(weapon.stats_text(1).split(" · ").slice(3))
	return description + ("\n\n" + extra if not extra.is_empty() else "") + "\n\n" + weapon.combat_text()
