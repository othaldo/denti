"""Generate class and talent-tree resources for the roster classes.

Writes data/classes/<id>.tres and data/talents/<id>.tres for Zahnfee, Glutzahn,
Spültechniker and Frostwächter. Each tree has three branches of 18 grid cells
(6 rows x 3 columns): attributes and free roots, entry talents, the branch
skill in row 3, three skill modifiers in row 4 and a keystone in row 5.
Usage: python tools/generate_class_roster.py [class_id ...]
Without arguments every class is written; with ids only those.
Portraits and atlas indices are assigned here so regeneration preserves art.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLACEHOLDER_PORTRAIT = "res://assets/denti/denti_unarmed.png"
## Painted class portraits; until a file exists the placeholder is used.
PORTRAITS = {class_id: "assets/classes/%s_portrait.png" % class_id for class_id in ["tooth_fairy", "ember", "rinser", "frost_warden", "herb_druid"]}
## First DentiUIIcons.talent() index of each class atlas (8 columns x 3 rows,
## one row per branch, nodes left to right in tree order). The existing atlases
## reserve 32 + 15 + 14 cells, including Assassin's unused final cell.
ATLAS_COLUMNS = 8
ATLAS_BASE = {"tooth_fairy": 61, "ember": 85, "rinser": 109, "frost_warden": 133,
    # Kräuterzahn: own atlas loaded at runtime (DentiUIIcons.HERB_TALENT_FIRST).
    "herb_druid": 400}


def a(stat, ranks):
    return ("a", stat, ranks)


def f(ranks=5):
    return ("f", ranks)


def t(id, name, desc, ranks=1, effects=None, stats=None, parent=None, icon=-1):
    return ("t", id, name, desc, ranks, effects or {}, stats or {}, parent, icon)


def s(id, name, desc, effects, icon=-1):
    return ("s", id, name, desc, effects, icon)


def m(id, name, desc, effects, ranks=1, icon=-1):
    return ("m", id, name, desc, effects, ranks, icon)


def k(id, name, desc, effects=None, stats=None, icon=-1):
    return ("k", id, name, desc, effects or {}, stats or {}, icon)


CLASSES = {
    "tooth_fairy": {
        "name": "Zahnfee",
        "tagline": "Für jeden Zahn eine Münze: Jede eingesammelte Beute feuert einen Lichtsplitter.",
        "style": ["Jede eingesammelte Beute feuert einen Lichtsplitter auf den nächsten Gegner", "Glück und Münzen machen die Splitter stärker", "Kaum Beutemagnet, weniger Waffenschaden, nur 5 Wurzeln"],
        "description": "Die Zahnfee hat kaum Beutemagnet. Jede Beute, die sie im Kampf einsammelt, feuert einen Lichtsplitter auf den nächsten Gegner; Glück verstärkt ihn, Glanz lässt ihn kritisch treffen. Ihr Dash ist ein langer Gleitflug.",
        "roots": 5,
        "starting": {"damage_bonus": -15.0, "luck": 10.0},
        "tags": ["economy", "luck", "crit"],
        "dash": {"capacity": 100.0, "cost": 100.0, "distance": 230.0, "duration": 0.3},
        "branches": ["Glanz", "Schatzkammer", "Kissen"],
        "tree": [
            [a("crit_chance", 4), t("fairy_cut", "Splitterschliff", "Lichtsplitter (beim Einsammeln von Beute) +4 Schaden je Rang.", 3, {"fairy_shard": 4}), a("damage_bonus", 6),
             a("luck", 6), t("fairy_bounce", "Lichtbrechung", "Jeder Splitter springt auf einen zweiten Gegner über (60 % Schaden).", 1, {"fairy_pierce": 1}, parent="fairy_cut"), a("attack_speed", 4),
             f(), a("crit_chance", 3), f(),
             f(), s("fairy_stardust", "Feenstaub", "Jede 20. eingesammelte Beute lässt Licht auf bis zu zwölf Gegner regnen, mit dreifachem Splitterschaden.", {"skill_stardust": 1}), a("ranged_damage", 6),
             m("stardust_fast", "Sternschnuppe", "Feenstaub schon bei jeder 15. Beute.", {"stardust_every": 5}), m("stardust_halo", "Heiligenschein", "Feenstaub heilt 5 Leben.", {"stardust_heal": 1}), m("stardust_spark", "Funkelzauber", "Feenstaub trifft immer kritisch.", {"stardust_crit": 1}),
             f(), k("fairy_glitter", "Glitzerwahn", "Splitter verursachen 50 % mehr Schaden, Waffen 10 % weniger.", {"fairy_glitter": 1}, {"damage_bonus": -10}), f()],
            [a("luck", 8), t("fairy_jingle", "Klimpergeld", "Eingesammelte Münzen feuern zwei Splitter.", 1, {"fairy_coin_double": 1}), a("speed_bonus", 6),
             a("dodge_chance", 4), t("fairy_savings", "Sparschwein", "+5 % Münzen beim Einsammeln je Rang.", 3, {"coin_bonus": 0.05}), a("max_health", 8),
             f(), a("luck", 6), f(),
             f(), s("fairy_bounty", "Kopfgeld", "Treffer an Eliten und Bossen werfen alle 3 s eine kleine Münze ab, höchstens 15 je Welle.", {"skill_bounty": 1}), a("damage_bonus", 6),
             m("bounty_gold", "Goldene Zähne", "Kopfgeld-Münzen feuern drei Splitter.", {"bounty_gold": 1}), m("bounty_fast", "Glückspilz", "Kopfgeld schon alle 2 s.", {"bounty_rate": 1}), m("bounty_sock", "Sparstrumpf", "Bis zu 10 Kopfgeld-Münzen mehr je Welle.", {"bounty_cap": 10}),
             f(), k("fairy_greed", "Habgier", "Noch kleinerer Beutemagnet, +30 Glück.", {"fairy_greed": 1}, {"luck": 30}), f()],
            [a("max_health", 15), t("fairy_down", "Daunenfedern", "Zu Wellenbeginn 1 Schild.", 1, {"wave_shield": 1}), a("armor", 15),
             a("regen", 15), t("fairy_dreams", "Süße Träume", "Eingesammelte XP heilen dich etwas. Je Rang.", 2, {"xp_heal": 0.15}), f(),
             f(), a("dodge_chance", 5), f(),
             a("dash_recovery_bonus", 6), s("fairy_pillow", "Zahnkissen", "Jede 25. eingesammelte Beute gibt 1 Schild.", {"skill_pillow": 1}), f(),
             m("pillow_feather", "Federbett", "Zahnkissen schon bei jeder 15. Beute.", {"pillow_feather": 1}), m("pillow_sleep", "Sanfter Schlaf", "Eingesammelte XP heilen zusätzlich.", {"xp_heal": 0.2}), m("pillow_guard", "Nachtwache", "Ein Zahnkissen-Schild stößt nahe Gegner weg.", {"pillow_guard": 1}),
             f(), k("fairy_sleepwalk", "Schlafwandler", "Der Gleitflug reicht 50 % weiter, −20 Schmelz.", {"dash_distance": 115}, {"max_health": -20}), f()],
        ],
    },
    "ember": {
        "name": "Glutzahn",
        "tagline": "Heiß gelaufen: Hitze aufbauen und mitten in der Horde ausbrechen.",
        "style": ["Treffer und nahe Gegner laden Hitze, bei voller Hitze bricht Feuer aus", "Je mehr Gegner um dich stehen, desto stärker der Ausbruch", "Danach kurz überhitzt; weniger Schmelz, schwache Fernwaffen"],
        "description": "Der Glutzahn lädt Hitze durch Treffer und Gedränge. Bei voller Hitze bricht eine Feuernova aus, die mit jedem nahen Gegner stärker wird. Danach greift er kurz langsamer an. Fernwaffen verursachen 20 % weniger Schaden.",
        "roots": 5,
        "starting": {"max_health": -15.0, "melee_damage": 2.0},
        "tags": ["melee", "area", "defense"],
        "branches": ["Esse", "Dampfkessel", "Hitzeschild"],
        "tree": [
            [a("melee_damage", 8), t("ember_tinder", "Zunder", "Hitze steigt 25 % schneller je Rang.", 2, {"ember_tinder": 1}), a("damage_bonus", 8),
             a("attack_speed", 4), t("ember_accel", "Brandbeschleuniger", "Ausbruch +25 % Schaden je Rang.", 3, {"ember_accelerant": 1}, parent="ember_tinder"), a("crit_chance", 3),
             f(), f(), f(),
             f(), s("ember_core", "Glutkern", "Ein Ausbruch hinterlässt 3 s brennenden Boden, der Gegner anzündet und dir Hitze gibt.", {"skill_core": 1}), a("melee_damage", 6),
             m("core_linger", "Nachglühen", "Glutkern brennt 2 s länger.", {"core_linger": 1}), m("core_sparks", "Funkenflug", "Ein Ausbruch schleudert Funken auf bis zu sechs Gegner.", {"core_sparks": 1}), m("core_forge", "Schmiedefeuer", "Im Glutkern +15 % Angriffstempo.", {"core_forge": 1}),
             f(), k("ember_wildfire", "Flächenbrand", "Ausbruch 50 % größer, Überhitzung 1.5 s länger.", {"ember_wildfire": 1}), f()],
            [a("speed_bonus", 6), t("ember_dashheat", "Kesseldruck", "Jeder Dash gibt Hitze. Je Rang.", 2, {"ember_dash_heat": 1}), a("dash_recovery_bonus", 6),
             a("dodge_chance", 4), t("ember_soles", "Heiße Sohlen", "+6 % Waffenschaden, während du dich bewegst. Je Rang.", 3, {"moving_damage": 0.06}), a("attack_speed", 4),
             f(), f(), f(),
             f(), s("ember_vent", "Druckablass", "Ein Dash bei mindestens halber Hitze löst sofort einen Ausbruch mit halber Kraft aus.", {"skill_vent": 1}), f(),
             m("vent_whistle", "Kesselpfeife", "Druckablass mit voller Kraft.", {"vent_whistle": 1}), m("vent_steam", "Volldampf", "Nach einem Druckablass kehrt etwas Wurzelkraft zurück.", {"vent_steam": 1}), m("vent_valve", "Sicherheitsventil", "Druckablass überhitzt nicht.", {"vent_valve": 1}),
             f(), k("ember_overpressure", "Überdruck", "Hitze steigt 50 % schneller, −15 Schmelz.", {"ember_overpressure": 1}, {"max_health": -15}), f()],
            [a("max_health", 15), t("ember_hide", "Hornhaut", "+2 Härte je Rang.", 3, stats={"armor": 2}), a("armor", 15),
             a("regen", 15), t("ember_cool", "Abkühlung", "Überhitzung 0.5 s kürzer je Rang.", 2, {"ember_cooling": 0.5}), f(),
             f(), a("dodge_chance", 4), f(),
             f(), s("ember_skin", "Glühende Haut", "Ab 60 % Hitze fangen Gegner, die dich berühren, Feuer.", {"skill_skin": 1}), f(),
             m("skin_asbestos", "Asbestschmelz", "Glühende Haut schon ab 40 % Hitze.", {"skin_asbestos": 1}), m("skin_slag", "Schlacke", "Glühende Haut heilt dich für jeden verbrannten Gegner etwas.", {"skin_slag": 1}), m("skin_thorns", "Glutdornen", "Wirst du getroffen, verbrennen Splitter nahe Gegner.", {"thorns": 8}),
             f(), k("ember_lava", "Lavakern", "+20 Schmelz, Hitze steigt 20 % langsamer.", {"ember_lava": 1}, {"max_health": 20}), f()],
        ],
    },
    "rinser": {
        "name": "Spültechniker",
        "tagline": "Erst wischen, dann zünden: Deine Laufspur macht nass, Strom folgt ihr.",
        "style": ["Lauf Schleifen: Gegner auf deiner Spur werden nass", "Treffer springen als Strom zu allen auf der Spur, der Dash lädt sie ganz auf", "Weniger Waffenschaden; wer stehen bleibt, hat keine Spur"],
        "description": "Der Spültechniker zieht beim Laufen eine kurze Spülspur. Gegner darauf sind nass; ein Waffentreffer auf einen von ihnen springt als Strom zu den anderen. Jeder Dash lädt die ganze Spur auf einmal auf.",
        "roots": 6,
        "starting": {"damage_bonus": -15.0},
        "tags": ["chain", "area", "ranged"],
        "branches": ["Leitung", "Spülung", "Wartung"],
        "tree": [
            [a("ranged_damage", 8), t("rinse_copper", "Kupferader", "Strom auf der Spur +10 % Schaden je Rang.", 3, {"rinse_copper": 1}), a("damage_bonus", 8),
             a("attack_speed", 4), t("rinse_conductor", "Mehrleiter", "Strom springt auf einen weiteren Gegner je Rang.", 2, {"rinse_conductor": 1}, parent="rinse_copper"), a("crit_chance", 3),
             f(), f(), f(),
             f(), s("rinse_short", "Kurzschluss", "Schließt deine Spur eine Schleife, entlädt sie sich zweimal in alles darin.", {"skill_short": 1}), a("ranged_damage", 6),
             m("short_power", "Starkstrom", "Kurzschluss +50 % Schaden.", {"short_power": 1}), m("short_rain", "Funkenregen", "Jeder Kurzschluss lädt auch die ganze Spur auf.", {"short_rain": 1}), m("short_ground", "Erdung", "Trifft ein Kurzschluss fünf Gegner, gibt er 1 Schild (alle 8 s).", {"short_ground": 1}),
             f(), k("rinse_pressure", "Hochdruck", "Spülstoß 50 % stärker, −20 Schmelz.", {"rinse_pressure": 1}, {"max_health": -20}), f()],
            [a("speed_bonus", 6), t("rinse_hose", "Langer Schlauch", "Längere Spur je Rang.", 2, {"rinse_hose": 1}), a("luck", 8),
             a("dodge_chance", 4), t("rinse_drip", "Tropfnass", "Die Spur bleibt 1.5 s länger je Rang.", 2, {"rinse_drip": 1}), a("dash_recovery_bonus", 6),
             f(), f(), f(),
             f(), s("rinse_flood", "Schwall", "Dein Dash schiebt nasse Gegner in Dashrichtung.", {"skill_flood": 1}), f(),
             m("flood_suction", "Sog", "Schwall zieht nasse Gegner zu dir, statt sie wegzuschieben.", {"flood_suction": 1}), m("flood_puddles", "Pfützenteppich", "Dein Dash hinterlässt Spülpfützen auf der Spur.", {"flood_puddles": 1}), m("flood_foam", "Schaumbad", "Gegner auf der Spur werden zusätzlich verlangsamt.", {"flood_foam": 1}),
             f(), k("rinse_mop", "Wischmop", "Die Spur wird viel länger, Waffen −10 % Schaden.", {"rinse_hose": 2}, {"damage_bonus": -10}), f()],
            [a("max_health", 15), t("rinse_scale", "Kalkschicht", "+2 Härte je Rang.", 3, stats={"armor": 2}), a("armor", 15),
             a("regen", 15), t("rinse_soothe", "Spülwasser", "+0.4 Speichel je Rang.", 3, stats={"regen": 0.4}), f(),
             f(), a("dodge_chance", 4), f(),
             f(), s("rinse_shower", "Notdusche", "Sinkt dein Leben unter ein Drittel, spült eine Welle Gegner und Geschosse weg und heilt dich, höchstens alle 20 s.", {"skill_shower": 1}), f(),
             m("shower_scale", "Kalkschutz", "Die Notdusche gibt 1 Schild.", {"shower_scale": 1}), m("shower_rinse", "Nachspülen", "Notdusche schon alle 12 s.", {"shower_rinse": 1}), m("shower_stone", "Tropfsteinschild", "Notdusche schon bei halbem Leben.", {"shower_stone": 1}),
             f(), k("rinse_seal", "Abdichtung", "Zu Wellenbeginn 2 Schilde, −15 % Bewegung.", {"wave_shield": 2}, {"speed_bonus": -15}), f()],
        ],
    },
    "frost_warden": {
        "name": "Frostwächter",
        "tagline": "Bis hierhin und nicht weiter: Dein Dash zieht eine Eiswand.",
        "style": ["Setz Eiswände quer zur Horde: Gegner stauen sich und kühlen aus", "Wer lange an der Wand steht, wird spröde", "Langsamer, nur ein Dash; Bosse brechen durch"],
        "description": "Der Frostwächter hinterlässt mit jedem Dash eine Eiswand. Gewöhnliche Gegner kommen nicht hindurch, stauen sich davor, werden verlangsamt und nach kurzer Zeit spröde. Bosse zerbrechen die Wand. Die Wand hält keine Geschosse auf.",
        "roots": 6,
        "starting": {"speed_bonus": -10.0, "armor": 2.0},
        "tags": ["defense", "shield", "area", "crit"],
        "dash": {"capacity": 100.0, "cost": 100.0, "distance": 150.0, "duration": 0.16, "recharge_rate": 18.0},
        "branches": ["Gletscher", "Bruch", "Wacht"],
        "tree": [
            [a("armor", 10), t("frost_thick", "Dicke Wand", "Eiswände halten 1 s länger je Rang.", 2, {"frost_thick": 1}), a("max_health", 10),
             a("dash_recovery_bonus", 6), t("frost_reach", "Weite Wand", "+20 % Dashweite und damit längere Eiswände je Rang.", 2, {"dash_distance": 30}), a("regen", 10),
             f(), t("frost_spikes", "Zackenwand", "Gegner an einer Eiswand nehmen laufend Schaden.", 1, {"wall_spikes": 1}), f(),
             f(), s("frost_wave", "Frostwelle", "Vergeht eine Eiswand, zerspringt sie in Eissplitter, die Gegner treffen und spröde machen.", {"skill_frostwave": 1}), f(),
             m("wall_lasting", "Dauerfrost", "Eiswände halten 1.5 s länger.", {"wall_lasting": 1}), m("wall_slide", "Rutschbahn", "Die Eiswand stößt Gegner ein Stück zurück.", {"wall_slide": 1}), m("wave_avalanche", "Lawine", "Doppelt so viele Eissplitter.", {"wave_avalanche": 1}),
             f(), k("frost_permafrost", "Permafrost", "Eiswände halten doppelt so lang, −10 % Bewegung.", {"frost_permafrost": 1}, {"speed_bonus": -10}), f()],
            [a("melee_damage", 8), t("frost_bite", "Kältebiss", "Gegner werden an einer Eiswand schneller spröde.", 1, {"frost_bite": 1}), a("damage_bonus", 8),
             a("crit_chance", 3), t("frost_pick", "Eispickel", "+2 Nahschaden je Rang.", 3, stats={"melee_damage": 2}), a("attack_speed", 4),
             f(), f(), f(),
             f(), s("frost_shatter", "Zerschmettern", "Ein Treffer auf einen spröden Gegner zerschmettert ihn: Zusatzschaden und Splitter auf zwei Nachbarn.", {"skill_shatter": 1}), t("frost_hammer", "Schwerer Hammer", "Zerschmettern +20 % Schaden je Rang.", 3, {"frost_hammer": 1}),
             m("shatter_chain", "Kettenbruch", "Splitter zerschmettern auch andere spröde Gegner.", {"shatter_chain": 1}), m("shatter_icicles", "Eiszapfen", "Zwei Splitter mehr.", {"shatter_icicles": 1}), m("shatter_shock", "Schockfrost", "Zerschmettern trifft kritisch.", {"shatter_shock": 1}),
             f(), k("frost_glass", "Glasschmelz", "+15 % Schaden, −20 Schmelz.", stats={"damage_bonus": 15, "max_health": -20}), f()],
            [a("max_health", 15), t("frost_layer", "Eisschicht", "+2 Härte je Rang.", 3, stats={"armor": 2}), a("armor", 15),
             a("regen", 15), t("frost_coat", "Frostmantel", "Zu Wellenbeginn 1 Schild.", 1, {"wave_shield": 1}), f(),
             f(), a("dodge_chance", 4), f(),
             f(), s("frost_armor", "Eispanzer", "Eine neue Eiswand gibt 1 Schild, höchstens alle 8 s.", {"skill_icearmor": 1}), f(),
             m("armor_rime", "Raureif", "Eispanzer schon alle 5 s.", {"armor_rime": 1}), m("armor_breath", "Frostatem", "Blockt ein Schild, werden nahe Gegner stark unterkühlt.", {"armor_breath": 1}), m("armor_stare", "Kältestarre", "Blockt ein Schild, werden nahe Gegner weggestoßen.", {"armor_stare": 1}),
             f(), k("frost_fortress", "Festung", "+6 Härte, −15 % Bewegung.", stats={"armor": 6, "speed_bonus": -15}), f()],
        ],
    },
    "herb_druid": {
        "name": "Kräuterzahn",
        "tagline": "Erst säen, dann ernten: Heilkräuter kämpfen für dich.",
        "style": ["Der Pflanzstab setzt im Angriffstakt Salbeitriebe, die auf Gegner schießen", "Putzeifer lässt den Garten wachsen, Fernschaden stärkt die Schüsse", "Denti selbst kämpft nicht; wer flieht, lässt seinen Garten zurück"],
        "description": "Der Kräuterzahn trägt nur den Pflanzstab. Im Angriffstakt pflanzt er dort, wo er steht, einen Salbeitrieb, der selbstständig schießt. Pflanzen verwelken nach einer Weile; je schneller er pflanzt, desto größer wird sein Garten. Gegner nutzen Pflanzen bei Kontakt ab, Bosse zertrampeln sie.",
        "roots": 1,
        "exclusive": "planting_staff",
        "starting": {},
        "tags": ["ranged", "area", "crit"],
        "branches": ["Salbeibeet", "Kamillenhain", "Nelkenhecke"],
        "tree": [
            [a("ranged_damage", 8), t("herb_thorns", "Dornen", "Salbeischüsse durchbohren einen weiteren Gegner.", 1, {"herb_pierce": 1}), a("attack_speed", 4),
             a("crit_chance", 4), t("herb_dense", "Dichtes Beet", "Ein Salbeitrieb mehr gleichzeitig je Rang.", 2, {"herb_cap": 1}), f(),
             f(), t("herb_bitter", "Bitterkraut", "+3 Salbeischaden je Rang.", 3, {"herb_damage": 3}), a("ranged_damage", 6),
             f(), s("herb_shrub", "Salbeistrauch", "Jeder fünfte Salbeitrieb wächst zu einem Strauch, der eine Salve auf mehrere Gegner feuert.", {"skill_shrub": 1}), a("damage_bonus", 6),
             m("shrub_wild", "Wildwuchs", "Schon jeder vierte Salbeitrieb wird ein Strauch.", {"shrub_wild": 1}), m("shrub_seeds", "Samenschuss", "Strauch-Salven feuern zwei Samen mehr.", {"shrub_seeds": 2}), m("shrub_roots", "Tiefe Wurzeln", "Sträucher leben doppelt so lang.", {"shrub_roots": 1}),
             f(), k("herb_monoculture", "Monokultur", "Nur noch Salbei, keine Kamille und Nelke; dafür 50 % mehr Pflanzen gleichzeitig.", {"herb_monoculture": 1}), f()],
            [a("regen", 10), t("herb_soothe", "Beruhigend", "Pflanzen in deiner Nähe heilen dich langsam.", 1, {"herb_soothe": 1}), a("max_health", 10),
             a("attack_speed", 4), t("herb_can", "Gießkanne", "Pflanzen leben 2 s länger je Rang.", 2, {"herb_life": 2}), f(),
             f(), t("herb_pollen", "Blütenstaub", "+5 % Putzeifer je Rang.", 3, stats={"attack_speed": 5}), a("armor", 8),
             f(), s("herb_totem", "Kamillentotem", "Jede vierte Pflanzung ist ein Kamillentotem. Seine Aura gibt dir mehr Angriffstempo, lässt Salbeitriebe darin schneller schießen und heilt dich langsam.", {"skill_totem": 1}), a("regen", 8),
             m("totem_wreath", "Großer Kranz", "Die Totem-Aura wird deutlich größer.", {"totem_wreath": 1}), m("totem_tea", "Kamillentee", "In einer Totem-Aura erhältst du alle 8 s einen Schild.", {"totem_tea": 1}), m("totem_cutting", "Ableger", "Verwelkt ein Totem, wächst an seiner Stelle ein Salbeitrieb.", {"totem_cutting": 1}),
             f(), k("herb_ceremony", "Teezeremonie", "Totems wirken doppelt so stark, aber du bist in ihrer Aura langsamer.", {"herb_ceremony": 1}), f()],
            [a("armor", 10), t("herb_numb", "Betäubung", "Salbeischüsse verlangsamen kurz.", 1, {"herb_numb": 1}), a("max_health", 10),
             a("speed_bonus", 5), t("herb_tendril", "Ranken", "Jeder Dash setzt an seinem Startpunkt einen Salbeitrieb.", 1, {"herb_tendril": 1}), f(),
             f(), t("herb_hedge", "Hecke", "Pflanzen halten 50 % mehr Gegnerkontakt aus je Rang.", 2, {"herb_hedge": 0.5}), a("dodge_chance", 4),
             f(), s("herb_clove", "Nelkenknospe", "Jede vierte Pflanzung ist eine Nelkenknospe. Gegner in ihrer Nähe sind verlangsamt und nehmen 15 % mehr Waffenschaden, auch Bosse.", {"skill_clove": 1}), a("dash_recovery_bonus", 6),
             m("clove_oil", "Nelkenöl", "Nelkenknospen betäuben stärker: 25 % mehr Waffenschaden.", {"clove_oil": 1}), m("clove_burst", "Platzende Knospe", "Eine verwelkende Nelkenknospe platzt und trifft Gegner in ihrer Nähe.", {"clove_burst": 1}), m("clove_snare", "Würgeranke", "Gegner, die zum ersten Mal an eine Nelkenknospe geraten, bleiben kurz hängen. Bosse nicht.", {"clove_snare": 1}),
             f(), k("herb_poison_garden", "Giftgarten", "Nelkenknospen vergiften statt zu verlangsamen.", {"herb_poison_garden": 1}), f()],
        ],
    },
}


def fmt(values):
    return "{" + ", ".join('"%s": %r' % (key, float(value)) for key, value in values.items()) + "}"


def tree_nodes(class_id, spec):
    nodes = []
    prefix = class_id.split("_")[0]
    atlas = ATLAS_BASE.get(class_id)
    for branch, cells in enumerate(spec["tree"]):
        assert len(cells) == 18, (class_id, branch, len(cells))
        skill_id = None
        painted = 0
        for index, cell in enumerate(cells):
            row, column = divmod(index, 3)
            cell_base = {"branch": branch, "row": row, "column": column}
            kind = cell[0]
            if kind == "a":
                nodes.append(dict(cell_base, id="%s_b%d_%s_%d%d" % (prefix, branch, cell[1], row, column), stat=cell[1], max_ranks=cell[2]))
            elif kind == "f":
                nodes.append(dict(cell_base, id="%s_b%d_free_%d%d" % (prefix, branch, row, column), free=True, max_ranks=cell[1]))
            elif kind == "t":
                _, id, name, desc, ranks, effects, stats, parent, icon = cell
                nodes.append(dict(cell_base, id=id, name=name, desc=desc, max_ranks=ranks, effects=effects, stats=stats, parent=parent, icon=icon))
            elif kind == "s":
                _, id, name, desc, effects, icon = cell
                skill_id = id
                nodes.append(dict(cell_base, id=id, name=name, desc=desc, max_ranks=1, effects=effects, kind="skill", icon=icon))
            elif kind == "m":
                _, id, name, desc, effects, ranks, icon = cell
                assert skill_id, (class_id, id)
                nodes.append(dict(cell_base, id=id, name=name, desc=desc, max_ranks=ranks, effects=effects, kind="modifier", parent=skill_id, icon=icon))
            elif kind == "k":
                _, id, name, desc, effects, stats, icon = cell
                nodes.append(dict(cell_base, id=id, name=name, desc=desc, max_ranks=1, effects=effects, stats=stats, kind="keystone", icon=icon))
            if kind in "tsmk" and atlas is not None:
                assert painted < ATLAS_COLUMNS, (class_id, branch, painted)
                nodes[-1]["icon"] = atlas + branch * ATLAS_COLUMNS + painted
            if kind in "tsmk": painted += 1
    ids = [node["id"] for node in nodes]
    assert len(ids) == len(set(ids)), class_id
    return nodes


def write_tree(class_id, spec):
    nodes = tree_nodes(class_id, spec)
    lines = ['[gd_resource type="Resource" script_class="TalentTreeData" load_steps=%d format=3]' % (len(nodes) + 3),
             '[ext_resource type="Script" path="res://scripts/player/talent_tree_data.gd" id="1"]',
             '[ext_resource type="Script" path="res://scripts/player/talent_node_data.gd" id="2"]']
    for index, node in enumerate(nodes):
        lines += ['[sub_resource type="Resource" id="N%d"]' % index, 'script = ExtResource("2")', 'id = &"%s"' % node["id"]]
        if "name" in node:
            lines += ['display_name = "%s"' % node["name"], 'description = "%s"' % node["desc"]]
        if "stat" in node: lines.append('stat = &"%s"' % node["stat"])
        if node.get("free"): lines.append("free_attribute = true")
        if node.get("kind"): lines.append('kind = &"%s"' % node["kind"])
        if node["branch"]: lines.append("branch = %d" % node["branch"])
        if node["row"]: lines.append("row = %d" % node["row"])
        if node["column"] != 1: lines.append("column = %d" % node["column"])
        if node.get("parent"): lines.append('parent = &"%s"' % node["parent"])
        if node["max_ranks"] != 1: lines.append("max_ranks = %d" % node["max_ranks"])
        if node.get("stats"): lines.append("stat_changes = %s" % fmt(node["stats"]))
        if node.get("effects"): lines.append("effects = %s" % fmt(node["effects"]))
        if "name" in node: lines.append("icon_index = %d" % node.get("icon", -1))
    lines += ["[resource]", 'script = ExtResource("1")',
              "branches = Array[String]([%s])" % ", ".join('"%s"' % name for name in spec["branches"]),
              'nodes = Array[ExtResource("2")]([%s])' % ", ".join('SubResource("N%d")' % i for i in range(len(nodes)))]
    with open(os.path.join(ROOT, "data/talents/%s.tres" % class_id), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


def portrait_path(class_id):
    painted = PORTRAITS.get(class_id)
    return "res://" + painted if painted and os.path.exists(os.path.join(ROOT, painted)) else PLACEHOLDER_PORTRAIT


def write_class(class_id, spec):
    dash = spec.get("dash")
    steps = 4 + (1 if dash else 0)
    lines = ['[gd_resource type="Resource" script_class="PlayerClassData" load_steps=%d format=3]' % steps,
             '[ext_resource type="Script" path="res://scripts/player/player_class_data.gd" id="1"]',
             '[ext_resource type="Resource" path="res://data/talents/%s.tres" id="2"]' % class_id,
             '[ext_resource type="Texture2D" path="%s" id="3"]' % portrait_path(class_id)]
    if dash:
        lines.append('[ext_resource type="Script" path="res://scripts/player/dash_data.gd" id="4"]')
        lines += ['[sub_resource type="Resource" id="Dash"]', 'script = ExtResource("4")']
        lines += ["%s = %r" % (key, float(value)) for key, value in dash.items()]
    lines += ["[resource]", 'script = ExtResource("1")', 'id = &"%s"' % class_id,
              'tagline = "%s"' % spec["tagline"],
              "play_style = Array[String]([%s])" % ", ".join('"%s"' % line for line in spec["style"]),
              'portrait = ExtResource("3")',
              ] + (['combat_sprite = ExtResource("3")'] if portrait_path(class_id) != PLACEHOLDER_PORTRAIT else []) + [
              'display_name = "%s"' % spec["name"], 'description = "%s"' % spec["description"],
              "root_capacity = %d" % spec["roots"],
              ] + (['exclusive_weapon_id = &"%s"' % spec["exclusive"]] if spec.get("exclusive") else []) + [
              "starting_stats = %s" % fmt(spec["starting"]),
              "preferred_tags = Array[StringName]([%s])" % ", ".join('&"%s"' % tag for tag in spec["tags"])]
    if dash: lines.append('dash_override = SubResource("Dash")')
    lines.append('talent_tree = ExtResource("2")')
    with open(os.path.join(ROOT, "data/classes/%s.tres" % class_id), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    import sys
    selected = sys.argv[1:] or list(CLASSES)
    for class_id, spec in CLASSES.items():
        if class_id not in selected: continue
        write_tree(class_id, spec)
        write_class(class_id, spec)
        print(class_id, len(tree_nodes(class_id, spec)), "nodes")
