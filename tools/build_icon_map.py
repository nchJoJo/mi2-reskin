import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MI1 = sys.argv[1] if len(sys.argv) > 1 else \
    r"C:\Program Files (x86)\Steam\steamapps\common\Melvor Idle\package.nw\assets\media"
OUT = os.path.join(HERE, "..", "mod", "mi1_icons.cfg")


MANUAL = {
    "Assets/Icons/Bank.png": "main/bank_header.svg",
    "Assets/Icons/Bank_64.png": "main/bank_header.svg",
    "Assets/Icons/Shop.png": "main/shop_header.svg",
    "Assets/Icons/Shop_64.png": "main/shop_header.svg",
    "Assets/Icons/Combat.png": "skills/combat/combat.svg",
    "Assets/Icons/Combat_64.png": "skills/combat/combat.svg",
    "Assets/Icons/Combat_512.png": "skills/combat/combat.svg",
    "Assets/Icons/CompletionLog.png": "main/completion_log.svg",
    "Assets/Icons/Completion_64.png": "main/completion_log.svg",
    "Assets/Icons/Completion_512.png": "main/completion_log.svg",
    "Assets/Icons/Statistics_64.png": "main/statistics_header.svg",
    "Assets/Icons/Mastery_Icon.png": "main/mastery_header.svg",
    "Assets/Icons/Mastery_Icon_48.png": "main/mastery_header.svg",
    "Assets/Icons/Settings_64.png": "main/settings_header.svg",
    "Assets/Icons/Defence_64.png": "skills/defence/defence.svg",
    "Assets/Icons/MeleeStrength.png": "skills/strength/strength.svg",
}


def tokens(name):
    name = re.sub(r"\.(png|svg|jpg)$", "", name, flags=re.I)
    name = re.sub(r"_(\d+)$", "", name)
    parts = re.findall(r"[A-Z]+(?=[A-Z][a-z])|[A-Z]?[a-z]+|[A-Z]+|\d+", name)
    return [p.lower() for p in parts]


DROP = {"armour", "weapon", "ammo", "of", "the"}
ALIAS = {"tg": ["trimmed", "gold"], "ts": ["trimmed", "silver"], "adamantite": ["adamant"],
         "runite": ["rune"], "2h": ["2", "h"]}


def keys(name):
    t = tokens(name)
    loose = []
    for w in t:
        if w in DROP:
            continue
        w = w[:-1] if len(w) > 3 and w.endswith("s") else w
        loose += ALIAS.get(w, [w])
    out = ["".join(t), "+".join(sorted(t)), "+".join(sorted(loose))]
    if "2" in loose and "h" in loose:
        out.append("+".join(sorted(w for w in loose if w != "sword")))
    return out


def mi1_files():
    out = {}
    for root, _, files in os.walk(MI1):
        rel_root = os.path.relpath(root, MI1).replace("\\", "/")
        top = rel_root.split("/")[0]
        if top in ("mods", "updates", "april"):
            continue
        for f in files:
            if f.lower().endswith((".png", ".svg")):
                out[f"{rel_root}/{f}"] = f
    return out


def main():
    idx = json.load(open(os.path.join(HERE, "pck_index.json")))
    mi2 = sorted(e["path"][:-7] for e in idx["files"] if e["path"].endswith(".png.import"))
    mi2_items = [p for p in mi2 if p.startswith("Assets/Items/")]
    mi2_icons = [p for p in mi2 if p.startswith("Assets/Icons/") and p.count("/") == 2]

    files = mi1_files()

    by_key = {}
    for rel, f in sorted(files.items(), key=lambda kv: (not kv[0].startswith("bank/"), kv[0])):
        for k in keys(f):
            by_key.setdefault(k, rel)
    skill_icon = {}
    for rel in files:
        m = re.fullmatch(r"skills/([a-z]+)/\1\.svg", rel)
        if m:
            skill_icon[m.group(1)] = rel

    table, missed = {}, []
    for p in mi2_items:
        hit = next((by_key[k] for k in keys(os.path.basename(p)) if k in by_key), None)
        (table.__setitem__(p, hit) if hit else missed.append(p))
    for p in mi2_icons:
        if p in MANUAL:
            table[p] = MANUAL[p]
            continue
        base = "".join(tokens(os.path.basename(p)))
        if base in skill_icon:
            table[p] = skill_icon[base]
    for p, rel in MANUAL.items():
        if rel in files:
            table[p] = rel

    bad = [p for p, rel in table.items() if rel not in files]
    assert not bad, bad
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("; MI2 icon -> MI1 image, both relative to each game's own folders. Made by tools/build_icon_map.py.\n")
        f.write("; Holds file names only. The images are read from the player's own Melvor Idle 1 install.\n\n[icons]\n\n")
        for p in sorted(table):
            f.write(f'"{p}"="{table[p]}"\n')
    print(f"items matched {sum(1 for p in table if p.startswith('Assets/Items/'))}/{len(mi2_items)}, "
          f"icons {sum(1 for p in table if p.startswith('Assets/Icons/'))}/{len(mi2_icons)}; wrote {OUT}")
    print("sample misses:", missed[:40])


if __name__ == "__main__":
    main()
