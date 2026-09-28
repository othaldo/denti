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
	preload("res://data/weapons/floss.tres"),
	preload("res://data/weapons/drill.tres"),
]

var offers: Array[ShopOfferData] = []
var reroll_cost: int = 2


func open_shop(owned_weapon_ids: Array[StringName]) -> void:
	reroll_cost = 2
	_roll_offers(owned_weapon_ids)


func reroll(owned_weapon_ids: Array[StringName]) -> void:
	_roll_offers(owned_weapon_ids)
	reroll_cost += 1


func take_offer(index: int) -> ShopOfferData:
	var offer := offers[index]
	offers[index] = null
	return offer


func _roll_offers(owned_weapon_ids: Array[StringName]) -> void:
	var pool: Array[ShopOfferData] = []
	for offer in CATALOG:
		if offer.weapon_scene == null or not owned_weapon_ids.has(offer.id):
			pool.append(offer)
	pool.shuffle()
	offers.clear()
	for index in mini(3, pool.size()):
		offers.append(pool[index])
