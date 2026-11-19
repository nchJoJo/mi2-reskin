# How it works

For installing and using the mod, see the [README](../README.md).

## Loading

`override.cfg` adds `mod/mi2_reskin.gd` as a Godot autoload. The loader compiles `mi2_reskin_core.gd`, which loads `mi2_reskin_polish.gd` (bars, scrollbars, sidebar, motion, cursor, tooltips) and `mi2_reskin_menu.gd` (the Reskin settings page).

Settings are read in this order, each overriding the one before:

1. `mod/mi2_reskin.cfg`, the defaults;
2. `mod/mi2_reskin_local.cfg`, optional settings for one computer;
3. `%APPDATA%\Games By Malcs\Melvor Idle 2\mi2_reskin_settings.cfg`, the choices made on the Reskin page.

## What it changes

Melvor Idle 2 draws most of its panels by stretching PNGs (`StyleBoxTexture` with no nine-patch margins), which blurs their edges. The reskin edits the game's shared style objects in memory:

- **Picture panels** get a small generated nine-patch, tinted with the average colour of the original picture. Content margins and the transparent border around the original are kept, so the layout doesn't move.
- **The crafted look** sorts each style into a kind of part, using the game's resource names, size and colour, and draws one look per kind:

  | Part | Look |
  |---|---|
  | Big frames | dark rim, bronze trim, corner studs, soft shading |
  | Cards | darker rim, lit top edge |
  | Headers | lit top edge, gold underline |
  | Label plaques | parchment with a brown rim |
  | Buttons | bevelled; bronze trim on hover |
  | Selected items | pressed in, gold trim |
  | Disabled buttons | recessed and grey |
  | Locked cards | dimmed per card, restored when unlocked |
  | Item slots | near-black with a warm edge |

- **Titles** on header bars, page titles and plaques use Alegreya SC; small header captions use Alegreya Sans SC. Buttons and body text keep the game's fonts.
- **Pages** are tidied when they open: locked entries, empty columns, category memory, picture shadows, Bank shortcuts, Farming's empty strips, the Hunting column, centred button text and missing artwork. The README lists them.
- **Melvor Idle 1 icons** are loaded at runtime from the player's own Melvor Idle 1 install. `mod/mi1_icons.cfg` only maps file names. **Melvor Idle 1 colours** replace the panel colours with Melvor Idle 1's slate greys.

Every original value is recorded before it changes, so F7 restores the game's look exactly. Style changes are made with the resource's signals blocked and followed by one redraw, because each "changed" signal rebuilds the whole UI's theme cache.

When the game builds a page, the shown part is styled in the same frame, before it is first drawn. Hidden branches are styled the moment they are shown, and a background scan handles the rest.

## For other mods


Other mods can match the reskin's look exactly:

- `get_node("/root/MI2Reskin/Core").style_box("frame")` returns a new `StyleBox` in the reskin's look. Roles: `frame`, `card`, `header`, `plaque`, `button`, `button_hover`, `go`, `stop`, `selected`, `locked`, `tooltip`, `tab`, `tab_on`, `footer`, `well`, `slot`. An optional second argument sets the fill colour.
- `palette()` returns the colours, trims, radii and shading of each role. The same data is written to `%APPDATA%\Games By Malcs\Melvor Idle 2\mi2_reskin_style.json` at start and after each F7, for code that doesn't run inside Godot.
- `bar_styles(kind, height)` returns `{"background": StyleBox, "fill": StyleBox}` for progress bars: `"progress"` (teal), `"xp"` (gold) or any `Color`.
- `fonts()` returns `{"title": Font, "caption": Font}`, the reskin's title and caption fonts (either can be null when switched off). `palette()` also lists their paths as `title_font` and `caption_font`.
- `dock_rect()` returns the inside of the top-bar slot in canvas coordinates, or an empty `Rect2` when the slot isn't shown. A panel placed there sits in the slot.
- The `look_changed(on)` signal fires on F7. The `Core` node is replaced when dev mode reloads it, so connect again after a reload.

Another mod keeps its own look, and gets the top-bar slot, if its top-level node is in the `mi2_reskin_keep_look` group, or if the start of that node's name is listed in `[frame] other_mods` (comma-separated). Settings that only apply to one computer can go in `mod\mi2_reskin_local.cfg`, which has the same layout, overrides `mi2_reskin.cfg`. `install.ps1` copies it; `package.ps1` and git leave it out.

## Dev mode

`install.ps1 -Dev` turns on a command file. Write one command per line to `%APPDATA%\Games By Malcs\Melvor Idle 2\mi2_reskin_cmd.txt`; the mod reads it within half a second and then deletes it.

| Command | What it does |
|---|---|
| `reload` | Re-reads `mod\mi2_reskin_core.gd` while the game runs. |
| `on`, `off` | Same as F7. |
| `at X Y` | Lists every UI node under that window pixel, with its styles and textures. |
| `tree DEPTH [path]` | Lists the node tree. |
| `find PATTERN` | Lists the path of every node whose name matches (wildcards `*` and `?`), and whether it's visible. |
| `desc DEPTH path` | Lists a node and its children with their styles, textures, colours and text, including hidden ones. |
| `api path` | Lists the signals, methods and properties of a node's script, C# ones included. |
| `signals path` | Lists the node's signals that have something connected. |
| `call path METHOD` | Calls a method without arguments on that node. |
| `press path` | Presses a button the way a click does (the game's own buttons, too). |
| `frames N` | Logs the next N frame times (average, worst, and every frame over 25 ms) to the log, to measure hitches after a page switch or F7. |
| `capture N` | Saves the next N drawn frames as `mi2_cap_NN.png` (half size), to see exactly what changes frame by frame. |
| `bench` | Times the parts of a node scan over the open page (read-only). |
| `kind CLASS` | Lists visible nodes of a class (progress bars, scrollbars...), grouped by their look. |
| `polish [hint path\|hint off]` | The polish module's state; forces a hover box onto a node, to check them without the mouse. Also saves the cursor pictures as `mi2_reskin_cursor*.png`. |
| `get path PROP ...` | Reads properties of a node, or of each of its children with `path/*`. |
| `stats` | Shows what was found and changed. |
| `center` | Lists visible buttons whose text sits more than 3 px above or below their middle. |
| `hidden` | How many nodes of the open page are shown, and how many sit in hidden branches. |
| `queue pause` / `queue resume` | Stops or restarts the background scan, to test that shown branches get styled without it. |
| `polish swatch` | Shows every scrollbar look (rest, hover, dragged; upright and on its side) for 8 s. |
| `blanks` | Lists visible picture slots that are empty or show a placeholder-looking picture. |
| `digits` | Total width of the visible labels showing whole numbers (to see whether digit widths changed). |
| `mem` | How many entries each of the reskin's own lists holds, and the game's object, resource and node counts (for finding leaks). |
| `tex NAME` | Lists nodes showing a texture whose path contains NAME. |
| `styles` | Lists every style drawn on screen: its kind of part, file, original look and one node that uses it. |

Output goes to `mi2_reskin_dump.txt` in the same folder.

`reload` compiles the file's text into a fresh `GDScript` instead of reloading it through `ResourceLoader`, which can hang Godot 4.7. Run `install.ps1` without `-Dev` for normal play.

## Tools

These read the game's files and change nothing:

- `tools/pck_index.py` lists the files packed inside `Melvor2.exe` and writes `pck_index.json`.
- `tools/extract_styles.py` and `tools/skewscan.py` read style resources from the exe.
- `tools/build_icon_map.py` writes `mod/mi1_icons.cfg` by matching Melvor Idle 2 icon names to Melvor Idle 1 file names.

## Packaging a release

`package.ps1` builds `dist/MI2-Reskin-<date>.zip` with the installer, the mod, the fonts with their licences, `README.md` and `LICENSE`. It refuses to build if the package contains any picture, sound or game-data file, if `[dev] enabled` isn't `false`, if a font has no licence next to it, or if a text file contains a path from the build computer.
