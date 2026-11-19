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

- **The Soft finish** (`preset="soft"`, the default) aims for Melvor Idle 1's calm look in Melvor Idle 2's colours. It drops the rim trims, studs, bevels and gold underlines from the table above, leaving only a faint edge in each panel's own colour. Corners are 8 px on frames, cards and tooltips and 6 px on headers, buttons and labels. Teal headers move 35% and the green and red action buttons 45% toward grey. The beige label plaques and picture tiles become a dark warm grey (`#2b2824`) with light text (`#e4dccd`), even when the title fonts are off. Cards and frames get 2 px more padding. The accent colours are neutral (`TRIM` #5d5850, `GOLD` #c9b48c), and the scrollbars, sidebar and dividers pick them up.
- **Titles** on header bars, page titles and plaques use Alegreya SC; small header captions use Alegreya Sans SC. Other text uses Rubik (`[reskin] body_font`): every label, button and text box whose font is one of the game's `Default_*` weights gets the matching Rubik weight (400, 500, 600 or 700) as an override that F7 removes. The mod's fonts load as MSDF fonts with mipmaps, like the game's own, so they stay sharp at the UI's fractional scale. MSDF needs fonts whose outlines don't overlap, so variable fonts and some static ones show specks inside letters; Rubik's static weights from Google Fonts render cleanly. Switching the body font re-measures the text of about 2,700 controls, so F7 takes about 0.1–0.2 s with it on, and building Rubik's MSDF glyphs costs about 0.9 s once, while the game starts.
- **Pages** are tidied when they open: locked entries, empty columns, category memory, picture shadows, Bank shortcuts, Farming's empty strips, the Hunting column, centred button text and missing artwork. The README lists them.
- **Melvor Idle 1 icons** are loaded at runtime from the player's own Melvor Idle 1 install. `mod/mi1_icons.cfg` only maps file names. **Colours** (`[reskin] palette`) remap the game's dark, low-saturation panel colours and keep saturated ones (buttons, icons, gold) as they are. MI1 Slate maps by brightness onto Melvor Idle 1's four slate tones. Graphite and Midnight keep each colour's brightness but give it a fixed hue and saturation (grey, or blue at 32%), and darken it slightly. Empty bar tracks get the preset's darkest tone so missing health still shows. **Accent** (`[reskin] accent`) replaces the finish's `TRIM` and `GOLD` colours, which the bars, dividers, scrollbars and outlines use. The older `[mi1] theme=true` still works and means `palette="slate"`.

Every original value is recorded before it changes, so F7 restores the game's look exactly. Style changes are made with the resource's signals blocked and followed by one redraw, because each "changed" signal rebuilds the whole UI's theme cache.

The game's Window Scale (70% to 120%) is Godot's `content_scale_factor` on top of a 1920 × 1080 base layout, so at 100% in a 1009-pixel-high window the UI is already drawn at about 93%. The generated panels stay sharp across that range. Thin bars are drawn as square boxes without anti-aliasing, because a rounded 1-pixel rim on a 2-pixel bar breaks apart below 100%. The top-bar slot for other mods measures the gap before the first navigation button whenever the top bar resizes, and hides if the gap is too narrow.

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
| `fonts` | Lists the fonts used by visible labels and their rendering settings (MSDF, mipmaps, hinting), and the window's oversampling. |
| `set path PROP VALUE` | Sets one property of a node; the value is read as a Godot value (`1.2`, `true`, `"text"`). Setting a game control's `value` runs the game's own handler, for example the Window Scale box. |
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
