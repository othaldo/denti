class_name ShopController
extends Node

const CATALOG: Array[ShopOfferData] = [
	preload("res://data/items/metal_crown.tres"),
	preload("res://data/items/fluoride_gel.tres"),
	preload("res://data/items/gold_filling.tres"),
	preload("res://data/items/mouthwash.tres"),
	preload("res://data/items/implant.tres"),
	preload("res://data/items/polish_paste.tres"),
	preload("res://data/items/saliva_fountain.tres"),
	preload("res://data/items/ceramic_shell.tres"),
	preload("res://data/items/mint_essence.tres"),
	preload("res://data/items/lucky_molar.tres"),
	preload("res://data/items/floss_reel.tres"),
	preload("res://data/items/cavity_bounty.tres"),
	preload("res://data/items/radiant_filling.tres"),
	preload("res://data/items/tooth_fairy_pact.tres"),
	preload("res://data/items/amalgam_core.tres"),
	preload("res://data/items/scalpel_wax.tres"),
	preload("res://data/items/holy_flash.tres"),
	preload("res://data/items/divine_seal.tres"),
	preload("res://data/weapons/shop_magic_toothbrush.tres"),
	preload("res://data/weapons/shop_turbo_drill.tres"),
	preload("res://data/weapons/shop_floss_whip.tres"),
	preload("res://data/weapons/shop_water_jet.tres"),
	preload("res://data/weapons/shop_crown_launcher.tres"),
	preload("res://data/weapons/shop_enamel_mirror.tres"),
	preload("res://data/weapons/shop_plaque_scaler.tres"),
	preload("res://data/weapons/shop_mouthwash_mortar.tres"),
]
const WEAPON_CHANCE := 0.35
const SAME_WEAPON_CHANCE := 0.30
const SAME_MODE_CHANCE := 0.15
const ITEM_TAG_CHANCE := 0.28
const WEAPON_PRICE_MULTIPLIERS := [1.0, 1.65, 2.4, 3.3]

var offers: Array[ShopOfferData] = []
var reroll_cost: int = 2
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func open_shop(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory = null) -> void:
	reroll_cost = 2
	_roll_offers(wave_number, luck, loadout, items)


func reroll(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory = null) -> void:
	_roll_offers(wave_number, luck, loadout, items)
	reroll_cost += 1


func take_offer(index: int) -> ShopOfferData:
	var offer := offers[index]
	offers[index] = null
	return offer


static func by_id(id: StringName) -> ShopOfferData:
	for offer in CATALOG:
		if offer.id == id:
			return offer
	return null


static func weapon_offer(template: ShopOfferData, tier: int) -> ShopOfferData:
	var offer := template.duplicate() as ShopOfferData
	offer.weapon_tier = clampi(tier, 1, WeaponLoadout.MAX_TIER)
	offer.rarity_tier = offer.weapon_tier
	offer.price = maxi(roundi(float(template.price) * WEAPON_PRICE_MULTIPLIERS[offer.weapon_tier - 1]), 1)
	return offer


func _roll_offers(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory) -> void:
	offers.clear()
	for index in 3:
		var tier := DentiRarity.roll(wave_number, luck, rng)
		var wants_weapon := index < (2 if wave_number <= 2 else 1) or rng.randf() < WEAPON_CHANCE
		var offer: ShopOfferData = _pick_weapon(tier, loadout) if wants_weapon else null
		if offer == null:
			offer = _pick_item(tier, items, loadout)
		if offer == null:
			offer = _pick_weapon(tier, loadout)
		offers.append(offer)
	offers.shuffle()


func _pick_item(tier: int, items: ItemInventory, loadout: WeaponLoadout) -> ShopOfferData:
	var wanted_tags: Array[StringName] = items.preferred_tags(loadout) if items != null else []
	for candidate_tier in range(tier, 0, -1):
		var pool: Array[ShopOfferData] = []
		var tagged: Array[ShopOfferData] = []
		for template in CATALOG:
			if template.weapon_data == null and template.rarity_tier == candidate_tier and not _already_offered(template.id, 0) and (items == null or items.can_acquire(template)):
				pool.append(template)
				for tag in template.tags:
					if wanted_tags.has(tag):
						tagged.append(template)
						break
		if not pool.is_empty():
			var selected := tagged if not tagged.is_empty() and rng.randf() < ITEM_TAG_CHANCE else pool
			return selected[rng.randi_range(0, selected.size() - 1)]
	return null


func _pick_weapon(tier: int, loadout: WeaponLoadout) -> ShopOfferData:
	var candidates: Array[ShopOfferData] = []
	for template in CATALOG:
		if template.weapon_data != null and loadout.can_acquire(template.weapon_data, tier) and not _already_offered(template.id, tier):
			candidates.append(template)
	if candidates.is_empty():
		return null
	var matching: Array[ShopOfferData] = []
	var same_mode: Array[ShopOfferData] = []
	var equipped := loadout.equipped()
	for candidate in candidates:
		var has_mode := false
		for weapon in equipped:
			if weapon.data.id == candidate.id:
				matching.append(candidate)
			if weapon.data.attack_mode == candidate.weapon_data.attack_mode:
				has_mode = true
		if has_mode:
			same_mode.append(candidate)
	var pool := candidates
	var roll := rng.randf()
	if roll < SAME_WEAPON_CHANCE and not matching.is_empty():
		pool = matching
	elif roll < SAME_WEAPON_CHANCE + SAME_MODE_CHANCE and not same_mode.is_empty():
		pool = same_mode
	return weapon_offer(pool[rng.randi_range(0, pool.size() - 1)], tier)


func _already_offered(id: StringName, tier: int) -> bool:
	for offer in offers:
		if offer != null and offer.id == id and (tier == 0 or offer.weapon_tier == tier):
			return true
	return false
