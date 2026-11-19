extends Node

const CORE_PATH := "res://mod/mi2_reskin_core.gd"
const CFG_PATH := "res://mod/mi2_reskin.cfg"
const CMD_PATH := "user://mi2_reskin_cmd.txt"
const LOG_PATH := "user://mi2_reskin.log"

var _core: Node = null
var _dev := false
var _next_poll := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		_dev = bool(cfg.get_value("dev", "enabled", false))
	_load_core()


func _load_core() -> void:
	var scr: GDScript
	if _core == null:
		scr = load(CORE_PATH)
	else:
		scr = GDScript.new()
		scr.source_code = FileAccess.get_file_as_string(CORE_PATH)
		if scr.reload() != OK:
			_log("reload: %s has a GDScript error; keeping the running version" % CORE_PATH)
			return
		_log("reload: compiled; stopping the running version")
		if _core.has_method("shutdown"):
			_core.call("shutdown")
		remove_child(_core)
		_core.free()
		_core = null
		_log("reload: old version stopped")
	if scr == null or not scr.can_instantiate():
		_log("could not load %s (see the game's log for the GDScript error)" % CORE_PATH)
		return
	_core = Node.new()
	_core.name = "Core"
	_core.set_script(scr)
	add_child(_core)


func _process(_delta: float) -> void:
	if not _dev:
		return
	var now := Time.get_ticks_msec()
	if now < _next_poll:
		return
	_next_poll = now + 500
	if not FileAccess.file_exists(CMD_PATH):
		return
	var text := FileAccess.get_file_as_string(CMD_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CMD_PATH))
	for line in text.split("\n"):
		line = line.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		_log("dev command: " + line)
		if line == "reload":
			_load_core()
		elif _core != null and _core.has_method("dev_command"):
			_core.call("dev_command", line)


func _log(msg: String) -> void:
	print("[MI2Reskin] ", msg)
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line("%s %s" % [Time.get_datetime_string_from_system(), msg])
