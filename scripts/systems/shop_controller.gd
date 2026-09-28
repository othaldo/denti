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
	preload("res://data/weapons/shop_magic_toothbrush.tres"),
	preload("res://data/weapons/shop_turbo_drill.tres"),
	preload("res://data/weapons/shop_floss_whip.tres"),
	preload("res://data/weapons/shop_water_jet.tres"),
	preload("res://data/weapons/shop_crown_launcher.tres"),
	preload("res://data/weapons/shop_enamel_mirror.tres"),
	preload("res://data/weapons/shop_plaque_scaler.tres"),
	preload("res://data/weapons/shop_mouthwash_mortar.tres"),
]

var offers: Array[ShopOfferData] = []
var reroll_cost: int = 2


func open_shop() -> void:
	reroll_cost = 2
	_roll_offers()


func reroll() -> void:
	_roll_offers()
	reroll_cost += 1


func take_offer(index: int) -> ShopOfferData:
	var offer := offers[index]
	offers[index] = null
	return offer


func _roll_offers() -> void:
	var pool: Array[ShopOfferData] = CATALOG.duplicate()
	pool.shuffle()
	offers.clear()
	for index in mini(3, pool.size()):
		offers.append(pool[index])
