"""Regenerate the complete item tables from the gameplay resources."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
FAMILIES = [
    ("health", "Schmelz / HP"), ("armor", "Härte / Rüstung"), ("damage", "Bisskraft / Bossjagd"),
    ("tempo", "Putzeifer / Spritzer"), ("crit", "Glanz / Krit"), ("regen", "Speichel / Regeneration"),
    ("mobility", "Bewegung / Beutemagnet"), ("luck", "Zahnglück / XP"), ("bleed", "Schnitt / Blutung"),
    ("chain", "Wasser / Licht / Ketten"), ("shield", "Schilde / Schutz"), ("coins", "Münzen / Economy"),
    ("return", "Projektile / Rücklauf"), ("burst", "Fläche / Zahnblitz"), ("sugar", "Zucker / Bewegungsschaden"),
    ("xp_heal", "XP / Heilung"), ("dodge", "Zahnflutsch / Ausweichen"),
]
TIERS = ["Common", "Uncommon", "Rare", "Legendary", "Mythic"]


def read_item(path):
    text = path.read_text(encoding="utf-8")
    def field(key, default=""):
        match = re.search(rf'^{key} = &?"?([^\n"]*)', text, re.M)
        return match.group(1).strip() if match else default
    return dict(id=field("id"), name=field("display_name"), description=field("description"),
                tier=int(field("rarity_tier", "1")), price=int(field("price", "3")),
                cap=int(field("max_stacks", "0")), family=field("family_id"),
                family_limit=int(field("family_limit", "0")))


items = [read_item(path) for path in (ROOT / "data/items").glob("*.tres")]
assert len(items) == 93
path = ROOT / "docs/items.md"
old = path.read_text(encoding="utf-8")
tail = old[old.index("Peitsche und Kratzer"):]
out = ["# Items und Builds", "",
       "Die Zahnklinik bietet **93 Items**: 17 Familien mit je vier Seltenheiten, 16 ergänzende Spezialitems und neun einmalige Mythics. Alle ursprünglichen 32 Items behalten ihre IDs, Effekte und Icons; 61 neue Items ergänzen den Pool. [Zahnflutsch: Ausweichen und fünf neue Items](DODGE.md).", "",
       "**Common / Gewöhnlich**, **Uncommon / Ungewöhnlich**, **Rare / Selten** und **Legendary / Legendär** bieten verschiedene Kombinationen aus Bonus, Synergie und Nachteil. Seltenere Varianten sind eigene Items: Sie ersetzen vorhandene Exemplare nicht und fusionieren nicht. Das **Familienlimit gilt über alle vier Seltenheiten zusammen**; unterschiedliche Familien und Spezialitems ergänzen sich weiterhin. Bereits gespeicherte Builds behalten ihren Besitz, auch oberhalb eines neuen Familienlimits; dann sind weitere Käufe dieser Familie gesperrt. Die bisher unbegrenzte Metallkrone teilt jetzt das Rüstungs-Familienlimit von sechs.", "",
       "**Mythic / Mythisch** ist eine neue, pink markierte Itemstufe. Jedes Mythic ist höchstens einmal pro Run erhältlich und gewährt genau einen positiven Statbonus ohne Nachteil oder zusätzlichen Proc. Die Stufe kann ab Welle 12 in Itemangeboten und Kisten erscheinen: `min((Welle - 11) × 0,00035 × max(1 + Glück/100, 0), 0,01)`, vorher 0. Das sind auf Welle 20 ohne Glück 0,315 % je Itemwurf, maximal 1 %. Waffen und Level-ups bleiben auf Stufe I–IV. Ein erschöpfter seltener Pool fällt auf verfügbare niedrigere Stufen zurück; besessene Mythics werden nicht erneut angeboten.", "",
       "Ein Kauf gewährt den Effekt sofort. Alle Preise unten sind **Basispreise vor der Welleninflation**. Shopangebote haben vier Plätze; „Merken“ bindet Angebot und Preis kostenlos über Rerolls und Wellen. Details: [Economy](ECONOMY_BALANCE.md). Itemangebote werden zu 28 % aus passenden Build-Tags gewählt, wenn solche Items in der gewürfelten Stufe vorhanden sind. Das ändert die Seltenheitschance nicht.", "",
       "Bisskraft und Item-Prozentboni werden addiert; Folgeeffekte skalieren einen bereits berechneten Treffer nicht erneut. Proc-Abklingzeiten und vorhandene Obergrenzen bleiben bestehen. Details: [Schaden und Verteidigung](DAMAGE_DEFENSE_BALANCE.md). Die Werte dieser Erweiterung sind ein Ausgangspunkt für Playtests, keine gemessene finale Balance.", "",
       "Die [Designnotizen mit Brotato-Recherche](ITEM_RARITY_EXPANSION.md) erklären Auswahl und Limits. Die [Attributübersicht](ATTRIBUTES.md) definiert die einheitlichen Namen: Härte ist Rüstung, Schmelz sind maximale HP. Die Tabellen geben die Ressourcentexte wieder; im Spiel werden deren ältere Bezeichnungen zentral aufgelöst. [Alle 56 neuen Icons in Kartengröße](screenshots/item_families_icons_48px.png).", ""]
for family, label in FAMILIES:
    members = sorted((item for item in items if item["family"] == family), key=lambda item: item["tier"])
    assert [item["tier"] for item in members] == [1, 2, 3, 4]
    out += [f'## {label}', "", f'Gemeinsames Familienlimit: **{members[0]["family_limit"]}**.', "",
            "| Seltenheit | Item | Vollständiger Effekt | Basispreis |", "| --- | --- | --- | ---: |"]
    for item in members:
        out.append(f'| {TIERS[item["tier"] - 1]} | {item["name"]} | {item["description"]} | {item["price"]} |')
    out.append("")
out += ["## Spezialitems", "", "Diese 16 bisherigen Items ergänzen die Familien mit eigenen Regeln. Ihre Stapellimits gelten je Item.", "",
        "| Item | Seltenheit | Effekt | Max. | Basispreis |", "| --- | --- | --- | ---: | ---: |"]
for item in sorted((i for i in items if not i["family"] and i["tier"] < 5), key=lambda i: (i["tier"], i["name"])):
    out.append(f'| {item["name"]} | {TIERS[item["tier"] - 1]} | {item["description"]} | {item["cap"] or "unbegrenzt"} | {item["price"]} |')
out += ["", "## Mythics", "", "Je Item einmal pro Run. Keine negativen Stats, keine zusätzlichen Nebeneffekte.", "",
        "| Item | Reiner Bonus | Basispreis |", "| --- | --- | ---: |"]
for item in sorted((i for i in items if i["tier"] == 5), key=lambda i: i["name"]):
    out.append(f'| {item["name"]} | {item["description"]} | {item["price"]} |')
out += ["", "## Effekte und Beispielbuilds", "", tail]
path.write_text("\n".join(out), encoding="utf-8")
readme = ROOT / "README.md"
text = re.sub(r"18 Waffen und \d+ Shop-Items", "18 Waffen und 93 Shop-Items", readme.read_text(encoding="utf-8"))
text = re.sub(r"(?: Items bieten 16 Familien von Common bis Legendary und acht einmalige Mythics ohne Nachteil; Varianten teilen ein Familienlimit\.)+", " Items bieten 17 Familien von Common bis Legendary und neun einmalige Mythics ohne Nachteil; Varianten teilen ein Familienlimit.", text)
text = text.replace("Levelaufstiege verbessern zehn Grundwerte.", "Levelaufstiege verbessern elf Grundwerte, einschließlich Zahnflutsch (Ausweichen).")
readme.write_text(text, encoding="utf-8")
print("Documented all 93 items from resources.")
