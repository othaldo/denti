class_name ShopViewData
extends RefCounted

# Display-only data is assembled once, independent of the shop scene tree.
var wave_number: int = 0
var coins: int = 0
var reroll_cost: int = 0
var offers: Array[ShopOfferData] = []
var equipment: Array[Dictionary] = []
var used_slots: int = 0
var capacity: int = WeaponLoadout.CAPACITY
var buyable: Array[bool] = []
var luck: float = 0.0
var collected: Array[Dictionary] = []
var counts: Dictionary = {}
var offer_dps: Array[float] = []
var reserved: Array[bool] = []
