import json, re, collections
EXE = r"C:\Program Files (x86)\Steam\steamapps\common\Melvor Idle 2\Melvor2.exe"
idx = json.load(open("pck_index.json")); start, base = idx["start"], idx["file_base"]
f = open(EXE, "rb")
def read(e): f.seek(start + base + e["off"]); return f.read(e["size"])
c = collections.Counter(); files_skew = []; total=0
for e in idx["files"]:
    p = e["path"]
    if not (p.endswith(".scn") or p.endswith(".res")): continue
    d = read(e); total+=1
    for k in (b"skew", b"anti_aliasing", b"StyleBoxFlat", b"StyleBoxTexture", b"corner_radius", b"border_width", b"shadow_size"):
        if k in d: c[k.decode()] += 1
    if b"skew" in d and b"StyleBoxFlat" in d: files_skew.append(p.split("-",1)[-1])
print("scanned", total, dict(c))
print(len(files_skew)); print(files_skew[:60])
