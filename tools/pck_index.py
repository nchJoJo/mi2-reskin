import struct, sys, json
EXE = r"C:\Program Files (x86)\Steam\steamapps\common\Melvor Idle 2\Melvor2.exe"
f = open(EXE, "rb")
start = 109411328
f.seek(start)
hdr = f.read(4)
print("header magic", hdr, "at", start)
ver, major, minor, patch = struct.unpack("<4I", f.read(16))
print("pck format", ver, "godot", major, minor, patch)
flags = struct.unpack("<I", f.read(4))[0]
file_base = struct.unpack("<Q", f.read(8))[0]
dir_offset = None
if ver >= 3:
    dir_offset = struct.unpack("<Q", f.read(8))[0]
print("flags", flags, "file_base", file_base, "dir_offset", dir_offset)
if flags & 1:
    sys.exit("directory is encrypted")
if dir_offset is not None:
    f.seek(start + dir_offset)
else:
    f.read(16 * 4)
count = struct.unpack("<I", f.read(4))[0]
files = []
for _ in range(count):
    n = struct.unpack("<I", f.read(4))[0]
    path = f.read(n).rstrip(b"\0").decode("utf-8", "replace")
    off, sz = struct.unpack("<QQ", f.read(16))
    md5 = f.read(16)
    fl = struct.unpack("<I", f.read(4))[0]
    files.append({"path": path, "off": off, "size": sz, "flags": fl})
print("files:", count)
json.dump({"start": start, "file_base": file_base, "files": files}, open(sys.argv[1], "w"))
