import json, re, os, collections, sys
EXE = r"C:\Program Files (x86)\Steam\steamapps\common\Melvor Idle 2\Melvor2.exe"
idx = json.load(open("pck_index.json")); start, base = idx["start"], idx["file_base"]
f = open(EXE, "rb")
def read(e): f.seek(start + base + e["off"]); return f.read(e["size"])
byp = {e["path"]: e for e in idx["files"]}

types = collections.Counter(); rows = []
for p, e in byp.items():
    if not (p.startswith("Assets/Styles") and p.endswith(".remap")) and p != "project.binary": continue
    if p == "project.binary": continue
    txt = read(e).decode("utf-8", "replace")
    m = re.search(r'path="res://([^"]+)"', txt)
    if not m or m.group(1) not in byp: continue
    data = read(byp[m.group(1)])
    s = re.findall(rb"[\x20-\x7e]{6,}", data)
    cls = next((x.decode() for x in s if x.startswith(b"StyleBox") or x in (b"Theme", b"LabelSettings")), "?")
    texs = [x.decode() for x in s if x.startswith(b"res://") ]
    types[cls] += 1; rows.append((p[:-6], cls, texs[:2]))
print(types)
for r in sorted(rows):
    if r[1] in ("StyleBoxTexture", "Theme"): print(r)
open("project.binary","wb").write(read(byp["project.binary"]))
