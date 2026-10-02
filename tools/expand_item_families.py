"""Author the rarity expansion as ordinary editable Godot resources.

Run once for a new batch; runtime loads .tres files, never this script.
Existing item IDs, effects and artwork remain compatible with saved runs.
"""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
NEW = []
FAMILIES = []


def family(key, label, original, cap, tags, variants):
    FAMILIES.append((key, label, original, cap))
    path = ROOT / f"data/items/{original}.tres"
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'\nfamily_id = [^\n]*\nfamily_limit = [^\n]*\n?', '\n', text)
    text += f'\nfamily_id = &"{key}"\nfamily_limit = {cap}\n'
    path.write_text(text, encoding="utf-8")
    for tier, name, stats, effect, value, description, motif in variants:
        NEW.append(dict(id=f"{key}_{tier}", family=key, tier=tier, name=name,
                        stats=stats, effect=effect, value=value, description=description,
                        cap=cap, tags=tags, motif=motif))


family("health", "Schmelz / HP", "ceramic_shell", 3, ["defense", "sustain", "area"], [
    (1, "Schmelzsplitter", {"max_health": 12, "speed_bonus": -2}, "", 0, "+12 Leben, -2 % Bewegung.", "ivory enamel chip with pink heart"),
    (2, "Porzellanpolster", {"max_health": 24, "regen": 1, "attack_speed": -3}, "", 0, "+24 Leben, +1 Regeneration, -3 % Angriffstempo.", "porcelain tooth cap with pink cushion"),
    (4, "Herzkeramik", {"max_health": 45, "speed_bonus": -5}, "thorns", 24, "+45 Leben, -5 % Bewegung. Bei Schaden: 24 Splitterschaden im Umkreis.", "ornate ivory dental shell with ruby heart"),
])
family("armor", "Härte / Rüstung", "metal_crown", 6, ["defense", "shield", "area"], [
    (2, "Titankrone", {"armor": 4, "attack_speed": -4}, "", 0, "+4 Härte, -4 % Angriffstempo.", "titanium tooth crown with blue rivet"),
    (3, "Panzerkeramik", {"armor": 5, "max_health": 12, "speed_bonus": -6}, "", 0, "+5 Härte, +12 Leben, -6 % Bewegung.", "blue ceramic tooth armor cap"),
    (4, "Bollwerkkrone", {"armor": 6, "damage_bonus": -8}, "shield_shards", 12, "+6 Härte, -8 % Schaden. Schildblock: 12 Splitterschaden im Umkreis.", "gold armored molar cap with turquoise gem"),
])
family("damage", "Bisskraft / Bossjagd", "implant", 2, ["boss", "melee", "risk"], [
    (1, "Bissschraube", {"damage_bonus": 5, "max_health": -5}, "", 0, "+5 % Schaden, -5 Leben.", "small steel dental screw"),
    (2, "Titanstift", {"damage_bonus": 8, "regen": -1}, "boss_bonus", .08, "+8 % Schaden, +8 % gegen Bosse, -1 Regeneration.", "sturdy titanium dental implant"),
    (3, "Wurzelanker", {"damage_bonus": 10, "speed_bonus": -4}, "boss_bonus", .16, "+10 % Schaden, +16 % gegen Bosse, -4 % Bewegung.", "gold reinforced dental implant with violet ring"),
])
family("tempo", "Putzeifer / Spritzer", "mouthwash", 3, ["ranged", "area"], [
    (2, "Druckspülung", {"attack_speed": 14, "max_health": -8}, "splash", .28, "+14 % Angriffstempo, -8 Leben. Fern-Treffer: 28 % Spritzschaden.", "pressurized turquoise mouthwash flask"),
    (3, "Turbospülung", {"attack_speed": 18, "armor": -2}, "splash", .32, "+18 % Angriffstempo, -2 Härte. Fern-Treffer: 32 % Spritzschaden.", "turquoise mouthwash bottle with silver turbo valve"),
    (4, "Orkanspülung", {"attack_speed": 22, "damage_bonus": -8}, "splash", .40, "+22 % Angriffstempo, -8 % Schaden. Fern-Treffer: 40 % Spritzschaden.", "gold turquoise mouthwash decanter"),
])
family("crit", "Glanz / Krit", "polish_paste", 3, ["crit", "area"], [
    (1, "Glanzpuder", {"crit_chance": .04, "max_health": -5}, "crit_burst", .15, "+4 % Krit, -5 Leben. Krits: Blitz mit 15 % Trefferschaden.", "ivory polishing paste tin with star"),
    (3, "Diamantpaste", {"crit_chance": .10, "attack_speed": -5}, "crit_burst", .45, "+10 % Krit, -5 % Angriffstempo. Krits: Blitz mit 45 % Trefferschaden.", "violet diamond polishing cream tube"),
    (4, "Sternpolitur", {"crit_chance": .12, "armor": -2}, "crit_burst", .55, "+12 % Krit, -2 Härte. Krits: Blitz mit 55 % Trefferschaden.", "gold polishing paste jar with crystal star"),
])
family("regen", "Speichel / Regeneration", "saliva_fountain", 3, ["sustain", "healing"], [
    (1, "Speicheltropfen", {"regen": 1, "damage_bonus": -3}, "kill_heal", 1, "+1 Regeneration, -3 % Schaden. Alle 8 normalen Kills: +1 Leben.", "blue saliva droplet in a spoon"),
    (3, "Speichelbrunnen", {"regen": 4, "max_health": -10}, "kill_heal", 4, "+4 Regeneration, -10 Leben. Alle 8 normalen Kills: +4 Leben.", "blue saliva fountain with ivory basin"),
    (4, "Speicheloase", {"regen": 6, "attack_speed": -6}, "kill_heal", 6, "+6 Regeneration, -6 % Angriffstempo. Alle 8 normalen Kills: +6 Leben.", "gold saliva fountain with turquoise pool"),
])
family("mobility", "Bewegung / Beutemagnet", "mint_essence", 3, ["mobility", "economy", "risk"], [
    (2, "Minzsohlen", {"speed_bonus": 7, "armor": -1}, "magnet", 65, "+7 % Bewegung, -1 Härte. +65 Beutereichweite.", "mint leaf slippers with turquoise soles"),
    (3, "Mentholwirbel", {"speed_bonus": 9, "max_health": -12}, "magnet", 80, "+9 % Bewegung, -12 Leben. +80 Beutereichweite.", "mint essence bottle wrapped in whirlwind"),
    (4, "Minzkomet", {"speed_bonus": 12, "damage_bonus": -6}, "magnet", 100, "+12 % Bewegung, -6 % Schaden. +100 Beutereichweite.", "mint green comet with tooth charm"),
])
family("luck", "Zahnglück / XP", "lucky_molar", 3, ["luck", "economy"], [
    (1, "Milchzahn-Talisman", {"luck": 8, "damage_bonus": -2}, "xp_bonus", .04, "+8 Glück, -2 % Schaden. +4 % gesammelte XP.", "small milk tooth charm with clover"),
    (3, "Kleeblattkrone", {"luck": 28, "armor": -2}, "xp_bonus", .14, "+28 Glück, -2 Härte. +14 % gesammelte XP.", "gold tooth crown with emerald clover"),
    (4, "Schicksalsmolar", {"luck": 36, "attack_speed": -6}, "xp_bonus", .18, "+36 Glück, -6 % Angriffstempo. +18 % gesammelte XP.", "ivory lucky molar with violet dice"),
])
family("bleed", "Schnitt / Blutung", "floss_reel", 3, ["melee", "bleed"], [
    (2, "Rasierseide", {"melee_damage": 3, "armor": -1}, "bleed", 4, "+3 Nahschaden, -1 Härte. Schnitt-Blutung: +4 Schaden/s.", "red edged dental floss spool"),
    (3, "Rubinseide", {"melee_damage": 4, "attack_speed": -5}, "bleed", 5, "+4 Nahschaden, -5 % Angriffstempo. Schnitt-Blutung: +5 Schaden/s.", "ruby dental floss reel with droplet"),
    (4, "Henkerseide", {"melee_damage": 6, "max_health": -15}, "bleed", 7, "+6 Nahschaden, -15 Leben. Schnitt-Blutung: +7 Schaden/s.", "gold bladed dental floss spool"),
])
family("chain", "Wasser / Licht / Ketten", "radiant_filling", 3, ["ranged", "area"], [
    (1, "Funkenclip", {"damage_bonus": -2}, "chain", .20, "Wasser/Licht springt mit 20 % Trefferschaden auf ein nahes Ziel. -2 % Schaden.", "small dental electric clip with blue spark"),
    (3, "Gewittersonde", {"ranged_damage": 2, "armor": -2}, "chain", .50, "+2 Fernschaden, -2 Härte. Wasser/Licht springt mit 50 % Schaden über.", "silver dental probe with lightning coil"),
    (4, "Blitzableiter", {"ranged_damage": 3, "attack_speed": -6}, "chain", .60, "+3 Fernschaden, -6 % Angriffstempo. Wasser/Licht springt mit 60 % Schaden über.", "gold dental lightning rod with blue crystal"),
])
family("shield", "Schilde / Schutz", "fluoride_gel", 3, ["defense", "sustain", "shield"], [
    (2, "Fluoridmantel", {"max_health": 28, "speed_bonus": -3}, "wave_shield", 1, "+28 Leben, -3 % Bewegung. Wellenbeginn: +1 Schild.", "turquoise fluoride tube with protective cape"),
    (3, "Fluoridpanzer", {"max_health": 30, "armor": -1}, "wave_shield", 2, "+30 Leben, -1 Härte. Wellenbeginn: +2 Schilde (gesamt max. 5).", "armored fluoride gel tube with shield"),
    (4, "Fluoridbastion", {"max_health": 35, "attack_speed": -6}, "wave_shield", 2, "+35 Leben, -6 % Angriffstempo. Wellenbeginn: +2 Schilde (gesamt max. 5).", "gold fluoride vial inside turquoise shield"),
])
family("coins", "Münzen / Economy", "gold_filling", 3, ["economy", "luck", "defense"], [
    (1, "Kupferfüllung", {"luck": 3, "max_health": -5}, "coin_bonus", .05, "+3 Glück, -5 Leben. +5 % Münzen beim Sammeln.", "copper dental filling with coin"),
    (2, "Silberfüllung", {"armor": 1, "speed_bonus": -3}, "coin_bonus", .10, "+1 Härte, -3 % Bewegung. +10 % Münzen beim Sammeln.", "silver dental filling with coin stack"),
    (4, "Platinfüllung", {"luck": 12, "damage_bonus": -6}, "coin_bonus", .22, "+12 Glück, -6 % Schaden. +22 % Münzen beim Sammeln.", "platinum tooth filling with gold coins"),
])
family("return", "Projektile / Rücklauf", "return_drill", 2, ["ranged", "projectile"], [
    (1, "Rückholfeder", {"ranged_damage": 1, "damage_bonus": -3}, "projectile_return", .15, "+1 Fernschaden, -3 % Schaden. Direkte Projektile kehren mit 15 % Schaden zurück.", "dental spring with turquoise return arrow"),
    (2, "Rücklaufspindel", {"ranged_damage": 2, "attack_speed": -4}, "projectile_return", .25, "+2 Fernschaden, -4 % Angriffstempo. Direkte Projektile kehren mit 25 % Schaden zurück.", "silver dental spindle with blue circular arrow"),
    (4, "Bumerangbohrer", {"ranged_damage": 3, "armor": -2}, "projectile_return", .50, "+3 Fernschaden, -2 Härte. Direkte Projektile kehren mit 50 % Schaden zurück (gesamt max. 70 %).", "gold boomerang dental drill with turquoise arrow"),
])
family("burst", "Fläche / Zahnblitz", "holy_flash", 2, ["area", "crit"], [
    (1, "Blitzampulle", {"crit_chance": .02, "regen": -1}, "kill_burst", 10, "+2 % Krit, -1 Regeneration. Alle 10 normalen Kills: Zahnblitz mit 10 Basisschaden.", "small turquoise ampoule with golden spark"),
    (2, "Zahnblitzflasche", {"crit_chance": .03, "speed_bonus": -3}, "kill_burst", 18, "+3 % Krit, -3 % Bewegung. Alle 10 normalen Kills: Zahnblitz mit 18 Basisschaden.", "ivory lightning potion bottle with tooth seal"),
    (4, "Heilige Nova", {"crit_chance": .05, "max_health": -15}, "kill_burst", 36, "+5 % Krit, -15 Leben. Alle 10 normalen Kills: Zahnblitz mit 36 Basisschaden.", "gold elixir decanter with radiant tooth nova"),
])
family("sugar", "Zucker / Bewegungsschaden", "forbidden_lollipop", 2, ["mobility", "risk"], [
    (1, "Zuckerwürfel", {"max_health": -6}, "moving_damage", .08, "Beim tatsächlichen Laufen: +8 % Waffenschaden. -6 Leben.", "pink sugar cube with tooth bite"),
    (2, "Kariesbonbon", {"armor": -1, "regen": -1}, "moving_damage", .14, "Beim tatsächlichen Laufen: +14 % Waffenschaden. -1 Härte, -1 Regeneration.", "pink striped candy with dental crack"),
    (4, "Sündenlolli", {"max_health": -20, "armor": -3}, "moving_damage", .28, "Beim tatsächlichen Laufen: +28 % Waffenschaden (gesamt max. 40 %). -20 Leben, -3 Härte.", "ornate forbidden golden pink lollipop"),
])
family("xp_heal", "XP / Heilung", "tooth_fairy_pact", 2, ["sustain", "economy", "healing"], [
    (1, "Feenquittung", {"damage_bonus": -3}, "xp_heal", .15, "Jeder gesammelte XP-Punkt heilt 0,15 Leben. -3 % Schaden.", "small fairy receipt scroll with tooth wax seal"),
    (3, "Feenvertrag", {"armor": -2}, "xp_heal", .45, "Jeder gesammelte XP-Punkt heilt 0,45 Leben. -2 Härte.", "violet fairy contract with glowing saliva droplet"),
    (4, "Feenbund", {"max_health": -15, "attack_speed": -4}, "xp_heal", .60, "Jeder gesammelte XP-Punkt heilt 0,6 Leben. -15 Leben, -4 % Angriffstempo.", "gold fairy pact scroll with turquoise heart seal"),
])

MYTHICS = [
    ("mythic_heart", "Herz des Urmolars", "max_health", 60, ["defense", "sustain"], "winged ivory molar heart with rose gemstone"),
    ("mythic_armor", "Unvergänglicher Schmelz", "armor", 8, ["defense", "shield"], "iridescent ivory tooth armor with halo"),
    ("mythic_bite", "Biss der Zahnheit", "damage_bonus", 20, ["melee", "ranged"], "golden divine molar fang emblem"),
    ("mythic_tempo", "Ewiger Putzeifer", "attack_speed", 30, ["melee", "ranged"], "celestial turquoise dental hourglass with brush"),
    ("mythic_crit", "Makelloser Glanz", "crit_chance", .18, ["crit", "area"], "radiant iridescent diamond on ivory tooth pedestal"),
    ("mythic_regen", "Quelle des Lebens", "regen", 8, ["sustain", "healing"], "divine turquoise saliva spring with golden halo"),
    ("mythic_speed", "Schritte der Zahnfee", "speed_bonus", 18, ["mobility", "risk"], "winged mint slippers with gold tooth clasp"),
    ("mythic_luck", "Zahnfee-Stern", "luck", 50, ["luck", "economy"], "golden fairy star with emerald tooth clover"),
]
LABELS = {"max_health": "Leben", "armor": "Härte", "damage_bonus": "% Schaden", "attack_speed": "% Angriffstempo",
          "crit_chance": "% Krit", "regen": "Regeneration", "speed_bonus": "% Bewegung", "luck": "Glück"}
for ident, name, stat, value, tags, motif in MYTHICS:
    shown = round(value * 100) if stat == "crit_chance" else value
    NEW.append(dict(id=ident, family="", tier=5, name=name, stats={stat: value}, effect="", value=0,
                    description=f"+{shown} {LABELS[stat]}. Einmalig pro Run. Ohne Nachteil.", cap=1, tags=tags, motif=motif))

for index, item in enumerate(NEW):
    item["description"] = item["description"].replace("Fern-Treffer", "Fern-Projektile")
    stats = ", ".join(f'&"{key}": {float(value)}' for key, value in item["stats"].items())
    tags = ", ".join(f'&"{tag}"' for tag in item["tags"])
    text = '\n'.join([
        '[gd_resource type="Resource" script_class="ShopOfferData" load_steps=2 format=3]',
        '[ext_resource type="Script" path="res://scripts/systems/shop_offer_data.gd" id="1"]',
        '[resource]', 'script = ExtResource("1")', f'id = &"{item["id"]}"',
        f'display_name = "{item["name"]}"', f'description = "{item["description"]}"',
        f'rarity_tier = {item["tier"]}', f'price = {[5, 9, 14, 22, 38][item["tier"] - 1]}',
        f'icon_index = {30 + index}', 'stat_changes = { ' + stats + ' }',
        f'effect_kind = &"{item["effect"]}"', f'effect_value = {float(item["value"])}',
        f'max_stacks = {item["cap"]}', f'family_id = &"{item["family"]}"',
        f'family_limit = {item["cap"] if item["family"] else 0}',
        f'tags = Array[StringName]([{tags}])', '',
    ])
    (ROOT / f'data/items/{item["id"]}.tres').write_text(text, encoding="utf-8")

controller = ROOT / "scripts/systems/shop_controller.gd"
text = controller.read_text(encoding="utf-8")
insert = ''.join(f'\tpreload("res://data/items/{item["id"]}.tres"),\n' for item in NEW)
for item in NEW:
    text = text.replace(f'\tpreload("res://data/items/{item["id"]}.tres"),\n', '')
text = text.replace('\tpreload("res://data/weapons/shop_magic_toothbrush.tres"),', insert + '\tpreload("res://data/weapons/shop_magic_toothbrush.tres"),')
controller.write_text(text, encoding="utf-8")
(ROOT / "docs/item_icon_manifest.json").write_text(json.dumps(NEW, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Added {len(NEW)} resources across {len(FAMILIES)} families and {len(MYTHICS)} mythics.")
