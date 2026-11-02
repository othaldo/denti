class_name DentipediaWeaponDetails
extends RefCounted
## Read the same resource helpers as the rest of the weapon UI.

static func build(parent: VBoxContainer, data: WeaponData, searchable_body: String) -> void:
	DentiUIComponents.label(parent, data.description.trim_prefix(data.roots_text() + " · "), 18)
	var roots := DentiUIComponents.label(parent, data.roots_text() + "\n" + data.scaling_label(), 16)
	roots.tooltip_text = data.scaling_description()
	roots.add_theme_color_override("font_color", DentiUIStyle.MINT)
	var combat := DentiUIComponents.label(parent, data.combat_text().replace(" · " + data.scaling_text(), ""), 15)
	combat.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	for paragraph in searchable_body.split("\n\n"):
		if paragraph.begins_with("Die Griffe bleiben") or paragraph.begins_with("Der Griff bleibt"):
			DentiUIComponents.label(parent, paragraph, 15)
	var caption := DentiUIComponents.label(parent, "Basiswerte", 14)
	caption.tooltip_text = "Ohne deinen Build. Bisskraft, Nah-/Fernschaden, Putzeifer und Items verändern die tatsächlichen Kampfwerte."
	caption.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	var tiers := GridContainer.new()
	tiers.columns = 2
	tiers.add_theme_constant_override("h_separation", 18)
	tiers.add_theme_constant_override("v_separation", 14)
	parent.add_child(tiers)
	for tier in ([4] if data.evolution_kind != &"" else [1, 2, 3, 4]):
		var mark := DentiUIComponents.label(tiers, WeaponPresentation.tier_text(data, tier), 17)
		mark.custom_minimum_size.x = 48
		mark.add_theme_color_override("font_color", DentiRarity.color_for(tier).lightened(0.25))
		var values := DentiUIComponents.label(tiers, data.stats_text(tier), 16)
		values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
