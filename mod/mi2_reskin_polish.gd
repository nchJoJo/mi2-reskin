extends Node

var core: Node = null

var bars := true
var scrollbars := true
var sidebar := true
var motion := true
var tooltips := true
var cursor := "sword"
var even_digits := true

var _bars: Array = []
var _ranges: Array = []
var _scrolls: Array = []
var _skills: Array = []
var _marked_styles := {}
var _tip_bits: Array = []
var _fonts := {}
var _tex := {}
var _styles := {}
var _dividers: Array = []
var _hover: Control = null
var _hover_item: Control = null
var _cursor_on := false
var _cursor_down := false
var force_hover: Control = null
var force_hint: Control = null
var _hints := {}
var _hint_layer: CanvasLayer = null
var _hint_box: PanelContainer = null
var _hint_for: Control = null
var _hint_since := 0


func hint(c: Control, text: String, title := "") -> void:
	if title != "" and text.begins_with(title + "\n"):
		text = text.substr(title.length() + 1)
	_hints[c.get_instance_id()] = [weakref(c), text, title]


func unhint(c: Control) -> void:
	_hints.erase(c.get_instance_id())
	if _hint_for == c:
		_hide_hint()


func _hint_of(n: Node) -> Control:
	var c := n
	for _i in 6:
		if c == null:
			return null
		if _hints.has(c.get_instance_id()):
			return c as Control
		c = c.get_parent()
	return null


func _update_hint() -> void:
	if Engine.get_process_frames() % 600 == 0:
		for id in _hints.keys():
			if _hints[id][0].get_ref() == null:
				_hints.erase(id)
	var target: Control = null
	if _on():
		var hovered: Control = force_hint if force_hint != null and is_instance_valid(force_hint) else get_viewport().gui_get_hovered_control()
		target = _hint_of(hovered) if hovered != null else null
	if target != _hint_for:
		_hide_hint()
		_hint_for = target
		_hint_since = Time.get_ticks_msec()
		return
	if target == null or (_hint_box != null and _hint_box.visible):
		return
	if Time.get_ticks_msec() - _hint_since < 250 and force_hint == null:
		return
	_show_hint(target)


func _show_hint(c: Control) -> void:
	var entry: Array = _hints[c.get_instance_id()]
	if _hint_layer == null:
		_hint_layer = CanvasLayer.new()
		_hint_layer.name = "MI2ReskinHints"
		_hint_layer.layer = 120
		add_child(_hint_layer)
	if _hint_box != null:
		_hint_box.queue_free()
	_hint_box = PanelContainer.new()
	_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBox = core.style_box("tooltip")
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 9
	_hint_box.add_theme_stylebox_override(&"panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_box.add_child(col)
	if entry[2] != "":
		var t := Label.new()
		t.text = entry[2]
		var font: Font = core._get_title_font() if core.title_font else null
		if font != null:
			t.add_theme_font_override(&"font", font)
		t.add_theme_font_size_override(&"font_size", 16)
		t.add_theme_color_override(&"font_color", core.GOLD.lightened(0.1))
		col.add_child(t)
	var body := Label.new()
	body.text = entry[1]
	body.add_theme_color_override(&"font_color", Color("#e8e4dc"))
	body.add_theme_font_size_override(&"font_size", 14)
	body.add_theme_constant_override(&"line_spacing", 2)
	col.add_child(body)
	_hint_layer.add_child(_hint_box)
	_hint_box.reset_size()
	var r := c.get_global_rect()
	var view := get_viewport().get_visible_rect().size
	var size := _hint_box.get_combined_minimum_size()
	var pos := Vector2(r.position.x, r.end.y + 6.0)
	if pos.y + size.y > view.y - 4.0:
		pos.y = r.position.y - size.y - 6.0
	pos.x = clampf(pos.x, 4.0, view.x - size.x - 4.0)
	_hint_box.position = pos


func _hide_hint() -> void:
	if _hint_box != null and is_instance_valid(_hint_box):
		_hint_box.queue_free()
	_hint_box = null
	_hint_for = null


func swatch() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 121
	add_child(layer)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override(&"panel", core.style_box("frame"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 28)
	box.add_child(row)
	for kind in ["grab", "grab_hi", "grab_down"]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override(&"separation", 10)
		var tall := Panel.new()
		tall.custom_minimum_size = Vector2(SCROLL_W, 140)
		tall.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tall.add_theme_stylebox_override(&"panel", _style("scroll"))
		var grip := Panel.new()
		grip.add_theme_stylebox_override(&"panel", _style(kind))
		grip.position = Vector2(0, 30)
		grip.size = Vector2(SCROLL_W, 70)
		tall.add_child(grip)
		col.add_child(tall)
		var wide := Panel.new()
		wide.custom_minimum_size = Vector2(140, SCROLL_W)
		wide.add_theme_stylebox_override(&"panel", _style("scroll_h"))
		var grip_h := Panel.new()
		grip_h.add_theme_stylebox_override(&"panel", _style(kind + "_h"))
		grip_h.position = Vector2(30, 0)
		grip_h.size = Vector2(70, SCROLL_W)
		wide.add_child(grip_h)
		col.add_child(wide)
		var name := Label.new()
		name.text = kind
		col.add_child(name)
		row.add_child(col)
	layer.add_child(box)
	box.position = get_viewport().get_visible_rect().size / 2.0 - Vector2(300, 120)
	get_tree().create_timer(8.0).timeout.connect(layer.queue_free)


func debug() -> PackedStringArray:
	var out := PackedStringArray()
	out.append("bars %d, ranges %d, scrollbars %d, skills %d, tooltip bits %d, dividers %d, cursor %s" % [
		_alive(_bars).size(), _alive(_ranges).size(), _alive(_scrolls).size(), _alive(_skills).size(),
		_alive(_tip_bits).size(), _dividers.size(), _cursor_on])
	var tnum := TextServerManager.get_primary_interface().name_to_tag("tnum")
	for f in _fonts.keys():
		if not is_instance_valid(f):
			continue
		var feats = f.get("opentype_features") if f is FontVariation else f.get("opentype_feature_overrides")
		var names := ""
		if f is FontFile:
			names = (f as FontFile).font_name
			var sup: Dictionary = (f as FontFile).get_supported_feature_list()
			names += " supports tnum: %s" % sup.has(tnum)
		out.append("font %s %s %s tnum=%s" % [f.get_class(), f.resource_path, names, feats])
	for g in [false, true]:
		var img: Image = _sword(g).get_image()
		img.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
		img.save_png("user://mi2_reskin_cursor%s.png" % ("_pressed" if g else ""))
	out.append("hover item: %s" % (str(_hover_item.get_path()) if _hover_item != null and is_instance_valid(_hover_item) and _hover_item.is_inside_tree() else "none"))
	return out


func setup(c: Node, cfg: ConfigFile) -> void:
	core = c
	if cfg != null:
		bars = bool(cfg.get_value("polish", "bars", bars))
		scrollbars = bool(cfg.get_value("polish", "scrollbars", scrollbars))
		sidebar = bool(cfg.get_value("polish", "sidebar", sidebar))
		motion = bool(cfg.get_value("polish", "motion", motion))
		tooltips = bool(cfg.get_value("polish", "tooltips", tooltips))
		cursor = str(cfg.get_value("polish", "cursor", cursor))
		even_digits = bool(cfg.get_value("polish", "even_digits", even_digits))


func _on() -> bool:
	return core != null and core.enabled and core.look == "crafted"


var _theme_fonts_noted := false
var _known := {}


func _add(list: Array, n: Node) -> void:
	if _known.size() > 20000:
		_known.clear()
		_track_ok.clear()
	var id := n.get_instance_id()
	if _known.has(id):
		return
	_known[id] = true
	list.append(weakref(n))


func scan(n: Node) -> void:
	if n is TextureProgressBar:
		var t := n as TextureProgressBar
		if t.texture_progress != null and t.texture_progress.resource_path.ends_with("TEX_progress-bar.png"):
			_add(_bars, n)
	elif n is ProgressBar:
		_add(_ranges, n)
	elif n is ScrollBar:
		_add(_scrolls, n)
	elif n is ScrollContainer:
		for sb in [(n as ScrollContainer).get_v_scroll_bar(), (n as ScrollContainer).get_h_scroll_bar()]:
			if sb != null:
				_add(_scrolls, sb)
	elif n.name == &"LegacySkillNavigationButton":
		_add(_skills, n)
	elif n is Label:
		var lb := n as Label
		if _tip_name(n.name, "HeaderLabel") and _in_tooltip(n):
			_add(_tip_bits, n)
		var ls := lb.label_settings
		if ls != null and ls.font != null and not _fonts.has(ls.font):
			_note_font(lb)
	elif n is HSeparator and _tip_name(n.name, "Seperator") and _in_tooltip(n):
		_add(_tip_bits, n)


var _header_names := {}
var _sep_names := {}

func _tip_name(name: StringName, part: String) -> bool:
	var d: Dictionary = _header_names if part == "HeaderLabel" else _sep_names
	var r = d.get(name)
	if r == null:
		r = str(name).ends_with(part) if part == "HeaderLabel" else str(name).contains(part)
		if d.size() > 20000:
			d.clear()
		d[name] = r
	return r


func _in_tooltip(n: Node) -> bool:
	var c := n.get_parent()
	for _i in 8:
		if c == null:
			return false
		var s = c.get_script()
		if s != null and str(s.resource_path).contains("/Tooltips/"):
			return true
		c = c.get_parent()
	return false


func _alive(list: Array) -> Array:
	var out := []
	var i := 0
	while i < list.size():
		var n = list[i].get_ref()
		if n == null or not is_instance_valid(n):
			list[i] = list[list.size() - 1]
			list.pop_back()
			continue
		out.append(n)
		i += 1
	return out


func tick() -> void:
	var on := _on()
	if not _theme_fonts_noted:
		_theme_fonts_noted = true
		var t := ThemeDB.get_project_theme()
		for f in [ThemeDB.fallback_font, t.default_font if t != null else null]:
			if f != null and not _fonts.has(f):
				_fonts[f] = true
				if on and even_digits:
					_digits_font(f, true)
	_apply_bars(on and bars)
	_apply_ranges(on and bars, on and sidebar)
	_apply_scrolls(on and scrollbars)
	_apply_skills(on and sidebar)
	_apply_dividers(on and sidebar)
	_apply_tooltips(on and tooltips)
	_apply_digits(on and even_digits)
	_apply_cursor(on and cursor != "off")


func apply(on: bool) -> void:
	if not on or not motion:
		_flush_fades()
	if not on:
		core._step("polish: dividers")
		_apply_dividers(false)
		_apply_skills(false)
		_drop_hover()
		_hide_hint()
		core._step("polish: cursor")
		_apply_cursor(false)
		core._step("polish: digits")
		_apply_digits(false)
		core._step("polish: done")
	else:
		tick()


func shutdown() -> void:
	apply(false)


func reset_cache() -> void:
	_tex.clear()
	_styles.clear()
	_cursor_on = false


func _apply_bars(on: bool) -> void:
	for b in _alive(_bars):
		var t := b as TextureProgressBar
		if on:
			var under: Color = core._orig(t, &"tint_under")
			if under.a > 0.01:
				core._put(t, &"texture_under", _track_texture())
				core._put(t, &"tint_under", Color(1, 1, 1, under.a))
			core._put(t, &"texture_progress", _fill_texture())
			core._put(t, &"nine_patch_stretch", true)
			for side in [&"stretch_margin_left", &"stretch_margin_top", &"stretch_margin_right", &"stretch_margin_bottom"]:
				core._put(t, side, 3)
		else:
			core._restore(t)


func _track_texture() -> Texture2D:
	if _tex.has("track"):
		return _tex["track"]
	var s := 9
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var rim: Color = core.TRIM.darkened(0.25)
	for y in s:
		for x in s:
			var c := Color("#0d0c0b")
			if y == 1:
				c = c.darkened(0.5)
			if x == 0 or y == 0 or x == s - 1 or y == s - 1:
				c = rim
			img.set_pixel(x, y, c)
	_tex["track"] = ImageTexture.create_from_image(img)
	return _tex["track"]


func _fill_texture() -> Texture2D:
	if _tex.has("fill"):
		return _tex["fill"]
	var s := 9
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			if x == 0 or y == 0 or x == s - 1 or y == s - 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var v := 0.86
			if y == 1:
				v = 1.0
			elif y == s - 2:
				v = 0.62
			img.set_pixel(x, y, Color(v, v, v))
	_tex["fill"] = ImageTexture.create_from_image(img)
	return _tex["fill"]


func _apply_ranges(track_on: bool, gold_on: bool) -> void:
	for r in _alive(_ranges):
		if core._foreign(r):
			continue
		if not _shows_track(r):
			if core._saved.has(r):
				core._restore(r)
			continue
		var in_sidebar := _skill_of(r) != null
		if (in_sidebar and gold_on) or (not in_sidebar and track_on):
			core._put(r, &"theme_override_styles/background", _style("range_bg"))
			if in_sidebar:
				core._put(r, &"theme_override_styles/fill", _style("range_gold"))
		else:
			core._restore(r)


var _track_ok := {}

func _shows_track(r: Control) -> bool:
	var id := r.get_instance_id()
	if _track_ok.has(id):
		return _track_ok[id]
	if core._saved.has(r):
		return true
	var ok := true
	if r.get_parent() is BaseButton:
		ok = false
	else:
		var bg := r.get_theme_stylebox(&"background")
		if bg == null or bg is StyleBoxEmpty:
			ok = false
		elif bg is StyleBoxFlat:
			ok = (bg as StyleBoxFlat).bg_color.a > 0.15 or (bg as StyleBoxFlat).border_width_top > 0
	_track_ok[id] = ok
	return ok


func _skill_of(n: Node) -> Node:
	var c := n.get_parent()
	for _i in 6:
		if c == null:
			return null
		if c.name == &"LegacySkillNavigationButton":
			return c
		c = c.get_parent()
	return null


const SCROLL_W := 8

func _scroll_style(kind: String, horizontal: bool) -> StyleBox:
	var trim: Color = core.TRIM
	var gold: Color = core.GOLD
	var col: Color
	var inset := 0
	match kind:
		"scroll":
			col = Color(0.0, 0.0, 0.0, 0.32)
		"grab":
			col = trim.darkened(0.15)
			inset = 1
		"grab_hi":
			col = trim.lerp(gold, 0.35)
		_:
			col = gold
	var t := _scroll_capsule(SCROLL_W, inset, col, horizontal)
	var sb := StyleBoxTexture.new()
	sb.texture = t
	var cap := float(SCROLL_W / 2)
	var along := 0.0 if kind == "scroll" else 6.0
	if horizontal:
		sb.texture_margin_left = cap
		sb.texture_margin_right = cap
		sb.content_margin_left = along
		sb.content_margin_right = along
		sb.content_margin_top = cap
		sb.content_margin_bottom = cap
	else:
		sb.texture_margin_top = cap
		sb.texture_margin_bottom = cap
		sb.content_margin_top = along
		sb.content_margin_bottom = along
		sb.content_margin_left = cap
		sb.content_margin_right = cap
	return sb


func _scroll_capsule(w: int, inset: int, col: Color, horizontal: bool) -> ImageTexture:
	var key := "capsule:%d:%d:%s:%s" % [w, inset, col.to_html(), horizontal]
	if _tex.has(key):
		return _tex[key]
	var h := w + 1
	var img := Image.create(h if horizontal else w, w if horizontal else h, false, Image.FORMAT_RGBA8)
	var r := w / 2.0 - inset
	var cx := w / 2.0
	for y in h:
		for x in w:
			var hits := 0
			for sy in 4:
				for sx in 4:
					var px := x + (sx + 0.5) / 4.0
					var py := y + (sy + 0.5) / 4.0
					var cy := clampf(py, w / 2.0, h - w / 2.0)
					if Vector2(px - cx, py - cy).length() <= r:
						hits += 1
			var c := Color(col.r, col.g, col.b, col.a * hits / 16.0)
			if horizontal:
				img.set_pixel(y, x, c)
			else:
				img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


func _style(name: String) -> StyleBox:
	if _styles.has(name):
		return _styles[name]
	if name.begins_with("scroll") or name.begins_with("grab"):
		var sbx := _scroll_style(name.trim_suffix("_h"), name.ends_with("_h"))
		sbx.set_meta(&"mi2r_own", true)
		_styles[name] = sbx
		return sbx
	var gold: Color = core.GOLD
	var trim: Color = core.TRIM
	var sb: StyleBox
	match name:
		"range_bg":
			var f := StyleBoxFlat.new()
			f.bg_color = Color("#0d0c0b")
			f.border_color = trim.darkened(0.35)
			f.set_border_width_all(1)
			f.set_corner_radius_all(2)
			sb = f
		"range_gold":
			var f := StyleBoxFlat.new()
			f.bg_color = gold.darkened(0.08)
			f.border_color = gold.lightened(0.35)
			f.border_width_top = 1
			f.set_corner_radius_all(2)
			sb = f
		"tip_line":
			var l := StyleBoxLine.new()
			l.color = trim.lightened(0.15)
			l.thickness = 1
			l.grow_begin = 0
			l.grow_end = 0
			sb = l
		"hover":
			var f := StyleBoxFlat.new()
			f.draw_center = false
			f.border_color = Color(gold, 0.85)
			f.set_border_width_all(2)
			f.set_corner_radius_all(6)
			f.anti_aliasing = true
			sb = f
	sb.set_meta(&"mi2r_own", true)
	_styles[name] = sb
	return sb


func _apply_scrolls(on: bool) -> void:
	for s in _alive(_scrolls):
		if core._foreign(s):
			continue
		if on:
			var h := "_h" if s is HScrollBar else ""
			core._put(s, &"theme_override_styles/scroll", _style("scroll" + h))
			core._put(s, &"theme_override_styles/scroll_focus", _style("scroll" + h))
			core._put(s, &"theme_override_styles/grabber", _style("grab" + h))
			core._put(s, &"theme_override_styles/grabber_highlight", _style("grab_hi" + h))
			core._put(s, &"theme_override_styles/grabber_pressed", _style("grab_down" + h))
		else:
			core._restore(s)


func _apply_skills(on: bool) -> void:
	var done := {}
	for b in _alive(_skills):
		var nl = b.get("NameLabel")
		var act = b.get("NameLabelSettingsActive")
		var active: bool = on and nl is Label and act != null and (nl as Label).label_settings == act
		if act is LabelSettings and not done.has(act):
			done[act] = true
			if on:
				core._put(act, &"font_color", core.GOLD.lightened(0.25))
			else:
				core._unput(act, &"font_color")
		var mark := b.get_node_or_null("MI2ReskinActive") as Control
		if active and mark == null:
			mark = Control.new()
			mark.name = "MI2ReskinActive"
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.set_anchors_preset(Control.PRESET_FULL_RECT)
			mark.show_behind_parent = true
			mark.draw.connect(_draw_active.bind(mark))
			b.add_child(mark)
		elif not active and mark != null:
			b.remove_child(mark)
			mark.queue_free()
		for prop in [&"PressedStyle", &"HoverPressedStyle"]:
			var st = b.get(prop)
			if not (st is StyleBoxFlat) or done.has(st):
				continue
			done[st] = true
			var f := st as StyleBoxFlat
			if on:
				var a := 0.16 if prop == &"PressedStyle" else 0.24
				core._put(f, &"bg_color", Color(core.GOLD, a))
				core._put(f, &"border_color", core.GOLD)
				core._put(f, &"border_width_left", 3)
				core._put(f, &"corner_radius_top_left", 0)
				core._put(f, &"corner_radius_bottom_left", 0)
				_marked_styles[f] = true
			elif _marked_styles.has(f):
				_marked_styles.erase(f)
				for p in [&"bg_color", &"border_color", &"border_width_left", &"corner_radius_top_left",
						&"corner_radius_bottom_left"]:
					core._unput(f, p)
				if core.enabled:
					core._style_flat(f)


func _draw_active(m: Control) -> void:
	var h := m.size.y
	m.draw_rect(Rect2(0, 1, m.size.x, h - 2), Color(core.GOLD, 0.10))
	m.draw_rect(Rect2(0, 1, 3, h - 2), core.GOLD)


func _apply_dividers(on: bool) -> void:
	var groups = get_tree().root.get_node_or_null(core.SIDEBAR_GROUPS)
	if not on or groups == null:
		for d in _dividers:
			if is_instance_valid(d):
				d.get_parent().remove_child(d)
				d.queue_free()
		_dividers.clear()
		return
	for g in groups.get_children():
		var lb := g.get_child(0) as Label if g.get_child_count() > 0 else null
		if lb == null or lb.get_node_or_null("MI2ReskinDivider") != null:
			continue
		var d := Control.new()
		d.name = "MI2ReskinDivider"
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.set_anchors_preset(Control.PRESET_FULL_RECT)
		d.draw.connect(_draw_divider.bind(d, lb))
		lb.add_child(d)
		_dividers.append(d)


func _draw_divider(d: Control, lb: Label) -> void:
	var font := lb.get_theme_font(&"font")
	var fs := lb.get_theme_font_size(&"font_size")
	if lb.label_settings != null:
		if lb.label_settings.font != null:
			font = lb.label_settings.font
		fs = lb.label_settings.font_size
	var text_w := font.get_string_size(lb.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if font != null else 60.0
	var y := roundf(d.size.y * 0.55) + 0.5
	var x0 := text_w + 8.0
	var x1 := d.size.x - 10.0
	if x1 - x0 < 12.0:
		return
	var col: Color = core.TRIM
	d.draw_line(Vector2(x0, y), Vector2(x1 - 4.0, y), Color(col, 0.8), 1.0)
	var dia := _diamond(core.GOLD.darkened(0.15))
	d.draw_texture(dia, Vector2(x1 - dia.get_width() / 2.0, y - dia.get_height() / 2.0))


func _diamond(col: Color) -> ImageTexture:
	var key := "diamond:%s" % col.to_html()
	if _tex.has(key):
		return _tex[key]
	var w := 11
	var h := 9
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var hits := 0
			for sy in 4:
				for sx in 4:
					var dx := absf(x + (sx + 0.5) / 4.0 - w / 2.0) / 4.0
					var dy := absf(y + (sy + 0.5) / 4.0 - h / 2.0) / 3.0
					if dx + dy <= 1.0:
						hits += 1
			img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * hits / 16.0))
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


func _apply_tooltips(on: bool) -> void:
	var font: Font = core._get_title_font() if core.title_font else null
	for n in _alive(_tip_bits):
		if n is Label:
			if on:
				core._label_look(n, font, core.GOLD.lightened(0.1), 1)
			else:
				core._restore(n)
		elif n is HSeparator:
			if on:
				core._put(n, &"theme_override_styles/separator", _style("tip_line"))
			else:
				core._restore(n)


var _fade_probe: Control = null
var _fade_samples: Array = []

func page_opened(page: Control) -> void:
	if motion and _on():
		_fade_in(page)
	if core._dev_timing:
		_fade_probe = page
		_fade_samples = []


const FADE_TIME := 0.2
var _fades: Array = []
var _last_frame_us := 0
var _usual_dt := 1.0 / 60.0

func _fade_in(page: Control) -> void:
	if not page.has_meta(&"mi2r_alpha"):
		page.set_meta(&"mi2r_alpha", page.modulate.a if page.modulate.a > 0.05 else 1.0)
	var target := float(page.get_meta(&"mi2r_alpha"))
	for f in _fades:
		if f[0] == page:
			f[2] = Time.get_ticks_msec()
			f[3] = 0
			f[4] = -1.0
			page.modulate.a = 0.0
			return
	_fades.append([page, target, Time.get_ticks_msec(), 0, -1.0])
	page.modulate.a = 0.0


func _flush_fades() -> void:
	for f in _fades:
		if is_instance_valid(f[0]):
			(f[0] as Control).modulate.a = float(f[1])
	_fades.clear()


func _run_fades() -> void:
	var now := Time.get_ticks_usec()
	var dt := (now - _last_frame_us) / 1000000.0 if _last_frame_us > 0 else 1.0
	_last_frame_us = now
	var smooth := dt < maxf(0.04, _usual_dt * 1.6)
	if smooth and dt < 0.25:
		_usual_dt = lerpf(_usual_dt, dt, 0.05)
	if _fades.is_empty():
		return
	var i := 0
	while i < _fades.size():
		var f: Array = _fades[i]
		var page = f[0]
		if page == null or not is_instance_valid(page):
			_fades.remove_at(i)
			continue
		if not page.is_inside_tree():
			page.modulate.a = float(f[1])
			_fades.remove_at(i)
			continue
		if float(f[4]) < 0.0:
			f[3] = int(f[3]) + 1 if smooth else 0
			var waited := Time.get_ticks_msec() - int(f[2])
			if int(f[3]) >= 3 or (waited > 300 and smooth) or waited > 1000:
				f[4] = 0.0
			else:
				i += 1
				continue
		f[4] = minf(float(f[4]) + minf(dt, maxf(1.0 / 60.0, _usual_dt)) / FADE_TIME, 1.0)
		var k: float = f[4]
		if k >= 1.0:
			page.modulate.a = float(f[1])
			_fades.remove_at(i)
			continue
		page.modulate.a = float(f[1]) * (1.0 - (1.0 - k) * (1.0 - k))
		i += 1


func frame() -> void:
	_update_hint()
	_run_fades()
	if _fade_probe != null:
		if is_instance_valid(_fade_probe) and _fade_samples.size() < 14:
			_fade_samples.append(snappedf(_fade_probe.modulate.a, 0.01))
		else:
			core._log("fade: page opacity over its first frames: %s" % str(_fade_samples))
			_fade_probe = null


func _drop_hover() -> void:
	if _hover != null and is_instance_valid(_hover):
		if _hover.get_parent() != null:
			_hover.get_parent().remove_child(_hover)
		_hover.queue_free()
	_hover = null
	_hover_item = null


func _apply_cursor(on: bool) -> void:
	if on == _cursor_on:
		return
	_cursor_on = on
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]:
		if on:
			Input.set_custom_mouse_cursor(_sword(false), shape, Vector2(1, 1))
		else:
			Input.set_custom_mouse_cursor(null, shape)


func input(e: InputEvent) -> void:
	if not _cursor_on or not (e is InputEventMouseButton) or (e as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	var down := (e as InputEventMouseButton).pressed
	if down == _cursor_down:
		return
	_cursor_down = down
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]:
		Input.set_custom_mouse_cursor(_sword(down), shape, Vector2(1, 1))


func _sword(glint: bool) -> Texture2D:
	var key := "sword_glint" if glint else "sword"
	if _tex.has(key):
		return _tex[key]
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var gold: Color = core.GOLD
	var blade := [Vector2(1.5, 1.5), Vector2(19, 19), 0.4, 1.9, Color("#dfe4ea")]
	var guard := [Vector2(14.5, 23.5), Vector2(23.5, 14.5), 1.6, 1.6, gold]
	var grip := [Vector2(20.5, 20.5), Vector2(26, 26), 1.4, 1.4, Color("#6b4a2b")]
	var pommel := [Vector2(27.5, 27.5), Vector2(27.5, 27.5), 2.3, 2.3, gold.darkened(0.1)]
	var parts := [blade, grip, guard, pommel]
	for y in s:
		for x in s:
			var p := Vector2(x + 0.5, y + 0.5)
			var col := Color(0, 0, 0, 0)
			var outline := false
			for part in parts:
				var d := _capsule(p, part[0], part[1], part[2], part[3])
				if d <= 0.0:
					col = part[4]
					if part == blade:
						var t := clampf((p - (part[0] as Vector2)).dot(Vector2(1, 1).normalized()) / 24.6, 0.0, 1.0)
						var off := absf((p.x - p.y) / sqrt(2.0))
						if off < 0.5:
							col = Color("#9aa3ad")
						if glint and t > 0.25 and t < 0.55 and off < 1.2:
							col = gold.lightened(0.45)
					elif part == guard or part == pommel:
						if p.x + p.y < (part[0] as Vector2).x + (part[0] as Vector2).y + 0.2 and part == pommel:
							col = col.lightened(0.3)
				elif d <= 1.1:
					outline = true
			if col.a == 0.0 and outline:
				col = Color(0.06, 0.05, 0.04, 1.0)
			img.set_pixel(x, y, col)
	_tex[key] = ImageTexture.create_from_image(img)
	return _tex[key]


func _capsule(p: Vector2, a: Vector2, b: Vector2, ra: float, rb: float) -> float:
	var ab := b - a
	var t := 0.0 if ab.length_squared() == 0.0 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t) - lerpf(ra, rb, t)


func _note_font(lb: Label) -> void:
	var f: Font = lb.label_settings.font if lb.label_settings != null and lb.label_settings.font != null else lb.get_theme_font(&"font")
	if f != null and not _fonts.has(f):
		_fonts[f] = true
		if _on() and even_digits:
			_digits_font(f, true)


func _apply_digits(on: bool) -> void:
	for f in _fonts.keys():
		if is_instance_valid(f):
			_digits_font(f, on)


func _digits_font(f: Font, on: bool) -> void:
	var tnum := TextServerManager.get_primary_interface().name_to_tag("tnum")
	var prop := &"opentype_features" if f is FontVariation else (&"opentype_feature_overrides" if f is FontFile else &"")
	if prop == &"":
		return
	if on:
		var d: Dictionary = (core._orig(f, prop) as Dictionary).duplicate()
		if d.get(tnum, 0) == 1:
			return
		d[tnum] = 1
		core._put(f, prop, d)
	else:
		core._unput(f, prop)
	if f is FontVariation and (f as FontVariation).base_font != null:
		_digits_font((f as FontVariation).base_font, on)
