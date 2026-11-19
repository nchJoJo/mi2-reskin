extends Node

const VERSION := "2026-11-19.2"
const CFG_PATH := "res://mod/mi2_reskin.cfg"
const LOCAL_CFG_PATH := "res://mod/mi2_reskin_local.cfg"
const ICON_MAP_PATH := "res://mod/mi1_icons.cfg"
const LOG_PATH := "user://mi2_reskin.log"
const STYLE_PATH := "user://mi2_reskin_style.json"
const TITLE_GROW := 2
const FONT_DIR := "res://mod/fonts/"
const DUMP_PATH := "user://mi2_reskin_dump.txt"
const NODES_PER_FRAME := 400
const WATCH_PER_FRAME := 300
const ICONS_PER_FRAME := 6
const MI1_MEDIA := "steamapps/common/Melvor Idle/package.nw/assets/media"

const MI1_PAGE := Color("#2c3444")
const MI1_INSET := Color("#232a36")
const MI1_PANEL := Color("#303a4b")
const MI1_HEADER := Color("#3a4559")

var TRIM := Color("#7a5f38")
var GOLD := Color("#c9a45c")
var preset := "soft"
var _polish: Node = null
const POLISH_PATH := "res://mod/mi2_reskin_polish.gd"
const MENU_PATH := "res://mod/mi2_reskin_menu.gd"
const USER_CFG_PATH := "user://mi2_reskin_settings.cfg"
var _menu: Node = null
const GRAD_ROWS := 16

var enabled := true
var straighten := true
var crisp_edges := true
var corner_radius := -1
var flatten_textures := true
var panel_radius := 6
var panel_border := 0.25
var panel_opacity := 1.0
var title_font := true
var title_font_file := "AlegreyaSC-Bold.ttf"
var caption_font_file := "AlegreyaSansSC-Bold.ttf"
var caption_spacing := 1
var body_font := "Rubik"
var _caption_font: Font = null
var tidy_pages := true
var tidy_frame := true
var other_mods: PackedStringArray = []
var _title_font: Font = null
var _titles := 0
var _title_settings := {}
var _labels: Array = []
var look := "crafted"
var toggle_key: Key = KEY_F7
var mi1_icons := false
var mi1_theme := false
var colours := "mi2"
var accent := "finish"
var keep_teal_headers := false
var mi1_plain_background := false
var mi1_path := ""

var _saved := {}
var _flats := {}
var _tracks := {}
const MI1_TRACK := Color("#161b23")
var _texboxes := {}
var _seen := {}
var _queue: Array = []
var _watch: Array = []
var _watch_i := 0
var _props_by_class := {}
var _tex_info := {}
var _style_users := {}
var _size_wait: Array = []
var _panel_textures := {}
var _icon_map := {}
var _icon_state := {}
var _icon_failed := {}
var _icon_pending := []
var _icon_queued := {}
var _page_nodes: Array = []
var _collapsed := {}
var remember_category := true
var _categories := {}
var _cat_tried := {}
var detail_frame := false
var picture_shadows := "faint"
var _shadows: Array = []
var _blanked := {}
var _label_kind := {}
var _title_labels := {}
var _dev_steps := false
var _dev_timing := false
var _ft: Array = []
var _ft_left := 0
var _ft_last := 0
var _cap_left := 0
var _cap_i := 0


func _capture_frame() -> void:
	await RenderingServer.frame_post_draw
	if _cap_left <= 0:
		return
	_cap_left -= 1
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() / 2, img.get_height() / 2)
	img.save_png("user://mi2_cap_%02d.png" % _cap_i)
	_cap_i += 1
var _foreign_roots: Array = []
var _foreign_at := -100000
var _token := 0
var _cfg: ConfigFile = null
var _version_box: StyleBoxFlat = null
var _released_total := 0
var _name_kind := {}
var _has_bg_style := {}
var _branches: Array = []
var _branches_queued := false
var _copies_found := 0
var _tidy_due := false
var _queue_paused := false
var _hidden_roots: Array = []
var _header_memo := {}
var _disk_info := {}
var _disk_dirty := false
var _us_info := 0
var _us_texbox := 0
var _us_flat := 0
var _new_styles := 0
var _version_next: WeakRef = null
var _bank_help: Label = null
var _quiet_panel: StyleBox = null
var _lock_labels := {}
var _text_stacks: Array = []
var _locks: Array = []
var _lock_tick := 0
var _redraw_due := false
var _last_redraw := 0
var _started := 0
var _summary_logged := false
var _slanted := 0


signal look_changed(on: bool)

const ROLE_FILLS := {"frame": "#36332c", "card": "#1b1a19", "header": "#005f6c", "plaque": "#e9dfc0",
	"button": "#2e2c28", "button_hover": "#443b14", "go": "#016101", "stop": "#7a1414",
	"selected": "#174214", "locked": "#181715", "tooltip": "#1b1a19", "tab": "#2e2c28", "tab_on": "#005f6c",
	"footer": "#121210", "well": "#121110", "slot": "#0f0f11"}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000
	_token = (randi() % 2000000000) + 1
	_started = Time.get_ticks_msec()
	_load_config()
	_load_pages()
	_load_disk_info()
	if mi1_icons:
		_load_icon_map()
	for t in _base_themes():
		_scan_theme(t)
	_load_polish()
	get_tree().node_added.connect(_on_node_added)
	_enqueue_tree(get_tree().root)
	if enabled:
		_apply_globals(true)
	_write_style_file()
	_log("core started: version=" + VERSION + " enabled=%s flatten_textures=%s panel_radius=%d mi1_icons=%s (%d mapped) mi1_theme=%s" % [
		enabled, flatten_textures, panel_radius, mi1_icons, _icon_map.size(), mi1_theme])


func style_box(role: String, fill: Color = Color(0, 0, 0, 0)) -> StyleBox:
	if fill.a == 0.0:
		fill = Color(ROLE_FILLS.get(role, "#1b1a19"))
	var L := _look(role, Color(fill.r, fill.g, fill.b))
	var m := _look_m(L)
	var sb := StyleBoxTexture.new()
	sb.texture = _crafted_texture(L, [0, 0, 0, 0])
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(m))
		sb.set("content_margin_" + side, float(maxi(m, 6)))
	sb.modulate_color = Color(1, 1, 1, fill.a)
	sb.set_meta(&"mi2r_own", true)
	return sb


func palette() -> Dictionary:
	var roles := {}
	for role in ROLE_FILLS:
		var L := _look(role, Color(ROLE_FILLS[role]))
		roles[role] = {"fill": _hex(L.fill), "rim": _hex(L.rim),
			"trim": _hex(L.trim) if L.trim_w > 0 else "", "trim_width": L.trim_w,
			"radius": L.r, "accent": _hex(L.accent) if L.accent_rows > 0 else "",
			"accent_rows": L.accent_rows, "top_light": L.hi, "bottom_shade": L.lo, "shade": L.grad,
			"rivets": L.rivets}
	return {"look": look, "enabled": enabled, "trim": _hex(TRIM), "gold": _hex(GOLD),
		"text": "#e8e4dc", "text_muted": "#9a958c", "progress": "#4fb3c2", "panel_radius": panel_radius,
		"title_font": FONT_DIR + title_font_file if title_font else "",
		"caption_font": FONT_DIR + caption_font_file if caption_font_file != "" else "",
		"roles": roles}


func bar_styles(kind = "progress", height := 6) -> Dictionary:
	var fill_color: Color = kind if kind is Color else (GOLD if str(kind) == "xp" else Color("#4fb3c2"))
	var r := mini(3, height / 2)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#0d0c0b")
	bg.border_color = TRIM.darkened(0.2)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(r)
	bg.content_margin_top = height / 2.0
	bg.content_margin_bottom = height / 2.0
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_color
	fg.border_color = fill_color.lightened(0.25)
	fg.border_width_top = 1
	fg.set_corner_radius_all(r)
	return {"background": bg, "fill": fg}


func fonts() -> Dictionary:
	return {"title": _get_title_font() if title_font else null, "caption": _get_caption_font()}


func _hex(c: Color) -> String:
	return "#" + c.to_html(false)


func _write_style_file() -> void:
	var f := FileAccess.open(STYLE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(palette(), "  "))


func shutdown() -> void:
	_save_disk_info()
	_set_enabled_quiet(false)
	if _polish != null:
		_polish.shutdown()
	if _menu != null:
		_menu.shutdown()


func _load_polish() -> void:
	_polish = _load_module(POLISH_PATH, "Polish")
	if _polish != null:
		_polish.setup(self, _cfg)
	_menu = _load_module(MENU_PATH, "Menu")
	if _menu != null:
		_menu.setup(self)


func _load_module(path: String, node_name: String) -> Node:
	if not FileAccess.file_exists(path):
		return null
	var scr := GDScript.new()
	scr.source_code = FileAccess.get_file_as_string(path)
	if scr.reload() != OK:
		_log("%s has a GDScript error; running without it" % path)
		return null
	var n := Node.new()
	n.name = node_name
	n.set_script(scr)
	add_child(n)
	return n


func apply_settings() -> void:
	var was_on := enabled
	_set_enabled_quiet(false)
	_load_config()
	enabled = was_on
	_panel_textures.clear()
	_hunt_styles.clear()
	_fallback_tex = null
	_tip_theme = null
	_quiet_panel = null
	_title_font = null
	_caption_font = null
	_title_settings.clear()
	_label_kind.clear()
	_plaque_memo.clear()
	if mi1_icons and _icon_map.is_empty():
		_load_icon_map()
	if _polish != null:
		_polish.setup(self, _cfg)
		_polish.reset_cache()
	_set_enabled_quiet(enabled)
	_log("settings applied: enabled=%s look=%s preset=%s" % [enabled, look, preset])


func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		_log("no %s, using defaults" % CFG_PATH)
	var local := ConfigFile.new()
	if local.load(LOCAL_CFG_PATH) == OK:
		for section in local.get_sections():
			for key in local.get_section_keys(section):
				cfg.set_value(section, key, local.get_value(section, key))
	var mine := ConfigFile.new()
	if mine.load(USER_CFG_PATH) == OK:
		for section in mine.get_sections():
			for key in mine.get_section_keys(section):
				cfg.set_value(section, key, mine.get_value(section, key))
	enabled = bool(cfg.get_value("reskin", "enabled", enabled))
	straighten = bool(cfg.get_value("reskin", "straighten", straighten))
	crisp_edges = bool(cfg.get_value("reskin", "crisp_edges", crisp_edges))
	corner_radius = int(cfg.get_value("reskin", "corner_radius", corner_radius))
	flatten_textures = bool(cfg.get_value("reskin", "flatten_textures", flatten_textures))
	panel_radius = int(cfg.get_value("reskin", "panel_radius", panel_radius))
	panel_border = float(cfg.get_value("reskin", "panel_border", panel_border))
	look = str(cfg.get_value("reskin", "look", look))
	title_font = bool(cfg.get_value("reskin", "title_font", title_font))
	title_font_file = str(cfg.get_value("reskin", "title_font_file", title_font_file))
	caption_font_file = str(cfg.get_value("reskin", "caption_font_file", caption_font_file))
	body_font = str(cfg.get_value("reskin", "body_font", body_font))
	caption_spacing = int(cfg.get_value("reskin", "caption_spacing", caption_spacing))
	tidy_frame = bool(cfg.get_value("frame", "tidy", tidy_frame))
	other_mods = PackedStringArray()
	for p in str(cfg.get_value("frame", "other_mods", "")).split(",", false):
		if p.strip_edges() != "":
			other_mods.append(p.strip_edges())
	tidy_pages = bool(cfg.get_value("pages", "tidy", tidy_pages))
	remember_category = bool(cfg.get_value("pages", "remember_category", remember_category))
	picture_shadows = str(cfg.get_value("pages", "picture_shadows", picture_shadows))
	detail_frame = bool(cfg.get_value("pages", "detail_frame", detail_frame))
	preset = str(cfg.get_value("reskin", "preset", preset))
	TRIM = Color("#7a5f38")
	GOLD = Color("#c9a45c")
	if preset == "soft":
		TRIM = Color("#5d5850")
		GOLD = Color("#c9b48c")
	elif preset == "gilded":
		TRIM = Color("#a07c3c")
		GOLD = Color("#e0b85a")
	accent = str(cfg.get_value("reskin", "accent", accent))
	if ACCENTS.has(accent):
		TRIM = Color(ACCENTS[accent][0])
		GOLD = Color(ACCENTS[accent][1])
	_cfg = cfg
	panel_opacity = clampf(float(cfg.get_value("reskin", "panel_opacity", panel_opacity)), 0.0, 1.0)
	var k := OS.find_keycode_from_string(str(cfg.get_value("reskin", "toggle_key", "F7")))
	if k != KEY_NONE:
		toggle_key = k
	mi1_icons = bool(cfg.get_value("mi1", "icons", mi1_icons))
	colours = str(cfg.get_value("reskin", "palette", colours))
	if bool(cfg.get_value("mi1", "theme", false)) and str(mine.get_value("reskin", "palette", "")) == "":
		colours = "slate"
	if not PALETTES.has(colours):
		colours = "mi2"
	mi1_theme = colours == "slate"
	keep_teal_headers = bool(cfg.get_value("mi1", "keep_teal_headers", keep_teal_headers))
	mi1_plain_background = bool(cfg.get_value("mi1", "plain_background", mi1_plain_background))
	mi1_path = str(cfg.get_value("mi1", "path", mi1_path))


func _base_themes() -> Array:
	var out := []
	if ThemeDB.has_method("get_project_theme"):
		out.append(ThemeDB.call("get_project_theme"))
	var path := str(ProjectSettings.get_setting("gui/theme/custom", ""))
	if path != "" and ResourceLoader.exists(path):
		out.append(load(path))
	out.append(ThemeDB.get_default_theme())
	return out


const ORIG_META := &"mi2r_orig"

func _put(o: Object, prop: StringName, v) -> void:
	var d: Dictionary = _saved.get(o, {})
	if not d.has(prop):
		d[prop] = o.get(prop)
		_saved[o] = d
		if o is StyleBox:
			o.set_block_signals(true)
			o.set_meta(ORIG_META, d.duplicate())
			o.set_block_signals(false)
	if o.get(prop) != v:
		var quiet := o is Resource
		if quiet:
			o.set_block_signals(true)
		o.set(prop, v)
		if quiet:
			o.set_block_signals(false)
			_redraw_due = true


func _orig(o: Object, prop: StringName):
	var d: Dictionary = _saved.get(o, {})
	return d[prop] if d.has(prop) else o.get(prop)


func _unput(o, prop: StringName) -> void:
	var d: Dictionary = _saved.get(o, {})
	if not d.has(prop):
		return
	if is_instance_valid(o):
		var quiet := o is Resource
		if quiet:
			o.set_block_signals(true)
		o.set(prop, d[prop])
		if quiet:
			o.set_block_signals(false)
			_redraw_due = true
	d.erase(prop)
	if d.is_empty():
		_saved.erase(o)
	if is_instance_valid(o) and o is StyleBox and o.has_meta(ORIG_META):
		o.set_block_signals(true)
		if d.is_empty():
			o.remove_meta(ORIG_META)
		else:
			o.set_meta(ORIG_META, d.duplicate())
		o.set_block_signals(false)


func _restore(o) -> void:
	if not _saved.has(o):
		return
	var d: Dictionary = _saved[o]
	_saved.erase(o)
	if not is_instance_valid(o):
		return
	var quiet := o is Resource
	if quiet:
		o.set_block_signals(true)
	for prop in d:
		if o.get(prop) != d[prop]:
			o.set(prop, d[prop])
	if o is StyleBox and o.has_meta(ORIG_META):
		o.remove_meta(ORIG_META)
	if quiet:
		o.set_block_signals(false)
		_redraw_due = true


func _on_node_added(n: Node) -> void:
	var parent := n.get_parent()
	if parent == get_tree().root:
		_foreign_at = -100000
	if n is CanvasItem:
		_queue.append(weakref(n))
		if enabled and parent != null and parent.has_meta(&"_mi2r") and parent.name != &"EntityViewContainer":
			_branches.append(weakref(n))
			if not _branches_queued:
				_branches_queued = true
				_settle_branches.call_deferred()
		if n is Control and n.get_parent() != null and n.get_parent().name == &"EntityViewContainer":
			if _polish != null and enabled:
				_polish.page_opened(n)
			_settle_page.call_deferred(n)


func _settle_page(page: Node) -> void:
	if not is_instance_valid(page) or not page.is_inside_tree():
		return
	var t0 := Time.get_ticks_usec()
	_new_styles = 0
	_us_info = 0
	_us_texbox = 0
	_us_flat = 0
	var labels: Array = []
	var count := _settle_nodes(page, labels)
	var t1 := Time.get_ticks_usec()
	_settle_titles(labels)
	var t2 := Time.get_ticks_usec()
	_check_locks()
	var t3 := Time.get_ticks_usec()
	_pages(enabled and look == "crafted" and tidy_pages)
	var t4 := Time.get_ticks_usec()
	if _polish != null:
		_polish.tick()
	var t5 := Time.get_ticks_usec()
	var ms := (t5 - t0) / 1000.0
	if ms > 8.0 or _dev_timing:
		_log("page %s styled in %.1f ms (%d nodes, %d new styles: picture panels %.1f incl. reading pictures %.1f, flat %.1f): scan %.1f, titles %.1f (%d labels), locks %.1f, pages %.1f, polish %.1f" % [
			page.name, ms, count, _new_styles, _us_texbox / 1000.0, _us_info / 1000.0, _us_flat / 1000.0, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0, labels.size(), (t3 - t2) / 1000.0,
			(t4 - t3) / 1000.0, (t5 - t4) / 1000.0])


func _settle_nodes(root: Node, labels: Array) -> int:
	var stack: Array = [root]
	var count := 0
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CanvasItem:
			if n != root and not (n as CanvasItem).visible:
				_hidden_roots.append([weakref(n), Time.get_ticks_msec()])
				continue
			_scan_node(n, true)
			count += 1
			if n is Label:
				labels.append(n)
		stack.append_array(n.get_children())
	return count


func _settle_titles(labels: Array) -> void:
	if _titles_wanted() and not labels.is_empty():
		var font := _title_font_or_null()
		for lb in labels:
			_title_one(lb, font)
	_header_memo.clear()


func _settle_branches() -> void:
	_branches_queued = false
	if not enabled:
		_branches.clear()
		return
	var labels: Array = []
	var done := 0
	for w in _branches:
		var r = w.get_ref()
		if r != null and is_instance_valid(r) and r.is_inside_tree() and not _foreign(r):
			done += _settle_nodes(r, labels)
	_branches.clear()
	_settle_titles(labels)
	if _tidy_due or done > 0:
		_tidy_due = false
		_check_locks()
		_pages(look == "crafted" and tidy_pages)


func _watch_hidden() -> void:
	if _hidden_roots.is_empty():
		return
	var now := Time.get_ticks_msec()
	var shown: Array = []
	var i := 0
	while i < _hidden_roots.size():
		var e: Array = _hidden_roots[i]
		var r = e[0].get_ref()
		if r == null or not is_instance_valid(r) or now - int(e[1]) > 3000:
			_hidden_roots[i] = _hidden_roots[_hidden_roots.size() - 1]
			_hidden_roots.pop_back()
			continue
		if (r as CanvasItem).visible and r.is_inside_tree() and (r as CanvasItem).is_visible_in_tree():
			shown.append(r)
			_hidden_roots[i] = _hidden_roots[_hidden_roots.size() - 1]
			_hidden_roots.pop_back()
			continue
		i += 1
	if shown.is_empty() or not enabled:
		return
	var labels: Array = []
	for r in shown:
		_settle_nodes(r, labels)
	_settle_titles(labels)
	_check_locks()
	_pages(enabled and look == "crafted" and tidy_pages)
	if _polish != null:
		_polish.tick()


func _enqueue_labels(n: Node) -> void:
	if n is Label:
		_labels.append(weakref(n))
	for c in n.get_children():
		_enqueue_labels(c)


func _enqueue_tree(n: Node) -> void:
	if n is CanvasItem:
		_queue.append(weakref(n))
	for c in n.get_children():
		_enqueue_tree(c)


func _process(_delta: float) -> void:
	if _cap_left > 0:
		_capture_frame.call_deferred()
	if _ft_left > 0:
		var now_us := Time.get_ticks_usec()
		if _ft_last > 0:
			_ft.append((now_us - _ft_last) / 1000.0)
		_ft_last = now_us
		_ft_left -= 1
		if _ft_left == 0:
			var mx := 0.0
			var sum := 0.0
			var slow := 0
			for d in _ft:
				mx = maxf(mx, d)
				sum += d
				if d > 25.0:
					slow += 1
			var big := _ft.filter(func(x): return x > 25.0).map(func(x): return snappedf(x, 0.1))
			_log("frames: %d, average %.1f ms, worst %.1f ms, %d over 25 ms: %s" % [_ft.size(), sum / _ft.size(), mx, slow, str(big)])
	_watch_hidden()
	var budget := 0 if _queue_paused else NODES_PER_FRAME
	while budget > 0 and not _queue.is_empty():
		budget -= 1
		var n = _queue.pop_back().get_ref()
		if n != null and is_instance_valid(n) and n.is_inside_tree():
			_scan_node(n)
	if _tidy_due:
		_tidy_due = false
		if enabled:
			_check_locks()
			_pages(look == "crafted" and tidy_pages)
	if enabled and mi1_icons and not _watch.is_empty():
		for i in mini(WATCH_PER_FRAME, _watch.size()):
			_watch_i = (_watch_i + 1) % _watch.size()
			var w = _watch[_watch_i].get_ref()
			if w == null or not is_instance_valid(w):
				_watch[_watch_i] = _watch[_watch.size() - 1]
				_watch.pop_back()
				if _watch.is_empty():
					break
				continue
			_check_textures(w)
	for i in mini(50, _size_wait.size()):
		var pair: Array = _size_wait.pop_front()
		var c = pair[0].get_ref()
		var sb: StyleBoxTexture = pair[1]
		if c == null or not is_instance_valid(c) or _style_users.has(sb):
			continue
		if c.size.x > 0.0 and c.size.y > 0.0:
			_style_users[sb] = c.size
			if enabled:
				_style_texbox(sb)
		elif c.is_inside_tree() and int(pair[2]) < 120:
			pair[2] = int(pair[2]) + 1
			_size_wait.append(pair)
	var loads := ICONS_PER_FRAME
	while loads > 0 and not _icon_pending.is_empty():
		loads -= 1
		var t = _icon_pending.pop_front()
		_icon_queued.erase(t)
		if enabled and mi1_icons and is_instance_valid(t):
			_swap_icon(t)
	_lock_tick += 1
	if _lock_tick % 15 == 0:
		_check_locks()
		_check_titles()
		_pages(enabled and look == "crafted" and tidy_pages)
		if _polish != null:
			_polish.tick()
		if _menu != null:
			_menu.tick()
		if enabled and look == "crafted" and _lock_tick % 60 == 0:
			_place_version(true)
			_frame(tidy_frame)
		if _lock_tick % 240 == 0:
			_prune()
	if _polish != null:
		_polish.frame()
	var now := Time.get_ticks_msec()
	if _redraw_due and now - _last_redraw >= 100:
		_redraw_due = false
		_last_redraw = now
		_redraw_all(get_tree().root)
	if not _summary_logged and now - _started > 20000:
		_summary_logged = true
		_log("after 20 s: %d flat styles (%d slanted), %d picture panels, %d MI1 icons shown, %d icons not usable" % [
			_flats.size(), _slanted, _texboxes.size(), _icon_state.size(), _icon_failed.size()])


func _class_props(n: Object) -> Array:
	var scr = n.get_script()
	var key = scr if scr != null else n.get_class()
	var entry = _props_by_class.get(key)
	if entry == null:
		var styles := []
		var textures := []
		for p in n.get_property_list():
			if p["type"] != TYPE_OBJECT:
				continue
			var pname := str(p["name"])
			var hint := str(p["hint_string"])
			if pname.begins_with("theme_override_styles/") or hint.contains("StyleBox") or hint == "Theme":
				styles.append(pname)
			elif hint == "Texture2D" or pname.begins_with("theme_override_icons/"):
				textures.append(pname)
		entry = [styles, textures]
		_props_by_class[key] = entry
	return entry


const PAGE_PARTS := {&"BankActiveView": true, &"FarmingActionView": true, &"CategorySelect": true,
	&"CategoryButtonContainer": true, &"QuestDialogueView": true, &"HuntingCurrentRecipeContainer": true}

func _scan_node(n: Node, trusted := false) -> void:
	var tag := n.get_instance_id() ^ _token
	if n.get_meta(&"_mi2r", 0) == tag:
		return
	if not trusted and _foreign(n):
		return
	n.set_meta(&"_mi2r", tag)
	if _polish != null:
		_polish.scan(n)
	if _body_active != "" and n is Control:
		_body_fonts_of(n as Control)
	if n is Range or n.get_script() != null:
		_note_track(n)
	if n is Control:
		var kind = _name_kind.get(n.name)
		if kind == null:
			var nm := str(n.name)
			kind = 0
			if nm.begins_with("Locked") or nm == "UnlockRequirements":
				kind = 1
			elif PAGE_PARTS.has(n.name) or nm.ends_with("CreatingRecipeContainer"):
				kind = 2
			elif nm.ends_with("Shadow"):
				kind = 3
			elif nm.begins_with("No") and nm.ends_with("SelectedView"):
				kind = 4
			_name_kind[n.name] = kind
		match kind:
			1:
				_locks.append(weakref(n))
				_tidy_due = true
			2:
				_page_nodes.append(weakref(n))
				_tidy_due = true
			3:
				if n is TextureRect and (n as TextureRect).modulate.v < 0.15:
					_shadows.append(weakref(n))
			4:
				if _is_empty_detail(n):
					_page_nodes.append(weakref(n))
	elif n is Sprite2D and n.name == &"OutlineSprite" and (n as Sprite2D).modulate.v < 0.15:
		_shadows.append(weakref(n))
	if n is Label:
		_labels.append(weakref(n))
	elif n is VBoxContainer and _in_button(n):
		_text_stacks.append(weakref(n))
	var entry := _class_props(n)
	for pname in entry[0]:
		var v = n.get(pname)
		if v is StyleBox:
			_scan_style(v)
			if v is StyleBoxTexture and n is Control and _texboxes.has(v) and not _style_users.has(v):
				_size_wait.append([weakref(n), v, 0])
		elif v is Theme:
			_scan_theme(v)
	if not entry[1].is_empty():
		for pname in entry[1]:
			var t = _orig(n, pname)
			if t is Texture2D and (t as Texture2D).resource_path == MISSING_ART:
				_fallbacks.append([weakref(n), pname])
				if enabled:
					_put(n, pname, _fallback_icon())
	if not entry[1].is_empty() and not _icon_map.is_empty():
		_watch.append(weakref(n))
		if enabled and mi1_icons:
			_check_textures(n)


func _foreign(n: Node) -> bool:
	var now := Time.get_ticks_msec()
	if now - _foreign_at > 2000:
		_foreign_at = now
		_foreign_roots.clear()
		for c in get_tree().root.get_children():
			if _is_other_mod(c):
				_foreign_roots.append(c)
	for r in _foreign_roots:
		if is_instance_valid(r) and (r == n or r.is_ancestor_of(n)):
			return true
	return false


func _check_textures(n: Object) -> void:
	for pname in _class_props(n)[1]:
		var t = n.get(pname)
		if t is CompressedTexture2D and not _icon_state.has(t) and not _icon_failed.has(t) \
				and not _icon_queued.has(t) and _icon_map.has(t.resource_path):
			_icon_queued[t] = true
			_icon_pending.append(t)


func _scan_theme(t) -> void:
	if t == null or not (t is Theme):
		return
	var id: int = t.get_instance_id()
	if _seen.has(id):
		return
	_seen[id] = true
	for type in t.get_stylebox_type_list():
		for sname in t.get_stylebox_list(type):
			_scan_style(t.get_stylebox(sname, type))


func _scan_style(sb) -> void:
	if sb == null:
		return
	var id: int = sb.get_instance_id()
	if _seen.has(id):
		return
	_seen[id] = true
	if sb.has_meta(&"mi2r_own"):
		return
	if sb.has_meta(ORIG_META) and not _saved.has(sb):
		_saved[sb] = (sb.get_meta(ORIG_META) as Dictionary).duplicate()
		_copies_found += 1
	_new_styles += 1
	if sb is StyleBoxTexture:
		if sb.texture is CompressedTexture2D or sb.texture is ImageTexture:
			_texboxes[sb] = true
			if enabled:
				var t_box := Time.get_ticks_usec()
				_style_texbox(sb)
				_us_texbox += Time.get_ticks_usec() - t_box
	elif sb is StyleBoxFlat:
		_flats[sb] = true
		if sb.skew != Vector2.ZERO:
			_slanted += 1
		if enabled:
			var t_flat := Time.get_ticks_usec()
			_style_flat(sb)
			_us_flat += Time.get_ticks_usec() - t_flat


func _apply_globals(on: bool) -> void:
	_place_version(on and look == "crafted")
	_frame(on and look == "crafted" and tidy_frame)
	var bg := get_tree().root.get_node_or_null("Main/Background")
	if bg != null:
		if on and mi1_theme and mi1_plain_background:
			_put(bg, &"visible", false)
		else:
			_restore(bg)
	var base := get_tree().root.get_node_or_null("Main/PanelContainer") as Control
	if base != null:
		var sb = base.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			if on and mi1_theme and mi1_plain_background:
				_put(sb, &"bg_color", MI1_PAGE)
			else:
				_restore(sb)


func _place_version(on: bool) -> void:
	var v := get_tree().root.get_node_or_null("Main/GameVersion/Container/Control/Background") as Control
	if v == null:
		return
	var view := get_viewport().get_visible_rect().size
	if on:
		if _version_box == null:
			_version_box = StyleBoxFlat.new()
			_version_box.bg_color = Color("#14110e", 0.94)
			_version_box.border_color = TRIM
			_version_box.border_width_left = 1
			_version_box.border_width_bottom = 1
			_version_box.corner_radius_bottom_left = 5
			_version_box.content_margin_left = 9.0
			_version_box.content_margin_right = 9.0
			_version_box.content_margin_top = 1.0
			_version_box.content_margin_bottom = 1.0
			_version_box.set_meta(&"mi2r_own", true)
		_version_box.border_color = TRIM
		_put(v, &"theme_override_styles/panel", _version_box)
		var row := v.get_child(0) as Control if v.get_child_count() > 0 else null
		var inner := row.get_combined_minimum_size() if row != null else Vector2(160, 17)
		var size := Vector2(inner.x + 18.0, inner.y + 2.0)
		var parent := v.get_parent() as Control
		if not (_saved.get(v, {}) as Dictionary).has(&"offset_left") and 				(v.global_position.x < 0.0 or v.global_position.x + v.size.x > view.x or v.global_position.y < 0.0):
			var w := v.size.x
			v.offset_left = -w / 2.0
			v.offset_right = w / 2.0
			v.offset_top = 0.0
			v.offset_bottom = v.size.y
		var ps := parent.size if parent != null else view
		var pos := Vector2(view.x - size.x, 60.0) - (parent.global_position if parent != null else Vector2.ZERO)
		_put(v, &"offset_left", pos.x - v.anchor_left * ps.x)
		_put(v, &"offset_top", pos.y - v.anchor_top * ps.y)
		_put(v, &"offset_right", pos.x + size.x - v.anchor_right * ps.x)
		_put(v, &"offset_bottom", pos.y + size.y - v.anchor_bottom * ps.y)
	else:
		for side in [&"offset_left", &"offset_top", &"offset_right", &"offset_bottom"]:
			_unput(v, side)
		_unput(v, &"theme_override_styles/panel")
	var main := get_tree().root.get_node_or_null("Main")
	var gv := main.get_node_or_null("GameVersion") if main != null else null
	var app := main.get_node_or_null("ApplicationViewContainer") if main != null else null
	if gv == null or app == null:
		return
	var layer := gv.get_node_or_null("Container") as CanvasItem
	if on:
		if layer != null:
			_put(layer, &"z_index", 0)
		if _version_next == null:
			var nxt: Node = main.get_child(gv.get_index() + 1) if gv.get_index() + 1 < main.get_child_count() else null
			_version_next = weakref(nxt) if nxt != null else weakref(main)
		if gv.get_index() != app.get_index() + 1:
			main.move_child(gv, app.get_index() + 1)
	else:
		if layer != null:
			_unput(layer, &"z_index")
		if _version_next != null:
			var nxt = _version_next.get_ref()
			var to := main.get_child_count() - 1
			if nxt != null and nxt != main and is_instance_valid(nxt) and nxt.get_parent() == main:
				to = nxt.get_index() - (1 if gv.get_index() < nxt.get_index() else 0)
			main.move_child(gv, to)
			_version_next = null


const HEADER := "Main/ApplicationViewContainer/GameView/MainContainer/VBoxContainer/Header"
const FOOTER_TRACKERS := "Main/ApplicationViewContainer/GameView/MainContainer/VBoxContainer/Footer/HBoxContainer/TrackerView/HBoxContainer"
const SIDEBAR_GROUPS := "Main/ApplicationViewContainer/GameView/MainContainer/VBoxContainer/MiddleContainer/VBoxContainer/HBoxContainer/MarginContainer/GameSidebarLegacy/MarginContainer/SidebarMainContainer/OptionsMainContainer/ScrollContainer/MarginContainer/OptionsContainer"
const DOCK_RECT := Rect2(74, 5, 404, 44)
const DOCK_NAV := "PanelContainer/GridContainer/LeftContainer/MarginContainer/NavigationContainer"
const SIDEBAR_HEAD := Color("#b89c6a")
const FOOTER_TIPS := {
	"HBoxContainer/PanelContainer": "Tracking window: the rates in this bar are averaged over this period.",
	"MainScrollContainer/MainHBoxContainer/ActionContainer/PanelContainer": "Current action",
	"MainScrollContainer/MainHBoxContainer/ExperienceView/PanelContainer": "Experience: level, time to the next level, and XP per hour",
	"MainScrollContainer/MainHBoxContainer/BankView/PanelContainer": "Bank: gold and items gained or used per hour",
	"MainScrollContainer/MainHBoxContainer/EquipableView/PanelContainer": "Equipment: ammunition and charges used per hour",
}
var _dock: Panel = null


func _frame(on: bool) -> void:
	var root := get_tree().root
	var teaser := root.get_node_or_null(HEADER + "/PanelContainer/GridContainer/RightContainer/RightContainer/HBoxContainer2/HBoxContainer3") as Control
	if teaser != null:
		if on:
			_put(teaser, &"visible", false)
		else:
			_restore(teaser)
	var trackers := root.get_node_or_null(FOOTER_TRACKERS)
	if trackers != null:
		for rel in FOOTER_TIPS:
			var c := trackers.get_node_or_null(rel) as Control
			if c != null:
				if on and _polish != null:
					_polish.hint(c, FOOTER_TIPS[rel])
				elif on:
					_put(c, &"tooltip_text", FOOTER_TIPS[rel])
					_put(c, &"theme", _tooltip_theme())
				else:
					if _polish != null:
						_polish.unhint(c)
					_restore(c)
	var groups := root.get_node_or_null(SIDEBAR_GROUPS)
	if groups != null:
		var font := _get_title_font() if title_font else null
		for g in groups.get_children():
			var lb := g.get_child(0) as Label if g.get_child_count() > 0 else null
			if lb == null:
				continue
			if on:
				_label_look(lb, font, SIDEBAR_HEAD, 0)
			else:
				_restore(lb)
	_place_dock(on)


func _place_dock(on: bool) -> void:
	var header := get_tree().root.get_node_or_null(HEADER) as Control
	var want := on and header != null and _other_mod_present()
	if not want:
		if _dock != null and is_instance_valid(_dock):
			_dock.queue_free()
		_dock = null
		return
	if _dock == null or not is_instance_valid(_dock):
		_dock = Panel.new()
		_dock.name = "MI2ReskinDock"
		_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dock.add_theme_stylebox_override(&"panel", style_box("well"))
		header.add_child(_dock)
	if not header.resized.is_connected(_fit_dock_later):
		header.resized.connect(_fit_dock_later)
	_fit_dock()


func _fit_dock_later() -> void:
	_fit_dock.call_deferred()


func _fit_dock() -> void:
	if _dock == null or not is_instance_valid(_dock):
		return
	var header := _dock.get_parent() as Control
	var r := DOCK_RECT
	var nav := header.get_node_or_null(DOCK_NAV) as Control
	if nav != null:
		for c in nav.get_children():
			if c is Control and (c as Control).visible:
				var left_of_button := (c as Control).global_position.x - header.global_position.x - 8.0
				r.size.x = minf(r.size.x, left_of_button - r.position.x)
				break
	_dock.position = r.position
	_dock.size = Vector2(maxf(r.size.x, 0.0), r.size.y)
	_dock.visible = r.size.x >= 160.0


func _other_mod_present() -> bool:
	for c in get_tree().root.get_children():
		if _is_other_mod(c):
			return true
	return false


func _is_other_mod(c: Node) -> bool:
	if c.is_in_group(&"mi2_reskin_keep_look"):
		return true
	var nm := str(c.name)
	for p in other_mods:
		if nm.begins_with(p):
			return true
	return false


func dock_rect() -> Rect2:
	if _dock == null or not is_instance_valid(_dock) or not enabled or not _dock.visible:
		return Rect2()
	return Rect2(_dock.global_position, _dock.size).grow(-4)


func _note_track(n: Node) -> void:
	var found: Array = []
	if n is Range and n is Control:
		for sname in [&"background", &"slider"]:
			if (n as Control).has_theme_stylebox(sname):
				found.append((n as Control).get_theme_stylebox(sname))
	var scr = n.get_script()
	if scr != null:
		var has_bg = _has_bg_style.get(scr)
		if has_bg == null:
			has_bg = false
			for prop in n.get_property_list():
				if prop["name"] == "BackgroundStyle":
					has_bg = true
					break
			_has_bg_style[scr] = has_bg
		if has_bg:
			var bs = n.get(&"BackgroundStyle")
			if bs is StyleBox:
				found.append(bs)
	for sb in found:
		if sb is StyleBoxFlat and not _tracks.has(sb):
			_tracks[sb] = true
			if enabled and _flats.has(sb):
				_style_flat(sb)


func _style_flat(f: StyleBoxFlat) -> void:
	if straighten and _orig(f, &"skew") != Vector2.ZERO:
		_put(f, &"skew", Vector2.ZERO)
		if crisp_edges and corner_radius <= 0 and _square(f):
			_put(f, &"anti_aliasing", false)
	var r := corner_radius
	if mi1_theme and r < 0 and int(_orig(f, &"corner_radius_top_left")) > 0:
		r = panel_radius
	if r >= 0:
		for p in [&"corner_radius_top_left", &"corner_radius_top_right", &"corner_radius_bottom_right",
				&"corner_radius_bottom_left"]:
			_put(f, p, r)
	var bg: Color = _orig(f, &"bg_color")
	if colours != "mi2":
		bg = _theme_color(bg)
		if _tracks.has(f) and bg.s < 0.45:
			bg = Color(Color(PALETTES[colours][2]), bg.a)
	_put(f, &"bg_color", _see_through(bg))
	if colours != "mi2":
		if f.border_width_left + f.border_width_top + f.border_width_right + f.border_width_bottom > 0:
			_put(f, &"border_color", _theme_color(_orig(f, &"border_color")))
	if look == "crafted":
		_style_flat_role(f)


func _style_texbox(sb: StyleBoxTexture) -> void:
	if not flatten_textures:
		return
	var tex = _orig(sb, &"texture")
	var sides := ["left", "top", "right", "bottom"]
	var extra := SOFT_PADDING if look == "crafted" and preset == "soft" and _role_of(sb) in ["card", "frame"] else 0.0
	for s in sides:
		var cm: float = _orig(sb, StringName("content_margin_" + s))
		if cm < 0.0:
			cm = float(_orig(sb, StringName("texture_margin_" + s)))
		_put(sb, StringName("content_margin_" + s), cm + extra)
	var info := _texture_info(tex, _orig(sb, &"region_rect"))
	var opaque: Rect2i = info[1]
	var size: Vector2i = info[2]
	var pad := [opaque.position.x, opaque.position.y, size.x - opaque.end.x, size.y - opaque.end.y]
	var margins := []
	for i in 4:
		var tm: float = _orig(sb, StringName("texture_margin_" + sides[i]))
		if tm <= 0.0:
			pad[i] = int(round(pad[i] * _stretch_guess(sb, size, i)))
		pad[i] = clampi(pad[i], 0, 64)
	if _rpath(tex).to_lower().contains("/notifications/"):
		pad = [0, 0, 0, 0]
	var c: Color = info[0] * _orig(sb, &"modulate_color")
	if colours != "mi2":
		c = _theme_color(c)
	c = _see_through(c)
	var tex2: Texture2D
	var inner := panel_radius + 1
	if look == "crafted":
		var L := _look(_role_of(sb), Color(c.r, c.g, c.b))
		tex2 = _crafted_texture(L, pad)
		inner = _look_m(L)
		c = Color(1, 1, 1, c.a)
	else:
		tex2 = _panel_texture(panel_radius, panel_border, pad)
	for i in 4:
		margins.append(pad[i] + inner)
	_put(sb, &"texture", tex2)
	_put(sb, &"region_rect", Rect2())
	_put(sb, &"axis_stretch_horizontal", StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH)
	_put(sb, &"axis_stretch_vertical", StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH)
	_put(sb, &"draw_center", true)
	for i in 4:
		_put(sb, StringName("texture_margin_" + sides[i]), float(margins[i]))
	_put(sb, &"modulate_color", c)


func _see_through(c: Color) -> Color:
	if panel_opacity < 1.0 and c.s < 0.45 and c.v < 0.45:
		c.a *= panel_opacity
	return c


const PALETTES := {"mi2": [0.0, 0.0, "#000000", 1.0], "slate": [0.0, 0.0, "#161b23", 1.0],
	"graphite": [0.08, 0.04, "#0f1011", 0.95], "midnight": [0.63, 0.32, "#0b0d14", 0.9]}
const ACCENTS := {"sand": ["#5d5850", "#c9b48c"], "gold": ["#7a5f38", "#c9a45c"], "silver": ["#5c6168", "#b8bec6"]}

func _theme_color(c: Color) -> Color:
	if colours == "mi2":
		return c
	if colours == "slate":
		return _mi1_color(c)
	var bluish := c.h > 0.40 and c.h < 0.72
	if keep_teal_headers and bluish and c.s > 0.35:
		return c
	if c.s > 0.35 and not (bluish and c.v < 0.6):
		return c
	if c.v >= 0.6:
		return c
	var p: Array = PALETTES[colours]
	return Color.from_hsv(p[0], p[1], c.v * float(p[3]), c.a)


func _mi1_color(c: Color) -> Color:
	var bluish := c.h > 0.40 and c.h < 0.72
	if keep_teal_headers and bluish and c.s > 0.35:
		return c
	if c.s > 0.35 and not (bluish and c.v < 0.6):
		return c
	var out: Color
	if c.v < 0.13:
		out = MI1_INSET
	elif c.v < 0.24:
		out = MI1_PANEL
	elif c.v < 0.6:
		out = MI1_HEADER
	else:
		return c
	out.a = c.a
	return out


func _panel_texture(r: int, border: float, pad: Array) -> ImageTexture:
	var key := "%d:%.2f:%s" % [r, border, pad]
	if _panel_textures.has(key):
		return _panel_textures[key]
	var n := 2 * r + 3
	var img := Image.create(pad[0] + n + pad[2], pad[1] + n + pad[3], false, Image.FORMAT_RGBA8)
	var half := n / 2.0
	for y in n:
		for x in n:
			var q := Vector2(absf(x + 0.5 - half), absf(y + 0.5 - half)) - Vector2(half - r, half - r)
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
			var a := clampf(0.5 - d, 0.0, 1.0)
			var shade := 1.0 - border if d > -1.0 and border > 0.0 else 1.0
			img.set_pixel(pad[0] + x, pad[1] + y, Color(shade, shade, shade, a))
	var t := ImageTexture.create_from_image(img)
	_panel_textures[key] = t
	return t


func _texture_info(tex, region: Rect2) -> Array:
	var path := _rpath(tex) if tex != null else ""
	var key = ("%s|%s" % [path, region]) if path.begins_with("res://") else [tex, region]
	if _tex_info.has(key):
		return _tex_info[key]
	if key is String and _disk_info.has(key):
		var d: Array = _disk_info[key]
		var saved := [Color(d[0], d[1], d[2]), Rect2i(d[3], d[4], d[5], d[6]), Vector2i(d[7], d[8])]
		_tex_info[key] = saved
		return saved
	var t_info := Time.get_ticks_usec()
	var c := Color(0.16, 0.17, 0.19)
	var img: Image = null
	if tex != null:
		img = tex.get_image()
	var size := Vector2i(1, 1)
	var opaque := Rect2i(0, 0, 1, 1)
	if img != null:
		if img.is_compressed():
			img.decompress()
		if region.has_area():
			img = img.get_region(Rect2i(region))
		var w := img.get_width()
		var h := img.get_height()
		size = Vector2i(w, h)
		opaque = Rect2i(0, 0, w, h)
		var step := maxi(1, int(sqrt(w * h / 6000.0)))
		var sum := Vector3.ZERO
		var count := 0
		var lo := Vector2i(w, h)
		var hi := Vector2i(-1, -1)
		for y in range(0, h, step):
			for x in range(0, w, step):
				var p := img.get_pixel(x, y)
				if p.a <= 0.5:
					continue
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
				if p.a > 0.6 and x >= w / 4 and x < w - w / 4 and y >= h / 4 and y < h - h / 4:
					sum += Vector3(p.r, p.g, p.b)
					count += 1
		if hi.x >= 0:
			opaque = Rect2i(lo, hi - lo + Vector2i(step, step)).intersection(Rect2i(0, 0, w, h))
		if count > 0:
			sum /= count
			c = Color(sum.x, sum.y, sum.z)
	var info := [c, opaque, size]
	_tex_info[key] = info
	if key is String:
		_disk_info[key] = [c.r, c.g, c.b, opaque.position.x, opaque.position.y, opaque.size.x, opaque.size.y, size.x, size.y]
		_disk_dirty = true
	_us_info += Time.get_ticks_usec() - t_info
	return info


const MISSING_ART := "res://Assets/Icons/missing_artwork.png"
var _fallback_tex: ImageTexture = null
var _fallbacks: Array = []

func _fallback_icon() -> ImageTexture:
	if _fallback_tex != null:
		return _fallback_tex
	var w := 64
	var img := Image.create(w, w, false, Image.FORMAT_RGBA8)
	var c := w / 2.0
	var r_out := 27.0
	var rim := 3.5
	for y in w:
		for x in w:
			var acc := Color(0, 0, 0, 0)
			for sy in 4:
				for sx in 4:
					var px := x + (sx + 0.5) / 4.0
					var py := y + (sy + 0.5) / 4.0
					var d := Vector2(px - c, py - c).length()
					if d > r_out:
						continue
					var col: Color
					var diamond := absf(px - c) / 11.0 + absf(py - c) / 15.0
					if d > r_out - rim:
						var lit := clampf(0.5 - ((px - c) + (py - c)) / (2.0 * r_out), 0.0, 1.0)
						col = TRIM.darkened(0.25).lerp(GOLD, lit * 0.6)
					elif diamond <= 1.0:
						col = GOLD.lightened(0.2) if (px - c) + (py - c) < 0.0 else GOLD.darkened(0.15)
					else:
						col = Color("#1d1a16").lerp(Color("#2c2721"), clampf(0.5 - (py - c) / (2.0 * r_out), 0.0, 1.0))
					acc += Color(col.r, col.g, col.b, 1.0)
			if acc.a > 0.0:
				img.set_pixel(x, y, Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, acc.a / 16.0))
	_fallback_tex = ImageTexture.create_from_image(img)
	return _fallback_tex


func _apply_fallbacks(on: bool) -> void:
	var i := 0
	while i < _fallbacks.size():
		var n = _fallbacks[i][0].get_ref()
		if n == null or not is_instance_valid(n):
			_fallbacks[i] = _fallbacks[_fallbacks.size() - 1]
			_fallbacks.pop_back()
			continue
		if on:
			_put(n, _fallbacks[i][1], _fallback_icon())
		else:
			_unput(n, _fallbacks[i][1])
		i += 1


const PICTURE_INFO_PATH := "user://mi2_reskin_picture_info.json"

func _load_disk_info() -> void:
	_disk_info = {}
	var f := FileAccess.open(PICTURE_INFO_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary and str(data.get("game", "")) == _game_version() and data.get("pictures") is Dictionary:
		_disk_info = data["pictures"]


func _save_disk_info() -> void:
	if not _disk_dirty:
		return
	_disk_dirty = false
	var f := FileAccess.open(PICTURE_INFO_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"game": _game_version(), "pictures": _disk_info}))


func _game_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "")) + "/" + 		str(ProjectSettings.get_setting("application/config/name", ""))


func _stretch_guess(sb: StyleBoxTexture, size: Vector2i, side: int) -> float:
	var span: float = _style_users.get(sb, Vector2.ZERO)[side % 2]
	var tex_span := float(size.x if side % 2 == 0 else size.y)
	if span <= 0.0 or tex_span <= 0.0:
		return 1.0
	return clampf(span / tex_span, 0.25, 4.0)


func _role_of(sb) -> String:
	var path := _rpath(sb).to_lower()
	if sb is StyleBoxFlat:
		if path.ends_with("default_info_icon_panel.tres"):
			return "slot"
		if path.contains("info_icon"):
			return "slot_other"
		if path.contains("button") and path.contains("disabled"):
			return "button_disabled"
		if path.contains("button"):
			return "button_flat"
		return "flat"
	if not (sb is StyleBoxTexture):
		return "other"
	var tex := _rpath(_orig(sb, &"texture")).to_lower()
	if tex.contains("actionbutton"):
		return "go"
	if tex.contains("cancelbutton"):
		return "stop"
	if tex.contains("/buttons/") or path.contains("btn_"):
		if tex.contains("disabled") or path.contains("disabled"):
			return "locked"
		if path.contains("hover_pressed"):
			return "selected"
		if tex.contains("pressed") or path.contains("pressed"):
			return "selected"
		if tex.contains("hover"):
			return "button_hover"
		return "button"
	if tex.contains("/tabcontainer/"):
		return "tab_on" if tex.contains("pressed") else "tab"
	if tex.contains("tooltip") or tex.contains("/notifications/"):
		return "tooltip"
	if tex.contains("hud-bottom"):
		return "footer"
	if path.contains("header") or path.contains("subcategory") or tex.contains("frameheader") or tex.contains("woodcutting_10"):
		return "header"
	var c: Color = _texture_info(_orig(sb, &"texture"), _orig(sb, &"region_rect"))[0] * _orig(sb, &"modulate_color")
	if c.h > 0.06 and c.h < 0.18 and c.s > 0.12 and c.v > 0.55:
		return "plaque"
	var used: Vector2 = _style_users.get(sb, Vector2.ZERO)
	if used.x >= 300.0 and used.y >= 300.0:
		return "frame"
	return "card"


func _look(role: String, fill: Color) -> Dictionary:
	var dark := Color(0.04, 0.04, 0.045)
	var L := {"r": panel_radius, "fill": fill, "rim": fill.darkened(0.45), "rim_w": 1,
		"trim": Color(0, 0, 0, 0), "trim_w": 0, "hi": 0.0, "hi_rows": 0, "lo": 0.0, "lo_rows": 0,
		"accent": Color(0, 0, 0, 0), "accent_rows": 0, "accent_top_rows": 0, "grad": 0.04, "rivets": false,
		"caps": false}
	match role:
		"frame":
			L.r = maxi(panel_radius, 6)
			L.rim = dark
			L.trim = TRIM
			L.trim_w = 1 if preset == "soft" else 2
			L.hi = 0.05
			L.hi_rows = 1
			L.rivets = preset != "soft"
		"card":
			L.hi = 0.06
			L.hi_rows = 1
			if preset == "gilded":
				L.trim = GOLD.darkened(0.5)
				L.trim_w = 1
		"header", "tab_on":
			L.r = mini(panel_radius, 4)
			L.rim = dark
			L.grad = 0.10
			L.hi = 0.12
			L.hi_rows = 1
			L.accent = GOLD
			L.accent_rows = 1 if preset == "soft" else 2
			L.caps = preset != "soft" and role == "header"
		"plaque":
			L.r = mini(panel_radius, 4)
			L.rim = Color("#3b2a18")
			L.hi = 0.10
			L.hi_rows = 1
			L.lo = 0.12
			L.lo_rows = 2
		"button", "button_hover", "go", "stop", "tab":
			L.r = mini(panel_radius, 4)
			L.rim = dark
			L.hi = 0.14
			L.hi_rows = 2
			L.lo = 0.30
			L.lo_rows = 2
			L.grad = 0.08
			if role == "button_hover":
				L.fill = fill.lightened(0.08)
				L.trim = TRIM
				L.trim_w = 1
		"selected":
			L.r = mini(panel_radius, 4)
			L.rim = dark
			L.trim = GOLD
			L.trim_w = 1
			L.lo = 0.0
			L.hi = -0.15
			L.hi_rows = 2
		"locked":
			L.r = mini(panel_radius, 4)
			var g := fill.get_luminance()
			L.fill = Color(g, g, g).lerp(fill, 0.25).darkened(0.30)
			L.rim = L.fill.lightened(0.12)
			L.grad = 0.0
			L.hi = -0.45
			L.hi_rows = 2
		"tooltip":
			L.rim = dark
			L.trim = TRIM
			L.trim_w = 1
		"footer":
			L.r = 0
			L.rim = dark
			L.accent = GOLD.darkened(0.1)
			L.accent_top_rows = 2
			L.grad = 0.06
		"slot":
			L.r = 3
			L.fill = Color("#0f0f11")
			L.rim = Color("#4a3f30")
			L.grad = 0.0
			L.hi = -0.35
			L.hi_rows = 1
		"well":
			L.fill = Color("#0d0c0b")
			L.rim = TRIM.darkened(0.1)
			L.grad = 0.0
			L.hi = -0.6
			L.hi_rows = 3
	if preset == "soft":
		_soften(L, role, dark)
	return L


const SOFT_PADDING := 2.0
const SOFT_PLAQUE := Color("#2b2824")
const SOFT_PLAQUE_TEXT := Color("#e4dccd")

func _soften(L: Dictionary, role: String, _dark: Color) -> void:
	L.trim = Color(0, 0, 0, 0)
	L.trim_w = 0
	L.rivets = false
	L.caps = false
	L.accent_rows = 0
	L.accent_top_rows = 0
	L.lo = 0.0
	L.lo_rows = 0
	L.grad = 0.025
	if float(L.hi) >= 0.0:
		L.hi = minf(float(L.hi), 0.04)
		L.hi_rows = mini(int(L.hi_rows), 1)
	else:
		L.hi = float(L.hi) * 0.5
	var f: Color = L.fill
	match role:
		"frame", "card", "tooltip", "well":
			L.r = maxi(panel_radius, 8)
		"header", "tab_on", "tab":
			L.r = maxi(mini(panel_radius, 6), 4)
			f = _mute(f, 0.35).darkened(0.06)
			if f.v < 0.1:
				f = f.lerp(_theme_color(Color("#2a2724")), 0.85)
		"plaque":
			L.r = maxi(mini(panel_radius, 6), 4)
			f = _theme_color(SOFT_PLAQUE)
			L.hi = 0.0
		"button", "button_hover":
			L.r = maxi(mini(panel_radius, 6), 4)
			if role == "button_hover":
				f = f.lightened(0.06)
		"go", "stop":
			L.r = maxi(mini(panel_radius, 6), 4)
			f = _mute(f, 0.45).darkened(0.10)
		"selected":
			L.r = maxi(mini(panel_radius, 6), 4)
			f = f.lightened(0.08)
		"locked", "slot":
			L.r = maxi(mini(panel_radius, 4), 3)
	L.fill = f
	L.rim = GOLD.darkened(0.2) if role == "selected" else f.darkened(0.18)


func _mute(c: Color, amount: float) -> Color:
	var g := c.get_luminance()
	return Color(c.lerp(Color(g, g, g), amount), c.a)


func _dark_plaques() -> bool:
	return enabled and look == "crafted" and preset == "soft"


var _plaque_memo := {}

func _plaque_text(lb: Label) -> Color:
	if not _dark_plaques():
		return Color(0, 0, 0, 0)
	var start := lb.get_parent()
	if start == null:
		return Color(0, 0, 0, 0)
	var sid := start.get_instance_id()
	if not _plaque_memo.has(sid):
		if _plaque_memo.size() > 20000:
			_plaque_memo.clear()
		var on_plaque := false
		var p := start
		for _i in 4:
			if p == null or not (p is Control) or p is BaseButton:
				break
			var sb = (p as Control).get_theme_stylebox(&"panel") if (p as Control).has_theme_stylebox(&"panel") else null
			if sb is StyleBoxTexture and (_texboxes.has(sb) or sb.texture is CompressedTexture2D):
				on_plaque = _role_of(sb) == "plaque"
				break
			p = p.get_parent()
		_plaque_memo[sid] = on_plaque
	return SOFT_PLAQUE_TEXT if _plaque_memo[sid] else Color(0, 0, 0, 0)


const BODY_WEIGHTS := {"Thin": 100, "ExtraLight": 200, "Light": 300, "Regular": 400, "Italic": 400, "Medium": 500,
	"SemiBold": 600, "Bold": 700, "ExtraBold": 800, "Black": 900}
var _body_active := ""
var _body_fonts := {}
var _body_done := {}

func _apply_body_font(family: String) -> void:
	for c in _body_done.keys():
		if is_instance_valid(c):
			for prop in [&"label_settings", &"theme_override_fonts/font", &"theme_override_fonts/normal_font",
					&"theme_override_fonts/bold_font"]:
				if (_saved.get(c, {}) as Dictionary).has(prop):
					_unput(c, prop)
	_body_done.clear()
	_body_fonts.clear()
	_body_active = family
	if family != "":
		var root := get_tree().root
		for cls in ["Label", "Button", "RichTextLabel", "LineEdit"]:
			for n in root.find_children("*", cls, true, false):
				if not _foreign(n):
					_body_fonts_of(n as Control)


func _body_fonts_of(c: Control) -> void:
	if _body_done.has(c) or c.get_meta(&"mi2r_own", false):
		return
	if c is Label:
		var lb := c as Label
		var ls: LabelSettings = _orig(lb, &"label_settings")
		if ls != null:
			if ls.font != null and not _title_labels.has(lb.get_instance_id()):
				var nf := _body_for(ls.font)
				if nf != null:
					var key := [ls, nf]
					if not _title_settings.has(key):
						var copy: LabelSettings = ls.duplicate()
						copy.font = nf
						_title_settings[key] = copy
					_put(lb, &"label_settings", _title_settings[key])
					_body_done[c] = true
			return
	if c is Label or c is Button or c is LineEdit or c is RichTextLabel:
		var names := [&"normal_font", &"bold_font"] if c is RichTextLabel else [&"font"]
		for nm in names:
			var prop := StringName("theme_override_fonts/" + nm)
			if (_saved.get(c, {}) as Dictionary).has(prop) or not c.has_theme_font(nm):
				continue
			var nf := _body_for(c.get_theme_font(nm))
			if nf != null:
				_put(c, prop, nf)
				_body_done[c] = true


func _body_for(font: Font) -> Font:
	if font == null:
		return null
	if _body_fonts.has(font):
		return _body_fonts[font]
	var base = font
	while base is FontVariation and (base as FontVariation).base_font != null:
		base = (base as FontVariation).base_font
	var out: Font = null
	var file := (base as Resource).resource_path.get_file() if base is Resource else ""
	if file.begins_with("Default_"):
		var weight: int = clampi(BODY_WEIGHTS.get(file.trim_prefix("Default_").get_basename(), 400), 400, 700)
		var ff := _body_file(weight)
		if ff != null:
			if font is FontVariation:
				var v := (font as FontVariation).duplicate() as FontVariation
				v.base_font = ff
				out = v
			else:
				out = ff
	_body_fonts[font] = out
	return out


var _body_files := {}

func _body_file(weight: int) -> FontFile:
	var key := "%s-%d" % [_body_active, weight]
	if not _body_files.has(key):
		var path := FONT_DIR + key + ".ttf"
		_body_files[key] = _crisp_font(path) if FileAccess.file_exists(path) else null
	return _body_files[key]


func _title_font_or_null() -> Font:
	return _get_title_font() if title_font else null


func _titles_wanted() -> bool:
	return enabled and look == "crafted" and ((title_font and _get_title_font() != null) or _dark_plaques())


func _look_m(L: Dictionary) -> int:
	var edge: int = L.rim_w + L.trim_w
	var m := maxi(L.r, edge + maxi(maxi(L.hi_rows, L.lo_rows), maxi(L.accent_rows, L.accent_top_rows))) + 1
	if L.rivets:
		m = maxi(m, edge + 6)
	if L.caps:
		m = maxi(m, edge + 8)
	return m


func _crafted_texture(L: Dictionary, pad: Array) -> ImageTexture:
	var key := "c:%s:%s" % [L, pad]
	if _panel_textures.has(key):
		return _panel_textures[key]
	var r: int = L.r
	var edge: int = L.rim_w + L.trim_w
	var m := _look_m(L)
	var w := 2 * m + 1
	var h := 2 * m + GRAD_ROWS
	var img := Image.create(pad[0] + w + pad[2], pad[1] + h + pad[3], false, Image.FORMAT_RGBA8)
	var hw := w / 2.0
	var hh := h / 2.0
	var grad: float = L.grad
	for y in h:
		var shade := grad * (1.0 - 2.0 * (y + 0.5) / h)
		for x in w:
			var q := Vector2(absf(x + 0.5 - hw), absf(y + 0.5 - hh)) - Vector2(hw - r, hh - r)
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
			var a := clampf(0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var depth := -d
			var c: Color = L.fill
			c = c.lightened(shade) if shade >= 0.0 else c.darkened(-shade)
			var from_top: int = y - edge
			var from_bottom: int = h - 1 - y - edge
			if from_top >= 0 and from_top < L.hi_rows:
				c = c.lightened(L.hi) if L.hi >= 0.0 else c.darkened(-L.hi)
			if from_bottom >= 0 and from_bottom < L.lo_rows:
				c = c.darkened(L.lo)
			if from_bottom >= 0 and from_bottom < L.accent_rows:
				c = L.accent
			if y < L.accent_top_rows:
				c = L.accent
			if depth < L.rim_w:
				c = L.rim
			elif depth < edge:
				c = c.lerp(L.trim, (L.trim as Color).a)
			c.a = a
			img.set_pixel(pad[0] + x, pad[1] + y, c)
	if L.rivets:
		var o := edge + 2
		for corner in [Vector2i(o, o), Vector2i(w - o - 2, o), Vector2i(o, h - o - 2), Vector2i(w - o - 2, h - o - 2)]:
			for dy in 2:
				for dx in 2:
					var rc: Color = GOLD.darkened(0.35)
					if dx == 0 and dy == 0:
						rc = GOLD.lightened(0.25)
					elif dx == 1 and dy == 1:
						rc = GOLD.darkened(0.6)
					img.set_pixel(pad[0] + corner.x + dx, pad[1] + corner.y + dy, rc)
	if L.caps:
		var gap := 2
		var cy: int = h - edge - L.accent_rows - gap - 2
		for cx in [edge + gap + 1, w - 1 - edge - gap - 1]:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var px := Vector2i(pad[0] + cx + dx, pad[1] + cy + dy)
					var sc: Color
					if dx != 0 and dy != 0:
						sc = img.get_pixelv(px).lerp(GOLD.darkened(0.45) if dx + dy > -2 else GOLD, 0.5)
					elif dx == 0 and dy == 0:
						sc = GOLD.lightened(0.35)
					elif dx < 0 or dy < 0:
						sc = GOLD.lightened(0.05)
					else:
						sc = GOLD.darkened(0.4)
					sc.a = 1.0
					img.set_pixelv(px, sc)
	var t := ImageTexture.create_from_image(img)
	_panel_textures[key] = t
	return t


func _style_flat_role(f: StyleBoxFlat) -> void:
	match _role_of(f):
		"slot":
			_put(f, &"bg_color", Color(0.06, 0.06, 0.07, 0.85))
			_put(f, &"border_color", Color("#4a3f30"))
			for p in [&"corner_radius_top_left", &"corner_radius_top_right", &"corner_radius_bottom_right",
					&"corner_radius_bottom_left"]:
				_put(f, p, 3)
		"slot_other":
			if (_orig(f, &"corner_radius_top_left") as int) < 3:
				for p in [&"corner_radius_top_left", &"corner_radius_top_right", &"corner_radius_bottom_right",
						&"corner_radius_bottom_left"]:
					_put(f, p, 3)
		"button_disabled":
			var bc: Color = _orig(f, &"border_color")
			_put(f, &"border_color", Color(0.29, 0.28, 0.26, bc.a))
			for p in [&"corner_radius_top_left", &"corner_radius_top_right", &"corner_radius_bottom_right",
					&"corner_radius_bottom_left"]:
				_put(f, p, 4)
		"button_flat":
			_put(f, &"border_color", (_orig(f, &"border_color") as Color).lerp(TRIM, 0.5))
			for p in [&"corner_radius_top_left", &"corner_radius_top_right", &"corner_radius_bottom_right",
					&"corner_radius_bottom_left"]:
				_put(f, p, 4)


func _check_titles() -> void:
	if _labels.is_empty():
		return
	if not _titles_wanted():
		_labels.clear()
		return
	var font := _title_font_or_null()
	var batch := _labels.slice(0, 800)
	_labels = _labels.slice(800)
	for w in batch:
		var lb = w.get_ref()
		if lb == null or not is_instance_valid(lb) or not lb.is_inside_tree():
			continue
		_title_one(lb, font)
	_header_memo.clear()


func _title_one(lb: Label, font: Font) -> void:
	var id := lb.get_instance_id()
	var kind: String = _label_kind.get(id, "?")
	if kind == "?":
		kind = _header_label(lb)
		if _label_kind.size() > 20000:
			_label_kind.clear()
		_label_kind[id] = kind
	match kind:
		"title":
			var col := _plaque_text(lb)
			if font == null and col.a == 0.0:
				return
			_label_look(lb, font, col, TITLE_GROW if font != null else 0)
			_titles += 1
			_title_labels[lb.get_instance_id()] = weakref(lb)
		"caption":
			var col := _plaque_text(lb)
			var cf := _get_caption_font() if title_font else null
			if cf != null or col.a > 0.0:
				_label_look(lb, cf, col, 1 if cf != null else 0)
				_title_labels[lb.get_instance_id()] = weakref(lb)


func _is_title(lb: Label) -> bool:
	return _header_label(lb) == "title"


func _header_label(lb: Label) -> String:
	return ("title" if _label_size(lb) >= 13 else "caption") if _on_header(lb) else ""


func _on_header(lb: Label) -> bool:
	var start := lb.get_parent()
	if start == null:
		return false
	var sid := start.get_instance_id()
	if _header_memo.has(sid):
		return _header_memo[sid]
	var r := _on_header_from(start)
	_header_memo[sid] = r
	return r


func _on_header_from(start: Node) -> bool:
	var p := start
	for _i in 4:
		if p == null or not (p is Control) or p is BaseButton or str(p.name).containsn("button"):
			return false
		var sb = (p as Control).get_theme_stylebox(&"panel") if (p as Control).has_theme_stylebox(&"panel") else null
		if sb is StyleBoxTexture and (_texboxes.has(sb) or sb.texture is CompressedTexture2D):
			if _rpath(sb).containsn("dropdown") or _rpath(_orig(sb, &"texture")).containsn("dropdown"):
				return false
			return _role_of(sb) in ["header", "plaque", "tab_on"]
		p = p.get_parent()
	return false


func _label_look(lb: Label, font: Font, color: Color, grow: int) -> void:
	var ls: LabelSettings = _orig(lb, &"label_settings")
	if ls != null:
		var key := [ls, font, color, grow]
		if not _title_settings.has(key):
			var copy: LabelSettings = ls.duplicate()
			if font != null:
				copy.font = font
			if color.a > 0.0:
				copy.font_color = color
			copy.font_size = ls.font_size + grow
			_title_settings[key] = copy
		_put(lb, &"label_settings", _title_settings[key])
		return
	if font != null:
		_put(lb, &"theme_override_fonts/font", font)
	if color.a > 0.0:
		_put(lb, &"theme_override_colors/font_color", color)
	if grow != 0 and not (_saved.get(lb, {}) as Dictionary).has(&"theme_override_font_sizes/font_size"):
		_put(lb, &"theme_override_font_sizes/font_size", lb.get_theme_font_size(&"font_size") + grow)


func _orig_font_size(lb: Label) -> int:
	var d: Dictionary = _saved.get(lb, {})
	if d.has(&"theme_override_font_sizes/font_size") and d[&"theme_override_font_sizes/font_size"] != null:
		return d[&"theme_override_font_sizes/font_size"]
	return lb.get_theme_font_size(&"font_size")


func _label_size(lb: Label) -> int:
	var ls: LabelSettings = _orig(lb, &"label_settings")
	return ls.font_size if ls != null else lb.get_theme_font_size(&"font_size")


func _crisp_font(path: String) -> FontFile:
	var f := FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	f.multichannel_signed_distance_field = true
	f.msdf_size = 96
	f.msdf_pixel_range = 12
	f.generate_mipmaps = true
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return f


func _get_caption_font() -> Font:
	var path := FONT_DIR + caption_font_file
	if _caption_font == null and caption_font_file != "" and FileAccess.file_exists(path):
		var f := _crisp_font(path)
		if f != null:
			var v := FontVariation.new()
			v.base_font = f
			v.spacing_glyph = caption_spacing
			_caption_font = v
	return _caption_font


func _get_title_font() -> Font:
	var path := FONT_DIR + title_font_file
	if _title_font == null and FileAccess.file_exists(path):
		var f := _crisp_font(path)
		if f != null:
			var v := FontVariation.new()
			v.base_font = f
			v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
			_title_font = v
	return _title_font


func _pages(on: bool) -> void:
	_apply_fallbacks(enabled)
	_collapse_locked(on)
	_center_stacks(on)
	_picture_shadows(on)
	var i := 0
	while i < _page_nodes.size():
		var n = _page_nodes[i].get_ref()
		if n == null or not is_instance_valid(n):
			_page_nodes[i] = _page_nodes[_page_nodes.size() - 1]
			_page_nodes.pop_back()
			continue
		i += 1
		if str(n.name).ends_with("CreatingRecipeContainer"):
			_idle_creating(n, on)
		elif n.name == &"QuestDialogueView":
			_idle_dialogue(n, on)
		elif n.name == &"HuntingCurrentRecipeContainer":
			_idle_hunting(n, on)
		elif n.name == &"CategorySelect" or n.name == &"CategoryButtonContainer":
			_open_category(n, on and remember_category)
		elif n.name == &"BankActiveView":
			_bank_shortcuts(n, on)
		elif n.name == &"FarmingActionView":
			_empty_strips(n, on)
		else:
			_detail_frame(n, on and detail_frame)


func _in_button(n: Node) -> bool:
	var p := n.get_parent()
	for _i in 3:
		if p == null:
			return false
		if p is BaseButton or str(p.get_script().resource_path if p.get_script() != null else "").ends_with("ButtonContainer.cs"):
			return true
		p = p.get_parent()
	return false


func _center_stacks(on: bool) -> void:
	var i := 0
	while i < _text_stacks.size():
		var box = _text_stacks[i].get_ref()
		if box == null or not is_instance_valid(box):
			_text_stacks[i] = _text_stacks[_text_stacks.size() - 1]
			_text_stacks.pop_back()
			continue
		i += 1
		var lines := 0
		for c in box.get_children():
			if c is Label:
				lines += 1
		if lines < 2:
			continue
		for c in box.get_children():
			if not (c is Label):
				continue
			var lb := c as Label
			var hidden_by_us := (_saved.get(lb, {}) as Dictionary).has(&"visible")
			if on and lb.text.strip_edges() == "" and (lb.visible or hidden_by_us):
				if not hidden_by_us:
					if box.custom_minimum_size.y < box.size.y:
						_put(box, &"custom_minimum_size", Vector2(box.custom_minimum_size.x, box.size.y))
					_put(lb, &"visible", false)
			elif hidden_by_us:
				_unput(lb, &"visible")
				_unput(box, &"custom_minimum_size")


func _empty_strips(root: Node, on: bool) -> void:
	if not (root as Control).is_visible_in_tree() and on:
		return
	for p in root.find_children("*", "PanelContainer", true, false):
		var empty: bool = on and _shows_nothing(p)
		if empty and not _blanked.has(p):
			_blanked[p] = true
			_put(p, &"self_modulate", Color(1, 1, 1, 0))
		elif not empty and _blanked.has(p):
			_blanked.erase(p)
			_unput(p, &"self_modulate")


func _shows_nothing(n: Node) -> bool:
	for c in n.get_children():
		if c is Control and (c as Control).visible:
			if c is Container and not (c is PanelContainer) and _shows_nothing(c):
				continue
			return false
	return true


func _picture_shadows(on: bool) -> void:
	var a := 1.0
	if on and picture_shadows == "off":
		a = 0.0
	elif on and picture_shadows == "faint":
		a = 0.2
	var i := 0
	while i < _shadows.size():
		var n = _shadows[i].get_ref()
		if n == null or not is_instance_valid(n):
			_shadows[i] = _shadows[_shadows.size() - 1]
			_shadows.pop_back()
			continue
		i += 1
		if a < 1.0:
			_put(n, &"self_modulate", Color(1, 1, 1, a))
		else:
			_unput(n, &"self_modulate")


const PAGES_PATH := "user://mi2_reskin_pages.json"

func _open_category(sel: Control, on: bool) -> void:
	if not sel.is_visible_in_tree():
		return
	var box: Node = sel if sel.name == &"CategoryButtonContainer" else sel.find_child("CategoryContainer", true, false)
	if box == null:
		return
	var is_empty := false
	var current := ""
	var view := sel.get_parent()
	var empty: Control = null
	for _i in 2:
		if view == null:
			return
		empty = view.find_child("NoCategoryContainer", true, false) as Control
		if empty != null:
			break
		view = view.get_parent()
	if empty != null:
		is_empty = empty.visible
		var header := view.find_child("CategoryHeader", true, false) as Control
		if not is_empty and header != null and header.visible:
			current = _category_key(header, "CategoryName", "CategoryIcon")
	else:
		var list := sel.get_parent().find_child("SubcategoryContainer", true, false) as Control
		if list == null:
			return
		is_empty = _shows_nothing(list)
		if not is_empty:
			for btn in box.get_children():
				if btn is Control and (btn as Control).visible and btn.has_method("GetCurrentStyleBox") 						and btn.call("GetCurrentStyleBox") == btn.get("SelectedStyleBox"):
					current = _category_key(btn, "CategoryName", "CategoryMedia")
					break
	var page := _page_name(sel)
	if not is_empty:
		_cat_tried.erase(sel)
		if current != "" and _categories.get(page, "") != current:
			_categories[page] = current
			_save_pages()
		return
	if not on or _cat_tried.has(sel):
		return
	_cat_tried[sel] = true
	var want: String = _categories.get(page, "")
	var first: Node = null
	var pick: Node = null
	for b in box.get_children():
		if not (b is Control and (b as Control).visible):
			continue
		if b.has_method("InternalPressed"):
			var unlocked := b.get_node_or_null("MarginContainer/UnlockedContainer") as Control
			if unlocked != null and not unlocked.visible:
				continue
		elif not (b is BaseButton) or (b as BaseButton).disabled:
			continue
		if first == null:
			first = b
		if want != "" and _category_key(b, "CategoryName", "CategoryMedia") == want:
			pick = b
			break
	if pick == null:
		pick = first
	if pick == null:
		return
	if pick.has_method("InternalPressed"):
		pick.call("InternalPressed")
	elif (pick as BaseButton).toggle_mode:
		(pick as BaseButton).button_pressed = true
	else:
		(pick as BaseButton).pressed.emit()


func _category_key(n: Node, name_node: String, icon_node: String) -> String:
	var nm := n.find_child(name_node, true, false) as Label
	if nm != null and nm.text != "":
		return nm.text
	var tex: Texture2D = null
	if n is Button:
		tex = (n as Button).icon
	else:
		var ic := n.find_child(icon_node, true, false) as TextureRect
		if ic != null:
			tex = ic.texture
	return tex.resource_path if tex != null else ""


func _page_name(n: Node) -> String:
	var c := n
	while c != null:
		if str(c.name).ends_with("ActiveView"):
			return str(c.name)
		c = c.get_parent()
	return str(n.get_parent().name)


func _load_pages() -> void:
	if FileAccess.file_exists(PAGES_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(PAGES_PATH))
		if d is Dictionary and d.get("categories") is Dictionary:
			_categories = d["categories"]


func _save_pages() -> void:
	var f := FileAccess.open(PAGES_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"categories": _categories}, "\t"))


func _is_empty_detail(n: Node) -> bool:
	var s := str(n.name)
	return s.begins_with("No") and s.ends_with("SelectedView") and n.get_parent() is Container \
		and str(n.get_parent().name).begins_with("Active")


const DETAIL_INSET := [6.0, 4.0, 14.0, -14.0]

func _detail_frame(empty: Control, on: bool) -> void:
	var view := empty.get_parent() as Container
	if view == null:
		return
	var bd := view.get_node_or_null("MI2ReskinBackdrop") as Panel
	if not on:
		if bd != null:
			view.remove_child(bd)
			bd.queue_free()
		return
	if bd == null:
		bd = Panel.new()
		bd.name = "MI2ReskinBackdrop"
		bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := style_box("frame")
		var sides := [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]
		for i in 4:
			sb.set_expand_margin(sides[i], -DETAIL_INSET[i])
		bd.add_theme_stylebox_override(&"panel", sb)
		view.add_child(bd)
		view.move_child(bd, 0)
	bd.visible = not empty.visible


func _collapse_locked(on: bool) -> void:
	var locked := {}
	for w in _locks:
		var lc = w.get_ref()
		if lc == null or not is_instance_valid(lc) or not lc.is_inside_tree():
			continue
		var item := _list_item(lc)
		if item == null:
			continue
		locked[item] = bool(locked.get(item, false)) or lc.visible
	var groups := {}
	for item in locked:
		if locked[item]:
			if not groups.has(item.get_parent()):
				groups[item.get_parent()] = []
			groups[item.get_parent()].append(item)
		elif _collapsed.has(item):
			_collapsed.erase(item)
			_unput(item, &"visible")
	for parent in groups:
		var items: Array = groups[parent]
		items.sort_custom(func(x, y): return x.get_index() < y.get_index())
		var kept := false
		for item in items:
			if not _collapsed.has(item) and not item.visible:
				continue
			if not kept:
				kept = true
				if _collapsed.has(item):
					_collapsed.erase(item)
					_unput(item, &"visible")
			elif on:
				_collapsed[item] = true
				_put(item, &"visible", false)
	if not on:
		for item in _collapsed:
			if is_instance_valid(item):
				_unput(item, &"visible")
		_collapsed.clear()


func _list_item(n: Node) -> Control:
	var c := n
	for _i in 6:
		var p := c.get_parent()
		if p == null:
			return null
		if p is GridContainer or p is FlowContainer or (p is BoxContainer and p.name == &"CategoryContainer"):
			return c as Control
		c = p
	return null


func _idle_creating(c: Control, on: bool) -> void:
	var none := c.get_node_or_null("MarginContainer/PanelContainer/NoRecipeContainer") as Control
	if none == null:
		none = c.get_node_or_null("MarginContainer/PanelContainer/MarginContainer/NoRecipeContainer") as Control
	if on and none != null and none.visible:
		_put(c, &"visible", false)
	elif _saved.has(c):
		_restore(c)


var _hunt_styles := {}

func _idle_hunting(c: Control, on: bool) -> void:
	var margins := c.get_node_or_null("MarginContainer") as MarginContainer
	var panel := c.get_node_or_null("MarginContainer/PanelContainer3") as PanelContainer
	if margins == null or panel == null:
		return
	if not on:
		_unput(panel, &"theme_override_styles/panel")
		_unput(margins, &"theme_override_constants/margin_top")
		for box in panel.find_children("*", "PanelContainer", true, false):
			_unput(box, &"theme_override_styles/panel")
		return
	if margins.get_theme_constant(&"margin_top") < 0:
		_put(margins, &"theme_override_constants/margin_top", 0)
	var beside := c.get_parent().get_node_or_null("HuntingSelectedRecipeContainer/MarginContainer/PanelContainer") as PanelContainer
	if beside != null:
		_put(panel, &"theme_override_styles/panel", _hunt_copy(_orig(panel, &"theme_override_styles/panel"),
				beside.get_theme_stylebox(&"panel")))
	if _quiet_panel == null:
		_quiet_panel = style_box("well")
	for box in panel.find_children("*", "PanelContainer", true, false):
		var own = _orig(box, &"theme_override_styles/panel")
		if own is StyleBoxTexture and _rpath(_orig(own, &"texture")).ends_with("TEX_Hunting_5.png"):
			_put(box, &"theme_override_styles/panel", _hunt_copy(own, _quiet_panel))


func _hunt_copy(own, look: StyleBox) -> StyleBox:
	if not (own is StyleBox) or look == null:
		return look
	if _hunt_styles.has(own):
		return _hunt_styles[own]
	var copy := look.duplicate() as StyleBox
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		copy.set_content_margin(side, (own as StyleBox).get_content_margin(side))
	copy.set_meta(&"mi2r_own", true)
	_hunt_styles[own] = copy
	return copy


func _idle_dialogue(c: Control, on: bool) -> void:
	var talk := c.find_child("DialogueScrollContainer", true, false) as Control
	if on and talk != null and not talk.visible:
		_put(c, &"visible", false)
	elif _saved.has(c):
		_restore(c)


func _bank_shortcuts(bank: Node, on: bool) -> void:
	var strip := bank.get_node_or_null("MarginContainer/MainContainer/LeftContainer/PanelContainer") as Control
	var search := bank.find_child("ItemSearchBar", true, false) as Control
	var none := bank.find_child("NoItemSelectedPanel", true, false) as PanelContainer
	if none != null:
		var nl := none.get_child(0) as Label if none.get_child_count() > 0 else null
		if on:
			if _quiet_panel == null:
				_quiet_panel = style_box("well")
			_put(none, &"theme_override_styles/panel", _quiet_panel)
			if nl != null:
				_label_look(nl, null, Color("#9a958c"), 0)
		else:
			_restore(none)
			if nl != null:
				_restore(nl)
	if strip == null or search == null:
		return
	if not on:
		_restore(strip)
		if _bank_help != null and is_instance_valid(_bank_help):
			_bank_help.queue_free()
		_bank_help = null
		return
	if _bank_help == null or not is_instance_valid(_bank_help):
		var tips := PackedStringArray()
		for r in strip.find_children("*", "RichTextLabel", true, false):
			var lines := (r as RichTextLabel).get_parsed_text().strip_edges().split("\n", false)
			if lines.size() >= 2:
				tips.append("%s: %s" % [lines[0].strip_edges(), " ".join(lines.slice(1)).strip_edges()])
			elif lines.size() == 1:
				tips.append(lines[0])
		if tips.is_empty():
			return
		_bank_help = Label.new()
		_bank_help.name = "MI2ReskinBankHelp"
		_bank_help.text = "?"
		_bank_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_bank_help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_bank_help.custom_minimum_size = Vector2(36, 36)
		_bank_help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_bank_help.mouse_filter = Control.MOUSE_FILTER_STOP
		var text := "Bank shortcuts\n" + "\n".join(tips)
		if _polish != null:
			_polish.hint(_bank_help, text, "Bank shortcuts")
		else:
			_bank_help.tooltip_text = text
			_bank_help.theme = _tooltip_theme()
		_bank_help.add_theme_stylebox_override(&"normal", style_box("button"))
		search.get_parent().add_child(_bank_help)
		search.get_parent().move_child(_bank_help, search.get_index() + 1)
	_put(strip, &"visible", false)


var _tip_theme: Theme = null

func _tooltip_theme() -> Theme:
	if _tip_theme == null:
		_tip_theme = Theme.new()
		var sb := style_box("tooltip")
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 7
		sb.content_margin_bottom = 7
		_tip_theme.set_stylebox(&"panel", &"TooltipPanel", sb)
		_tip_theme.set_color(&"font_color", &"TooltipLabel", Color("#e8e4dc"))
		_tip_theme.set_color(&"font_shadow_color", &"TooltipLabel", Color(0, 0, 0, 0))
	return _tip_theme


const LOCK_TINT := Color(0.55, 0.55, 0.6)
const LOCK_TEXT := Color("#a8a29a")

func _check_locks() -> void:
	var cards := {}
	var i := 0
	while i < _locks.size():
		var lc = _locks[i].get_ref()
		if lc == null or not is_instance_valid(lc):
			_locks[i] = _locks[_locks.size() - 1]
			_locks.pop_back()
			continue
		i += 1
		var want: bool = enabled and look == "crafted" and lc.visible
		for lb in lc.find_children("*", "Label", true, false):
			if want and _reddish(_label_color(lb)):
				_label_look(lb, null, LOCK_TEXT, 0)
				_lock_labels[lb] = true
			elif not want and _lock_labels.has(lb):
				_lock_labels.erase(lb)
				_restore(lb)
		var card := _lock_card(lc)
		if card != null and not str(card.name).begins_with("Locked"):
			cards[card] = bool(cards.get(card, false)) or want
	for card in cards:
		if cards[card]:
			_put(card, &"self_modulate", LOCK_TINT)
		else:
			_unput(card, &"self_modulate")


func _label_color(lb: Label) -> Color:
	var ls: LabelSettings = _orig(lb, &"label_settings")
	if ls != null:
		return ls.font_color
	var d: Dictionary = _saved.get(lb, {})
	if d.has(&"theme_override_colors/font_color"):
		return Color(0, 0, 0, 0) if d[&"theme_override_colors/font_color"] == null else d[&"theme_override_colors/font_color"]
	return lb.get_theme_color(&"font_color")


func _reddish(c: Color) -> bool:
	return c.a > 0.0 and c.r > 0.65 and c.g < 0.5 and c.b < 0.4


func _lock_card(n: Node) -> CanvasItem:
	var p := n.get_parent()
	for _i in 4:
		if p == null or not (p is Control):
			return null
		if p is PanelContainer or p.get(&"NormalStyle") is StyleBox:
			return p
		p = p.get_parent()
	return null


func _square(f: StyleBoxFlat) -> bool:
	return f.corner_radius_top_left == 0 and f.corner_radius_top_right == 0 \
		and f.corner_radius_bottom_right == 0 and f.corner_radius_bottom_left == 0


func _redraw_all(n: Node) -> void:
	var c := n as CanvasItem
	if c != null:
		if not c.visible:
			return
		c.queue_redraw()
	for child in n.get_children():
		_redraw_all(child)


func _load_icon_map() -> void:
	var media := _find_mi1()
	if media == "":
		_log("Melvor Idle 1 not found; keeping MI2's own icons (set [mi1] path= in mi2_reskin.cfg if it is installed)")
		return
	var cfg := ConfigFile.new()
	if cfg.load(ICON_MAP_PATH) != OK:
		_log("no %s; keeping MI2's own icons" % ICON_MAP_PATH)
		return
	for key in cfg.get_section_keys("icons"):
		_icon_map["res://" + key] = media.path_join(str(cfg.get_value("icons", key)))
	_log("MI1 pictures read from %s" % media)


func _find_mi1() -> String:
	var tries := []
	if mi1_path != "":
		tries.append(mi1_path)
		tries.append(mi1_path.path_join("package.nw/assets/media"))
	var steamapps := OS.get_executable_path().get_base_dir().get_base_dir().get_base_dir()
	tries.append(steamapps.get_base_dir().path_join(MI1_MEDIA))
	for vdf in [steamapps.path_join("libraryfolders.vdf"),
			"C:/Program Files (x86)/Steam/steamapps/libraryfolders.vdf",
			"C:/Program Files/Steam/steamapps/libraryfolders.vdf",
			OS.get_environment("HOME").path_join(".steam/steam/steamapps/libraryfolders.vdf"),
			OS.get_environment("HOME").path_join(".local/share/Steam/steamapps/libraryfolders.vdf")]:
		if not FileAccess.file_exists(vdf):
			continue
		var rx := RegEx.create_from_string("\"path\"\\s+\"([^\"]+)\"")
		for m in rx.search_all(FileAccess.get_file_as_string(vdf)):
			tries.append(m.get_string(1).replace("\\\\", "/").path_join(MI1_MEDIA))
	for t in tries:
		if DirAccess.dir_exists_absolute(t) and DirAccess.dir_exists_absolute(t.path_join("bank")):
			return t
	return ""


func _swap_icon(tex: CompressedTexture2D) -> void:
	if _icon_state.has(tex):
		return
	var file: String = _icon_map[tex.resource_path]
	var w := tex.get_width()
	var h := tex.get_height()
	var img := _load_mi1_image(file, maxi(w, h))
	if img == null or img.is_empty():
		_icon_failed[tex] = true
		return
	img = _fit(img, w, h)
	var original := tex.get_image()
	if original == null:
		_icon_failed[tex] = true
		return
	if original.has_mipmaps():
		img.generate_mipmaps()
	_icon_state[tex] = original
	RenderingServer.texture_replace(tex.get_rid(), RenderingServer.texture_2d_create(img))
	_redraw_due = true


func _unswap_icon(tex: CompressedTexture2D) -> void:
	var original: Image = _icon_state.get(tex)
	_icon_state.erase(tex)
	if original != null and is_instance_valid(tex):
		RenderingServer.texture_replace(tex.get_rid(), RenderingServer.texture_2d_create(original))
		_redraw_due = true


func _load_mi1_image(file: String, size: int) -> Image:
	if not FileAccess.file_exists(file):
		return null
	var img := Image.new()
	if file.get_extension().to_lower() == "svg":
		var buf := FileAccess.get_file_as_bytes(file)
		if img.load_svg_from_buffer(buf, 1.0) != OK:
			return null
		var big := maxi(img.get_width(), img.get_height())
		if big > 0 and big != size:
			img = Image.new()
			if img.load_svg_from_buffer(buf, float(size) / big) != OK:
				return null
	elif img.load(file) != OK:
		return null
	return img


func _fit(img: Image, w: int, h: int) -> Image:
	img.convert(Image.FORMAT_RGBA8)
	if img.get_width() == w and img.get_height() == h:
		return img
	var s := minf(float(w) / img.get_width(), float(h) / img.get_height())
	var nw := maxi(1, roundi(img.get_width() * s))
	var nh := maxi(1, roundi(img.get_height() * s))
	img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(0, 0, nw, nh), Vector2i((w - nw) / 2, (h - nh) / 2))
	return out


func _input(e: InputEvent) -> void:
	if _polish != null:
		_polish.input(e)
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo or k.keycode != toggle_key:
		return
	set_enabled(not enabled)


func set_enabled(on: bool) -> void:
	var t0 := Time.get_ticks_msec()
	_set_enabled_quiet(on)
	_log("toggle: reskin %s in %d ms (%d flat styles, %d picture panels, %d MI1 icons)" % [
		"on" if enabled else "off", Time.get_ticks_msec() - t0, _flats.size(), _texboxes.size(), _icon_state.size()])


func _set_enabled_quiet(on: bool) -> void:
	enabled = on
	if on:
		for f in _flats:
			_style_flat(f)
		for sb in _texboxes:
			_style_texbox(sb)
		_apply_globals(true)
		for n in _watch:
			var w = n.get_ref()
			if w != null and is_instance_valid(w):
				_check_textures(w)
		if _titles_wanted():
			var tf := _title_font_or_null()
			for id in _title_labels.keys():
				var lb = _title_labels[id].get_ref()
				if lb == null or not is_instance_valid(lb):
					_title_labels.erase(id)
				elif lb.is_inside_tree():
					_title_one(lb, tf)
		_labels.clear()
		_enqueue_labels(get_tree().root)
		_apply_body_font(body_font if look == "crafted" and body_font != "game" else "")
		if _polish != null:
			_polish.apply(true)
	else:
		_apply_body_font("")
		_step("off: frame")
		_frame(false)
		_step("off: pages")
		_pages(false)
		_step("off: polish")
		if _polish != null:
			_polish.apply(false)
		_step("off: restore %d objects" % _saved.size())
		for o in _saved.keys():
			if is_instance_valid(o):
				_restore(o)
		_saved.clear()
		_step("off: version")
		_blanked.clear()
		_place_version(false)
		_step("off: icons")
		for t in _icon_state.keys():
			_unswap_icon(t)
		_icon_pending.clear()
		_icon_queued.clear()
	_step("redraw")
	_redraw_all(get_tree().root)
	_write_style_file()
	_step("signal")
	look_changed.emit(on)
	_step("done")


func _prune() -> void:
	_save_disk_info()
	_release_unused()
	_drop_freed(_saved)
	for d in [_collapsed, _cat_tried, _lock_labels, _blanked]:
		_drop_freed(d)
	var w := []
	for r in _watch:
		if r.get_ref() != null:
			w.append(r)
	_watch = w
	if _seen.size() > 50000:
		_seen.clear()
	for id in _title_labels.keys():
		if _title_labels[id].get_ref() == null:
			_title_labels.erase(id)


func _drop_freed(d: Dictionary) -> void:
	for k in d.keys():
		if not is_instance_valid(k):
			d.erase(k)


func _release_unused() -> void:
	var tmp := {StyleBoxFlat.new(): true}
	var overhead := 0
	for r in tmp.keys():
		overhead = r.get_reference_count() - 1
	var released := 0
	for d in [_flats, _texboxes, _tracks]:
		for r in d.keys():
			var refs: int = r.get_reference_count() - overhead
			var ours := int(_saved.has(r)) + int(_flats.has(r)) + int(_texboxes.has(r)) + int(_tracks.has(r)) 					+ int(_style_users.has(r))
			if refs <= ours:
				_saved.erase(r)
				_flats.erase(r)
				_texboxes.erase(r)
				_tracks.erase(r)
				_style_users.erase(r)
				_seen.erase(r.get_instance_id())
				released += 1
	_released_total += released
	if released > 0 and _dev_timing:
		_log("released %d styles only the reskin still held" % released)


func _step(what: String) -> void:
	if _dev_steps:
		_log("step: " + what)


func dev_command(line: String) -> void:
	var parts := line.split(" ", false)
	var out := PackedStringArray()
	match parts[0]:
		"on":
			set_enabled(true)
		"off":
			set_enabled(false)
		"at":
			for i in range(1, parts.size() - 1, 2):
				_dump_at(Vector2(float(parts[i]), float(parts[i + 1])), out)
				out.append("")
		"tree":
			var start: Node = get_tree().root
			if parts.size() > 2:
				start = get_tree().root.get_node_or_null(NodePath(parts[2]))
			if start != null:
				_dump_tree(start, int(parts[1]), 0, out)
		"desc":
			if parts.size() > 2:
				var start := get_tree().root.get_node_or_null(NodePath(parts[2]))
				if start != null:
					_desc_rec(start, int(parts[1]), "", out)
		"api":
			if parts.size() > 1:
				var nd := get_tree().root.get_node_or_null(NodePath(parts[1]))
				if nd != null and nd.get_script() != null:
					var scr: Script = nd.get_script()
					for s in scr.get_script_signal_list():
						out.append("signal " + str(s.name))
					for m in scr.get_script_method_list():
						out.append("method %s(%d)" % [m.name, m.args.size()])
					for p in scr.get_script_property_list():
						out.append("prop " + str(p.name))
		"signals":
			if parts.size() > 1:
				var nd := get_tree().root.get_node_or_null(NodePath(parts[1]))
				if nd != null:
					for s in nd.get_signal_list():
						var k := nd.get_signal_connection_list(s.name).size()
						if k > 0:
							out.append("%s (%d)" % [s.name, k])
		"get":
			if parts.size() > 2:
				var p := parts[1]
				var targets: Array = []
				if p.ends_with("/*"):
					var par := get_tree().root.get_node_or_null(NodePath(p.trim_suffix("/*")))
					if par != null:
						targets = par.get_children()
				else:
					var nd := get_tree().root.get_node_or_null(NodePath(p))
					if nd != null:
						targets = [nd]
				for t in targets:
					var vals := PackedStringArray()
					for prop in parts.slice(2):
						vals.append("%s=%s" % [prop, str(t.get(prop))])
					out.append("%s: %s" % [t.name, ", ".join(vals)])
		"bodyfont":
			_apply_body_font("" if parts.size() < 2 or parts[1] == "off" else parts[1])
			out.append("body font: %s, %d controls changed" % [_body_active if _body_active != "" else "game's", _body_done.size()])
		"fonts":
			var seen := {}
			var pt := ThemeDB.get_project_theme()
			if pt != null and pt.default_font != null:
				seen[pt.default_font] = 1000000
			for n in get_tree().root.find_children("*", "Label", true, false):
				var lb := n as Label
				if not lb.is_visible_in_tree():
					continue
				var f: Font = lb.label_settings.font if lb.label_settings != null and lb.label_settings.font != null else lb.get_theme_font(&"font")
				seen[f] = int(seen.get(f, 0)) + 1
			for f in seen:
				var base = f
				while base is FontVariation and (base as FontVariation).base_font != null:
					base = (base as FontVariation).base_font
				var info := ""
				if base is FontFile:
					var ff := base as FontFile
					info = " aa=%d hint=%d subpx=%d over=%s msdf=%s mip=%s autohint=%s fixed=%d" % [ff.antialiasing, ff.hinting,
						ff.subpixel_positioning, ff.oversampling, ff.multichannel_signed_distance_field, ff.generate_mipmaps,
						ff.force_autohinter, ff.fixed_size]
				out.append("%d x %s %s base=%s %s%s" % [seen[f], f.get_class(), _rpath(f), base.get_class(), _rpath(base) if base != f else "", info])
			var vp := get_viewport()
			out.append("viewport: oversampling=%s override=%s snap2d=%s/%s msaa=%d" % [vp.oversampling, vp.oversampling_override,
				vp.snap_2d_transforms_to_pixel, vp.snap_2d_vertices_to_pixel, vp.msaa_2d])
		"set":
			if parts.size() > 3:
				var nd := get_tree().root.get_node_or_null(NodePath(parts[1]))
				if nd != null:
					nd.set(parts[2], str_to_var(" ".join(parts.slice(3))))
					out.append("%s.%s = %s" % [nd.name, parts[2], str(nd.get(parts[2]))])
		"kind":
			if parts.size() > 1:
				var groups := {}
				for n in get_tree().root.find_children("*", parts[1], true, false):
					if not (n is CanvasItem and (n as CanvasItem).is_visible_in_tree()):
						continue
					var key := ""
					if n is TextureProgressBar:
						var t := n as TextureProgressBar
						key = "%s | %s | fill_mode %d | %s" % [_rpath(t.texture_under), _rpath(t.texture_progress), t.fill_mode, t.tint_progress.to_html()]
					elif n is Range and n is Control:
						key = "%s / %s" % [_rpath((n as Control).get_theme_stylebox(&"background")), _rpath((n as Control).get_theme_stylebox(&"fill"))]
					elif n is ScrollBar:
						key = "%s / %s" % [_rpath((n as Control).get_theme_stylebox(&"scroll")), _rpath((n as Control).get_theme_stylebox(&"grabber"))]
					if not groups.has(key):
						groups[key] = [0, get_tree().root.get_path_to(n)]
					groups[key][0] += 1
				for k in groups:
					out.append("%d x %s\n    e.g. %s" % [groups[k][0], k, groups[k][1]])
		"polish":
			if _polish != null:
				if parts.size() > 2 and parts[1] == "hint":
					_polish.force_hint = null if parts[2] == "off" else get_tree().root.get_node_or_null(NodePath(parts[2])) as Control
				if parts.size() > 1 and parts[1] == "swatch":
					_polish.swatch()
				if parts.size() > 2 and parts[1] == "hover":
					_polish.force_hover = null if parts[2] == "off" else get_tree().root.get_node_or_null(NodePath(parts[2])) as Control
				out.append_array(_polish.debug())
		"bench":
			var page: Node = null
			var evc := get_tree().root.find_child("EntityViewContainer", true, false)
			if evc != null and evc.get_child_count() > 0:
				page = evc.get_child(0)
			if page != null:
				var nodes: Array = []
				var st: Array = [page]
				while not st.is_empty():
					var x: Node = st.pop_back()
					if x is CanvasItem:
						nodes.append(x)
					st.append_array(x.get_children())
				var t := Time.get_ticks_usec()
				for x in nodes:
					x.get_meta(&"_mi2r", 0)
				var t_meta := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				for x in nodes:
					_class_props(x)
				var t_cls := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				var gets := 0
				for x in nodes:
					for pname in _class_props(x)[0]:
						x.get(pname)
						gets += 1
				var t_get := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				for x in nodes:
					_foreign(x)
				var t_for := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				for x in nodes:
					if x is Range or x.get_script() != null:
						x.get("BackgroundStyle")
				var t_trk := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				if _polish != null:
					for x in nodes:
						_polish.scan(x)
				var t_pol := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				for x in nodes:
					if x is Control:
						var nm := str(x.name)
						if nm.begins_with("Locked") or PAGE_PARTS.has(x.name) or nm.ends_with("CreatingRecipeContainer"):
							pass
				var t_nm := Time.get_ticks_usec() - t
				t = Time.get_ticks_usec()
				var sts := 0
				for x in nodes:
					for pname in _class_props(x)[0]:
						var v = x.get(pname)
						if v is StyleBox:
							_scan_style(v)
							sts += 1
				var t_sty := Time.get_ticks_usec() - t
				out.append("%d nodes: meta %d us, class props %d us, %d style gets %d us, foreign %d us, track %d us, polish %d us, names %d us, %d styles scanned %d us" % [
					nodes.size(), t_meta, t_cls, gets, t_get, t_for, t_trk, t_pol, t_nm, sts, t_sty])
		"capture":
			_cap_i = 0
			_cap_left = int(parts[1]) if parts.size() > 1 else 12
		"sizes":
			var c := {}
			for id in _title_labels:
				var lb = _title_labels[id].get_ref()
				if lb != null and is_instance_valid(lb) and lb.is_inside_tree():
					var sz: int = lb.label_settings.font_size if lb.label_settings != null else lb.get_theme_font_size(&"font_size")
					c[sz] = c.get(sz, 0) + 1
					if sz > 24:
						out.append("big: '%s' %s (orig %s)" % [lb.text, lb.get_path(), str(_saved.get(lb, {}))])
			var keys := c.keys()
			keys.sort()
			out.append(", ".join(keys.map(func(k): return "%d px x%d" % [k, c[k]])))
		"frames":
			_ft = []
			_ft_last = 0
			_ft_left = int(parts[1]) if parts.size() > 1 else 60
			_dev_timing = true
		"press":
			if parts.size() > 1:
				var nd := get_tree().root.get_node_or_null(NodePath(parts[1]))
				if nd != null and nd.has_method("InternalPressed"):
					nd.call("InternalPressed")
				elif nd is BaseButton and (nd as BaseButton).toggle_mode:
					(nd as BaseButton).button_pressed = true
				elif nd is BaseButton:
					(nd as BaseButton).pressed.emit()
		"call":
			if parts.size() > 2:
				var nd := get_tree().root.get_node_or_null(NodePath(parts[1]))
				if nd != null:
					out.append(str(nd.call(parts[2])))
		"find":
			if parts.size() > 1:
				for n in get_tree().root.find_children(parts[1], "", true, false):
					var c := n as CanvasItem
					out.append("%s [%s]%s" % [get_tree().root.get_path_to(n), n.get_class(),
						"" if c == null else (" visible" if c.is_visible_in_tree() else " hidden")])
		"caption":
			if parts.size() > 1:
				_set_enabled_quiet(false)
				caption_font_file = "" if parts[1] == "none" else parts[1]
				if parts.size() > 2:
					caption_spacing = int(parts[2])
				_caption_font = null
				_set_enabled_quiet(true)
				out.append("caption font now '%s' spacing %d" % [caption_font_file, caption_spacing])
		"font":
			if parts.size() > 1:
				_set_enabled_quiet(false)
				title_font_file = parts[1]
				_title_font = null
				_set_enabled_quiet(true)
				out.append("title font now %s (%s)" % [title_font_file, _get_title_font()])
		"queue":
			_queue_paused = parts.size() > 1 and parts[1] == "pause"
			out.append("background scan %s, %d waiting" % ["paused" if _queue_paused else "running", _queue.size()])
		"hidden":
			var evc := get_tree().root.find_child("EntityViewContainer", true, false)
			if evc != null and evc.get_child_count() > 0:
				var shown := 0
				var hid := 0
				var st: Array = [evc.get_child(0)]
				while not st.is_empty():
					var x: Node = st.pop_back()
					if x is CanvasItem and not (x as CanvasItem).visible:
						var sub := x.find_children("*", "", true, false).size() + 1
						hid += sub
						continue
					shown += 1
					st.append_array(x.get_children())
				out.append("shown %d, in hidden branches %d" % [shown, hid])
		"blanks":
			var seen_paths := {}
			for tr in get_tree().root.find_children("*", "TextureRect", true, false):
				var t := tr as TextureRect
				if not t.is_visible_in_tree() or _foreign(t) or t.size.x < 12.0:
					continue
				var path := _rpath(t.texture) if t.texture != null else "<none>"
				var low := path.to_lower()
				if t.texture == null or low.contains("placeholder") or low.contains("missing") or low.contains("unknown") or low.contains("default"):
					var key := "%s  [%s]" % [path, t.name]
					seen_paths[key] = int(seen_paths.get(key, 0)) + 1
			for k in seen_paths:
				out.append("%d x %s" % [seen_paths[k], k])
		"digits":
			var total := 0.0
			var n_lb := 0
			for lb in get_tree().root.find_children("*", "Label", true, false):
				var t: String = (lb as Label).text
				if (lb as Label).is_visible_in_tree() and t.length() >= 2 and t.is_valid_int():
					total += (lb as Label).get_minimum_size().x
					n_lb += 1
			out.append("%d number labels, total width %.1f" % [n_lb, total])
		"center":
			var stack: Array = [get_tree().root]
			while not stack.is_empty():
				var n: Node = stack.pop_back()
				stack.append_array(n.get_children())
				if not (n is Control) or not (n as Control).is_visible_in_tree() or _foreign(n):
					continue
				var is_btn: bool = n is BaseButton or (n.get_script() != null and str(n.get_script().resource_path).ends_with("ButtonContainer.cs"))
				if not is_btn:
					continue
				var r := (n as Control).get_global_rect()
				var top := INF
				var bottom := -INF
				var names := []
				for lb in n.find_children("*", "Label", true, false):
					if (lb as Label).is_visible_in_tree() and (lb as Label).text.strip_edges() != "":
						var lr := (lb as Label).get_global_rect()
						var lh := (lb as Label).get_line_height() * (lb as Label).get_line_count()
						var ly := lr.position.y + (lr.size.y - lh) / 2.0
						top = minf(top, ly)
						bottom = maxf(bottom, ly + lh)
						names.append((lb as Label).text.left(24))
				if names.is_empty() and n is Button and (n as Button).text != "":
					continue
				if names.is_empty():
					continue
				var off := (top + bottom) / 2.0 - r.get_center().y
				if absf(off) > 3.0 and r.size.y < 120.0:
					out.append("%+.0f px  %s  [%s]  h=%d" % [off, ", ".join(names), get_tree().root.get_path_to(n), r.size.y])
		"mem":
			for obj in [self, _polish, _menu]:
				if obj == null:
					continue
				var row := []
				for p in obj.get_property_list():
					if not (p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
						continue
					var v = obj.get(p["name"])
					if v is Array or v is Dictionary:
						if v.size() > 0:
							row.append("%s %d" % [p["name"], v.size()])
				out.append("%s: %s" % [obj.name, ", ".join(row)])
			var fk := _flats.keys()
			for k in fk.slice(maxi(0, fk.size() - 6)):
				out.append("  newest flat: %s refs %d bg %s users %s" % [_rpath(k), k.get_reference_count(), k.bg_color.to_html(),
					str(_saved.get(k, {}).keys().size())])
			out.append("styles released so far: %d" % _released_total)
			var ours := {}
			for t in _panel_textures.values():
				ours[t] = true
			var copies := 0
			for sb in _texboxes.keys():
				if ours.has(_orig(sb, &"texture")):
					copies += 1
			out.append("picture panels whose 'original' is the reskin's own picture: %d; copies of reskinned styles recognised: %d" % [copies, _copies_found])
			var tmp := {StyleBoxFlat.new(): true}
			var overhead := 0
			for r in tmp.keys():
				overhead = r.get_reference_count() - 1
			var hist := {}
			for r in _flats.keys():
				var extra: int = r.get_reference_count() - overhead - (int(_saved.has(r)) + int(_flats.has(r)) + int(_texboxes.has(r)) + int(_tracks.has(r)) + int(_style_users.has(r)))
				hist[extra] = int(hist.get(extra, 0)) + 1
			out.append("overhead %d; flat styles by references beyond the reskin's own: %s" % [overhead, str(hist)])
			out.append("godot memory %.1f MB, objects %d, resources %d, nodes %d, orphan nodes %d" % [
				Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
				Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)])
		"stats":
			_dump_stats(out)
			out.append("bar_styles: %s, %s; slot: %s" % [bar_styles(), bar_styles("xp", 4).fill.bg_color, style_box("slot")])
			var probe := style_box("frame")
			out.append("title labels: %d, waiting %d, font %s" % [_titles, _labels.size(), _get_title_font()])
			out.append("style_box(frame): %s %s margins %d" % [probe.get_class(), probe.texture.get_size(), probe.texture_margin_left])
		"tex":
			_dump_tex(parts[1] if parts.size() > 1 else "", get_tree().root, out)
		"styles":
			var found := {}
			_collect_styles(get_tree().root, found)
			for sb in found:
				out.append("%s\t%s\t%s\t%s" % [_role_of(sb), _rpath(sb), _describe_orig(sb), found[sb]])
		_:
			out.append("unknown command: " + line)
	if not out.is_empty():
		var f := FileAccess.open(DUMP_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(out) + "\n")
		_log("dev: wrote %d lines to %s" % [out.size(), DUMP_PATH])


func _rpath(r) -> String:
	if r == null:
		return "null"
	var p := str(r.resource_path)
	return p if p != "" else "<%s embedded>" % r.get_class()


func _describe_style(sb) -> String:
	if sb == null:
		return "null"
	var s := "%s %s" % [sb.get_class(), _rpath(sb)]
	if sb is StyleBoxFlat:
		s += " bg=%s skew=%s r=%d,%d,%d,%d bw=%d,%d,%d,%d bc=%s aa=%s" % [
			sb.bg_color.to_html(), sb.skew, sb.corner_radius_top_left, sb.corner_radius_top_right,
			sb.corner_radius_bottom_right, sb.corner_radius_bottom_left, sb.border_width_left,
			sb.border_width_top, sb.border_width_right, sb.border_width_bottom, sb.border_color.to_html(),
			sb.anti_aliasing]
	elif sb is StyleBoxTexture:
		s += " tex=%s (orig %s) margins=%d,%d,%d,%d modulate=%s" % [_rpath(sb.texture),
			_rpath(_orig(sb, &"texture")), sb.texture_margin_left, sb.texture_margin_top,
			sb.texture_margin_right, sb.texture_margin_bottom, sb.modulate_color.to_html()]
	return s


func _describe_node(c: Node, out: PackedStringArray, indent: String) -> void:
	var scr = c.get_script()
	var rect := ""
	if c is Control:
		rect = str((c as Control).get_global_rect())
	out.append("%s%s [%s%s] %s" % [indent, c.name, c.get_class(),
		(" " + str(scr.resource_path)) if scr != null else "", rect])
	var entry := _class_props(c)
	for pname in entry[0]:
		var v = c.get(pname)
		if v is StyleBox:
			out.append("%s  .%s = %s" % [indent, pname, _describe_style(v)])
		elif v is Theme:
			out.append("%s  .%s = Theme %s" % [indent, pname, _rpath(v)])
	if c is Control:
		for sname in ["panel", "normal", "hover", "pressed", "disabled", "background", "fill"]:
			if (c as Control).has_theme_stylebox(sname):
				out.append("%s  theme '%s' = %s" % [indent, sname, _describe_style((c as Control).get_theme_stylebox(sname))])
	for pname in entry[1]:
		var t = c.get(pname)
		if t != null:
			out.append("%s  .%s = %s %s%s" % [indent, pname, t.get_class(), _rpath(t),
				" [MI1]" if _icon_state.has(t) else ""])
	if c is CanvasItem and ((c as CanvasItem).modulate != Color.WHITE or (c as CanvasItem).self_modulate != Color.WHITE):
		out.append("%s  modulate %s self_modulate %s" % [indent, (c as CanvasItem).modulate.to_html(),
			(c as CanvasItem).self_modulate.to_html()])
	if c is Control and (c as Control).tooltip_text != "":
		out.append("%s  tooltip '%s'" % [indent, (c as Control).tooltip_text.c_escape()])
	if c is Label:
		out.append("%s  text '%s' font_size %d title %s" % [indent, (c as Label).text.left(30),
			_label_size(c), _is_title(c)])
	if c is CanvasItem and (c as CanvasItem).material != null:
		var m = (c as CanvasItem).material
		out.append("%s  .material = %s %s %s" % [indent, m.get_class(), _rpath(m),
			_rpath(m.shader) if m is ShaderMaterial else ""])


func _desc_rec(n: Node, depth: int, indent: String, out: PackedStringArray) -> void:
	_describe_node(n, out, indent)
	if depth > 0:
		for c in n.get_children():
			_desc_rec(c, depth - 1, indent + "  ", out)


func _dump_at(screen: Vector2, out: PackedStringArray) -> void:
	var root := get_tree().root
	var p: Vector2 = root.get_final_transform().affine_inverse() * screen
	out.append("at %s (canvas %s)" % [screen, p])
	_dump_at_rec(root, p, out, 0)


func _dump_at_rec(n: Node, p: Vector2, out: PackedStringArray, depth: int) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Control and (n as Control).get_global_rect().has_point(p):
		_describe_node(n, out, "  ".repeat(mini(depth, 30)))
	for c in n.get_children():
		_dump_at_rec(c, p, out, depth + (1 if n is Control else 0))


func _dump_tree(n: Node, max_depth: int, depth: int, out: PackedStringArray) -> void:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	var scr = n.get_script()
	var extra := ""
	if n is Control:
		extra = str((n as Control).get_global_rect())
	out.append("%s%s [%s%s] %s (%d children)" % ["  ".repeat(depth), n.name, n.get_class(),
		(" " + str(scr.resource_path)) if scr != null else "", extra, n.get_child_count()])
	if depth >= max_depth:
		return
	for c in n.get_children():
		_dump_tree(c, max_depth, depth + 1, out)


func _dump_stats(out: PackedStringArray) -> void:
	out.append("flat styles %d, picture panels %d, changed objects %d, icon nodes watched %d" % [
		_flats.size(), _texboxes.size(), _saved.size(), _watch.size()])
	out.append("MI1 icons shown %d, pending %d, failed %d, mapped %d" % [_icon_state.size(),
		_icon_pending.size(), _icon_failed.size(), _icon_map.size()])
	for t in _icon_failed:
		out.append("  failed: %s -> %s" % [t.resource_path, _icon_map.get(t.resource_path, "?")])
	var tex_use := {}
	for sb in _texboxes:
		var k := _rpath(_orig(sb, &"texture"))
		tex_use[k] = tex_use.get(k, 0) + 1
	for k in tex_use:
		out.append("picture panel %s x%d" % [k, tex_use[k]])


func _collect_styles(n: Node, found: Dictionary) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Control:
		var c := n as Control
		var styles := []
		for pname in _class_props(n)[0]:
			var v = n.get(pname)
			if v is StyleBox:
				styles.append(v)
		for sname in ["panel", "normal", "hover", "pressed", "disabled", "background", "fill", "focus"]:
			if c.has_theme_stylebox(sname):
				styles.append(c.get_theme_stylebox(sname))
		for sb in styles:
			if (sb is StyleBoxTexture or sb is StyleBoxFlat) and not found.has(sb):
				found[sb] = "%s %dx%d" % [c.get_path(), c.size.x, c.size.y]
	for ch in n.get_children():
		_collect_styles(ch, found)


func _describe_orig(sb) -> String:
	if sb is StyleBoxTexture:
		var info := _texture_info(_orig(sb, &"texture"), _orig(sb, &"region_rect"))
		return "tex=%s avg=%s mod=%s" % [_rpath(_orig(sb, &"texture")), (info[0] as Color).to_html(false),
			(_orig(sb, &"modulate_color") as Color).to_html()]
	if sb is StyleBoxFlat:
		return "bg=%s border=%d %s r=%d" % [(_orig(sb, &"bg_color") as Color).to_html(),
			_orig(sb, &"border_width_top"), (_orig(sb, &"border_color") as Color).to_html(),
			_orig(sb, &"corner_radius_top_left")]
	return ""


func _dump_tex(sub: String, n: Node, out: PackedStringArray) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	for pname in _class_props(n)[1]:
		var t = n.get(pname)
		if t != null and _rpath(t).contains(sub):
			_describe_node(n, out, "")
			out.append("    path " + str(n.get_path()))
			break
	for c in n.get_children():
		_dump_tex(sub, c, out)


func _log(msg: String) -> void:
	print("[MI2Reskin] ", msg)
	var mode: FileAccess.ModeFlags = FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE
	var file := FileAccess.open(LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	file.store_line("%s %s" % [Time.get_datetime_string_from_system(), msg])
