extends Node

const SETTINGS := "Main/ApplicationViewContainer/GameView/PauseOverlay/Settings"
const CONTENT := SETTINGS + "/MarginContainer/PanelContainer/MarginContainer/ContentContainer"
const ROWS := "MarginContainer/PanelContainer/MarginContainer/ScrollContainer/MarginContainer/VBoxContainer"

var core: Node = null
var _category: VBoxContainer = null
var _button: Button = null
var _view: Control = null
var _rows: Array = []

const ITEMS := [
	["heading", "", "", "Look"],
	["toggle", "reskin", "enabled", "Reskin", "Switch the whole reskin on or off. F7 does the same while you play."],
	["choice", "reskin", "look", "Panel style", "Crafted: trims, bevels and one look per kind of part. Flat: plain panels with a thin rim.",
		[["crafted", "Crafted"], ["flat", "Flat"]]],
	["choice", "reskin", "preset", "Finish", "Soft: flat, rounded panels in muted colours, like Melvor Idle 1. Crafted: bronze trims, bevels and gold underlines. Gilded: extra gold.",
		[["crafted", "Crafted"], ["soft", "Soft"], ["gilded", "Gilded"]]],
	["choice", "reskin", "palette", "Colours", "MI2: Melvor Idle 2's warm browns. MI1 Slate: Melvor Idle 1's slate blues. Graphite: neutral dark greys. Midnight: deep blue-black.",
		[["mi2", "MI2"], ["slate", "MI1 Slate"], ["graphite", "Graphite"], ["midnight", "Midnight"]]],
	["choice", "reskin", "accent", "Accent", "The colour of bars, dividers, scrollbar grips and selected outlines. Finish's: the finish's own colour.",
		[["finish", "Finish's"], ["sand", "Sand"], ["gold", "Gold"], ["silver", "Silver"]]],
	["toggle", "reskin", "title_font", "Title fonts", "Header and page titles in Alegreya SC, small captions in Alegreya Sans SC."],
	["choice", "reskin", "body_font", "Body font", "Rubik is softly rounded and easy to read at small sizes, or keep the game's own font.",
		[["Rubik", "Rubik"], ["game", "Game's"]]],
	["heading", "", "", "Frame & Pages"],
	["toggle", "frame", "tidy", "Tidy the frame", "Hides the \"coming soon\" teaser, labels the footer, gold sidebar headings, and a slot in the top bar for other mods."],
	["toggle", "pages", "tidy", "Tidy the pages", "Lists show only the next locked entry, the Creating column only while crafting, Bank shortcuts behind a \"?\", grey locked text."],
	["toggle", "pages", "remember_category", "Remember categories", "Crafting pages and the Shop reopen the category you used last."],
	["choice", "pages", "picture_shadows", "Picture shadows", "The black shadow behind rock, tree and monster pictures.",
		[["off", "Off"], ["faint", "Faint"], ["game", "Game's"]]],
	["toggle", "pages", "detail_frame", "Frame the detail column", "A framed panel behind the selected rock's or tree's details."],
	["heading", "", "", "Polish"],
	["toggle", "polish", "bars", "Crafted progress bars", "A dark inset track with a bronze rim and a bevelled fill."],
	["toggle", "polish", "scrollbars", "Bronze scrollbars", "Rounded scrollbars with a bronze grip."],
	["toggle", "polish", "sidebar", "Sidebar polish", "Gold level bars, a gold edge on the active skill, and dividers after the headings."],
	["toggle", "polish", "motion", "Motion", "Pages fade in smoothly when they open."],
	["toggle", "polish", "tooltips", "Item tooltips", "The item's name in the title font and gold."],
	["toggle", "polish", "even_digits", "Even-width digits", "Numbers and timers keep their width as they change."],
	["choice", "polish", "cursor", "Mouse pointer", "A small sword, or the normal pointer.",
		[["sword", "Sword"], ["off", "Normal"]]],
	["heading", "", "", "Melvor Idle 1"],
	["toggle", "mi1", "icons", "Melvor Idle 1 icons", "Skill and item icons from your own Melvor Idle 1 install, where one exists. Nothing is copied."],
	["reset"],
]

const VARS := {
	"reskin/enabled": ["core", "enabled"], "reskin/look": ["core", "look"], "reskin/preset": ["core", "preset"],
	"reskin/title_font": ["core", "title_font"], "reskin/body_font": ["core", "body_font"], "frame/tidy": ["core", "tidy_frame"], "pages/tidy": ["core", "tidy_pages"],
	"pages/remember_category": ["core", "remember_category"], "pages/picture_shadows": ["core", "picture_shadows"],
	"pages/detail_frame": ["core", "detail_frame"], "polish/bars": ["polish", "bars"],
	"polish/scrollbars": ["polish", "scrollbars"], "polish/sidebar": ["polish", "sidebar"],
	"polish/motion": ["polish", "motion"], "polish/tooltips": ["polish", "tooltips"],
	"polish/even_digits": ["polish", "even_digits"], "polish/cursor": ["polish", "cursor"],
	"mi1/icons": ["core", "mi1_icons"], "reskin/palette": ["core", "colours"], "reskin/accent": ["core", "accent"],
}


func setup(c: Node) -> void:
	core = c


func shutdown() -> void:
	for n in [_category, _view]:
		if n != null and is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_category = null
	_view = null
	_button = null
	_rows.clear()


func tick() -> void:
	var settings := get_tree().root.get_node_or_null(SETTINGS)
	if settings == null:
		return
	if _view == null or not is_instance_valid(_view) or not _view.is_inside_tree() 			or _button == null or not is_instance_valid(_button) or not _button.is_inside_tree():
		_build(settings)
		return
	if not _view.visible:
		return
	var others_shown := false
	for v in _view.get_parent().get_children():
		if v != _view and v is Control and (v as Control).visible:
			others_shown = true
	if others_shown or not _button.button_pressed:
		_view.visible = false
		if _button.button_pressed and others_shown:
			_button.set_pressed_no_signal(false)
		return
	_refresh()


func _build(settings: Node) -> void:
	shutdown()
	var left := get_tree().root.get_node_or_null(CONTENT + "/LeftContainer") as Control
	var pages := get_tree().root.get_node_or_null(CONTENT + "/MarginContainer/SettingsContainer") as Control
	if left == null or pages == null:
		return
	var general := left.get_node_or_null("GeneralSettingsCategoryContainer") as VBoxContainer
	var game_page := pages.get_node_or_null("GameSettingsView") as Control
	if general == null or game_page == null:
		return
	var heading_tpl := general.get_node_or_null("HBoxContainer2")
	var button_tpl := general.get_node_or_null("GameSettingsButton") as Button
	var row_tpl := game_page.get_node_or_null(ROWS + "/StopActionOnFullBank")
	var page_tpl := game_page.get_node_or_null("MarginContainer")
	if heading_tpl == null or button_tpl == null or row_tpl == null or page_tpl == null:
		return
	_category = VBoxContainer.new()
	_category.name = "MI2ReskinCategory"
	_category.add_theme_constant_override(&"separation", general.get_theme_constant(&"separation"))
	var h := heading_tpl.duplicate(0)
	_set_heading(h, "Mods")
	_category.add_child(h)
	_button = button_tpl.duplicate(0) as Button
	_button.name = "MI2ReskinSettingsButton"
	_button.text = "Reskin"
	_button.toggle_mode = true
	_button.button_group = button_tpl.button_group
	_button.set_pressed_no_signal(false)
	_button.toggled.connect(func(on: bool):
		if on:
			_open()
		elif _view != null and is_instance_valid(_view):
			_view.visible = false)
	_category.add_child(_button)
	left.add_child(_category)
	left.move_child(_category, general.get_index() + 1)
	_view = VBoxContainer.new()
	_view.name = "MI2ReskinSettingsView"
	_view.size_flags_horizontal = game_page.size_flags_horizontal
	_view.size_flags_vertical = game_page.size_flags_vertical
	_view.custom_minimum_size = game_page.custom_minimum_size
	_view.visible = false
	var body := page_tpl.duplicate(0)
	_view.add_child(body)
	var title := body.find_child("Title", true, false) as Label
	if title != null:
		title.text = "Reskin"
	pages.add_child(_view)
	var rows := body.get_node_or_null(ROWS.trim_prefix("MarginContainer/"))
	if rows == null:
		return
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()
	for item in ITEMS:
		match item[0]:
			"heading":
				var hh := heading_tpl.duplicate(0)
				_set_heading(hh, item[3])
				rows.add_child(hh)
			"toggle":
				rows.add_child(_toggle_row(row_tpl, item))
			"choice":
				rows.add_child(_choice_row(row_tpl, button_tpl, item))
			"reset":
				var b := button_tpl.duplicate(0) as Button
				b.text = "Reset to defaults"
				b.toggle_mode = false
				b.button_group = null
				b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				b.custom_minimum_size = Vector2(200, 36)
				b.pressed.connect(_reset)
				var note := Label.new()
				note.text = "Your choices are kept in your own game folder (mi2_reskin_settings.cfg). F7 switches the reskin off and on while you play.\nMI2 Reskin version %s" %(str(core.get("VERSION")) if core != null else "?")
				note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				var grey = row_tpl.find_child("Description", true, false)
				if grey is Label:
					note.label_settings = (grey as Label).label_settings
				var box := VBoxContainer.new()
				box.add_theme_constant_override(&"separation", 8)
				var gap := Control.new()
				gap.custom_minimum_size = Vector2(0, 6)
				box.add_child(gap)
				box.add_child(b)
				box.add_child(note)
				rows.add_child(box)
	_refresh()


func _set_heading(h: Node, text: String) -> void:
	var lb := h.find_child("Label", true, false) as Label
	if lb != null:
		lb.text = text


func _labels(row: Node, title: String, desc: String) -> void:
	var dn := row.find_child("DisplayName", true, false) as Label
	var ds := row.find_child("Description", true, false) as Label
	var d2 := row.find_child("Description2", true, false)
	if dn != null:
		dn.text = title
	if ds != null:
		ds.text = desc
	if d2 != null:
		d2.get_parent().remove_child(d2)
		d2.queue_free()


func _toggle_row(tpl: Node, item: Array) -> Node:
	var row := tpl.duplicate(0)
	row.name = "MI2Reskin_" + item[2]
	_labels(row, item[3], item[4])
	var cb: CheckButton = null
	for c in row.get_children():
		if c is CheckButton:
			cb = c
	if cb != null:
		cb.toggled.connect(_changed.bind(item[1], item[2]))
		_rows.append(["toggle", item[1], item[2], cb])
	return row


func _choice_row(tpl: Node, button_tpl: Button, item: Array) -> Node:
	var row := tpl.duplicate(0)
	row.name = "MI2Reskin_" + item[2]
	_labels(row, item[3], item[4])
	for c in row.get_children():
		if c is CheckButton:
			row.remove_child(c)
			c.queue_free()
		elif c is MarginContainer:
			(c as MarginContainer).add_theme_constant_override(&"margin_right", 0)
	var vb := row.find_child("VBoxContainer", true, false) as VBoxContainer
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 6)
	var group := ButtonGroup.new()
	var buttons := {}
	for ch in item[5]:
		var b := button_tpl.duplicate(0) as Button
		b.text = ch[1]
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(96, 32)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var sec: String = item[1]
		var key: String = item[2]
		var val: String = ch[0]
		b.toggled.connect(func(on: bool): if on: _changed(true, sec, key, val))
		line.add_child(b)
		buttons[ch[0]] = b
	if vb != null:
		vb.mouse_filter = Control.MOUSE_FILTER_PASS
		vb.add_child(line)
	(row as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	_rows.append(["choice", item[1], item[2], buttons])
	return row


func _value(section: String, key: String):
	var where = VARS.get(section + "/" + key)
	if where == null:
		return null
	var obj: Object = core if where[0] == "core" else core.get("_polish")
	return obj.get(where[1]) if obj != null else null


func _refresh() -> void:
	for r in _rows:
		var v = _value(r[1], r[2])
		if v == null:
			continue
		if r[0] == "toggle":
			var cb := r[3] as CheckButton
			if is_instance_valid(cb) and cb.button_pressed != bool(v):
				cb.set_pressed_no_signal(bool(v))
		else:
			for val in r[3]:
				var b := r[3][val] as Button
				if is_instance_valid(b) and b.button_pressed != (str(v) == val):
					b.set_pressed_no_signal(str(v) == val)


func _open() -> void:
	var settings := get_tree().root.get_node_or_null(SETTINGS)
	if settings != null and settings.has_method("HideAllSettingsViews"):
		settings.call("HideAllSettingsViews")
	else:
		for v in _view.get_parent().get_children():
			if v is Control:
				(v as Control).visible = false
	_view.visible = true
	_refresh()


func _changed(pressed: bool, section: String, key: String, value = null) -> void:
	var v = pressed if value == null else value
	if _value(section, key) == v:
		return
	var mine := ConfigFile.new()
	mine.load(core.USER_CFG_PATH)
	mine.set_value(section, key, v)
	mine.save(core.USER_CFG_PATH)
	if section == "reskin" and key == "enabled":
		core.set_enabled(bool(v))
	else:
		core.apply_settings()
	_refresh()


func _reset() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(core.USER_CFG_PATH))
	core.apply_settings()
	_refresh()
