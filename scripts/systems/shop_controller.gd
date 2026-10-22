class_name ShopController
extends Node

const WEAPON_OFFERS: Array[ShopOfferData] = [
	preload("res://data/weapons/shop_magic_toothbrush.tres"),
	preload("res://data/weapons/shop_turbo_drill.tres"),
	preload("res://data/weapons/shop_floss_whip.tres"),
	preload("res://data/weapons/shop_water_jet.tres"),
	preload("res://data/weapons/shop_crown_launcher.tres"),
	preload("res://data/weapons/shop_enamel_mirror.tres"),
	preload("res://data/weapons/shop_plaque_scaler.tres"),
	preload("res://data/weapons/shop_mouthwash_mortar.tres"),
	preload("res://data/weapons/shop_toothpick_spear.tres"),
	preload("res://data/weapons/shop_cavity_grinder.tres"),
	preload("res://data/weapons/shop_interdental_brush.tres"),
	preload("res://data/weapons/shop_fluoride_sprayer.tres"),
	preload("res://data/weapons/shop_water_turbine.tres"),
	preload("res://data/weapons/shop_uv_lamp.tres"),
	preload("res://data/weapons/shop_amalgam_slingshot.tres"),
	preload("res://data/weapons/shop_floss_garrote.tres"),
	preload("res://data/weapons/shop_prophylaxis_polisher.tres"),
	preload("res://data/weapons/shop_fluoride_rocket.tres"),
]
# Compatibility view for existing tools; gameplay uses the explicit catalogs.
const CATALOG: Array[ShopOfferData] = ItemCatalog.ALL + WEAPON_OFFERS

const WEAPON_CHANCE := 0.35
const SAME_WEAPON_CHANCE := 0.30
const SAME_MODE_CHANCE := 0.15
const ITEM_TAG_CHANCE := 0.28
const WEAPON_PRICE_MULTIPLIERS := [1.0, 1.65, 2.4, 3.3]
const OFFER_COUNT := 4

var offers: Array[ShopOfferData] = []
var reserved: Array[bool] = [false, false, false, false]
var reroll_cost: int = 2
var reroll_step: int = 1
var rerolls: int = 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func open_shop(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory = null) -> void:
	rerolls = 0
	reroll_cost = EndlessRules.shop_reroll_start(wave_number)
	reroll_step = EndlessRules.shop_reroll_step(wave_number)
	_roll_offers(wave_number, luck, loadout, items)


func reroll(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory = null) -> void:
	_roll_offers(wave_number, luck, loadout, items)
	rerolls += 1
	reroll_cost = maxi(reroll_cost + reroll_step, EconomyRules.shop_reroll_cost(wave_number, rerolls))


func take_offer(index: int) -> ShopOfferData:
	var offer := offers[index]
	offers[index] = null
	reserved[index] = false
	return offer


func toggle_reservation(index: int) -> bool:
	if index < 0 or index >= offers.size() or offers[index] == null:
		return false
	reserved[index] = not reserved[index]
	return true


func can_reroll() -> bool:
	for index in OFFER_COUNT:
		if not reserved[index] or index >= offers.size() or offers[index] == null:
			return true
	return false


static func by_id(id: StringName) -> ShopOfferData:
	var item := ItemCatalog.by_id(id)
	if item != null:
		return item
	for offer in WEAPON_OFFERS:
		if offer.id == id:
			return offer
	return null

static func weapon_offer(template: ShopOfferData, tier: int) -> ShopOfferData:
	var offer := template.duplicate() as ShopOfferData
	offer.weapon_tier = clampi(tier, 1, WeaponLoadout.MAX_TIER)
	offer.rarity_tier = offer.weapon_tier
	offer.price = maxi(roundi(float(template.price) * WEAPON_PRICE_MULTIPLIERS[offer.weapon_tier - 1]), 1)
	return offer


func complete_saved_offers(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory) -> void:
	_roll_offers(wave_number, luck, loadout, items, true)


func _roll_offers(wave_number: int, luck: float, loadout: WeaponLoadout, items: ItemInventory, preserve_existing: bool = false) -> void:
	var previous := offers.duplicate()
	offers = [null, null, null, null]
	for index in OFFER_COUNT:
		if index < previous.size() and (preserve_existing or (reserved[index] and previous[index] != null)):
			offers[index] = previous[index]
		else:
			reserved[index] = false
	for index in OFFER_COUNT:
		if offers[index] != null or (preserve_existing and index < previous.size()):
			continue
		var tier := DentiRarity.roll_item(wave_number, luck, rng)
		var wants_weapon := index < (2 if wave_number <= 2 else 1) or rng.randf() < WEAPON_CHANCE
		var offer: ShopOfferData = _pick_weapon(mini(tier, WeaponLoadout.MAX_TIER), loadout) if wants_weapon else null
		if offer == null:
			offer = _pick_item(tier, items, loadout)
		if offer == null:
			offer = _pick_weapon(mini(tier, WeaponLoadout.MAX_TIER), loadout)
		if offer == null:
			# A full build and exhausted item pool are not a sold offer. Show a
			# weapon the player can inspect/reserve and buy after making room.
			offer = _pick_weapon(mini(tier, WeaponLoadout.MAX_TIER), loadout, true)
		if offer != null:
			offer = offer.duplicate() as ShopOfferData
			if offer.weapon_data != null:
				offer.weapon_data = WeaponRolls.resolve(offer.weapon_data, WeaponRolls.roll(wave_number, luck, rng))
			offer.price = EconomyRules.shop_price(offer.price, wave_number)
		offers[index] = offer


func _pick_item(tier: int, items: ItemInventory, loadout: WeaponLoadout) -> ShopOfferData:
	var wanted_tags: Array[StringName] = []
	if items != null: wanted_tags = items.preferred_tags(loadout)
	for candidate_tier in range(tier, 0, -1):
		var pool: Array[ShopOfferData] = []
		var tagged: Array[ShopOfferData] = []
		for template in ItemCatalog.ALL:
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


func _pick_weapon(tier: int, loadout: WeaponLoadout, allow_unavailable: bool = false) -> ShopOfferData:
	var candidates: Array[ShopOfferData] = []
	for template in WEAPON_OFFERS:
		if template.weapon_data != null and (allow_unavailable or loadout.can_acquire(template.weapon_data, tier)) and not _already_offered(template.id, tier):
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


func save_state() -> Dictionary:
	var offer_data: Array[Dictionary] = []
	for index in offers.size():
		var offer: ShopOfferData = offers[index]
		offer_data.append({"id": str(offer.id), "tier": offer.weapon_tier, "rolls": offer.weapon_data.rolls.duplicate(true) if offer.weapon_data != null else {}, "price": offer.price, "reserved": reserved[index]} if offer != null else {})
	return {"offers": offer_data, "reroll_cost": reroll_cost, "shop_rerolls": rerolls}


func restore_state(saved: Dictionary, wave_number: int) -> void:
	reroll_cost = maxi(int(saved.get("reroll_cost", 2)), 2)
	reroll_step = EndlessRules.shop_reroll_step(wave_number)
	# Honor an already displayed legacy quote, then continue the new curve.
	rerolls = clampi(int(saved.get("shop_rerolls", maxi((reroll_cost - EndlessRules.shop_reroll_start(wave_number)) / reroll_step, 0))), 0, 10000)
	offers.clear()
	reserved = [false, false, false, false]
	for value in saved.get("offers", []):
		var offer_id := str(value.get("id", "")) if value is Dictionary else str(value)
		if offer_id == "floss":
			offer_id = "floss_whip"
		elif offer_id == "drill":
			offer_id = "turbo_drill"
		var template := ShopController.by_id(StringName(offer_id))
		var found: ShopOfferData = null
		if template != null:
			if template.weapon_data != null and value is Dictionary:
				found = ShopController.weapon_offer(template, int(value.get("tier", 1)))
				found.weapon_data = WeaponRolls.resolve(template.weapon_data, value.get("rolls", {}))
			else:
				found = template.duplicate() as ShopOfferData
			if value is Dictionary:
				found.price = maxi(int(value.get("price", found.price)), 1)
		if offers.size() >= ShopController.OFFER_COUNT:
			break
		reserved[offers.size()] = found != null and value is Dictionary and bool(value.get("reserved", false))
		offers.append(found)
