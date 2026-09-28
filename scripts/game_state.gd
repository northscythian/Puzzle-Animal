extends Node

signal changed

var save_path := "user://save.cfg"

var money: int = 1200
var quality: int = 0
var creativity: int = 0
var care: int = 0
var experience: int = 0
var completed_projects: int = 0
var cafe_completed: bool = false
var kite_workshop_completed: bool = false
var cottage_owned: bool = false
var cottage_completed: bool = false
var greenhouse_completed: bool = false
var observatory_completed: bool = false
var tools_level: int = 0
var design_level: int = 0
var client_level: int = 0
var bruno_skill: bool = false
var lika_skill: bool = false
var topa_skill: bool = false
var iskra_skill: bool = false
var current_event := "none"
var last_event_project_count: int = -1
var tutorial_seen: bool = false
var finale_seen: bool = false
var master_volume: float = 80.0
var music_volume: float = 55.0
var sfx_volume: float = 75.0
var text_speed: float = 45.0
var fullscreen: bool = false
var window_initialized := false
var puzzle_session: Dictionary = {}
var puzzle_records: Dictionary = {}
var story_chapters: Dictionary = {}
var journey: Dictionary = {}


func _ready() -> void:
	load_game()
	apply_settings()


func reset() -> void:
	money = 1200
	quality = 0
	creativity = 0
	care = 0
	experience = 0
	completed_projects = 0
	cafe_completed = false
	kite_workshop_completed = false
	cottage_owned = false
	cottage_completed = false
	greenhouse_completed = false
	observatory_completed = false
	tools_level = 0
	design_level = 0
	client_level = 0
	bruno_skill = false
	lika_skill = false
	topa_skill = false
	iskra_skill = false
	current_event = "none"
	last_event_project_count = -1
	tutorial_seen = false
	finale_seen = false
	puzzle_session = {}
	puzzle_records = {}
	story_chapters = {}
	journey = {}
	save_game()
	changed.emit()


func apply_project_result(net_income: int, quality_gain: int, creativity_gain: int, care_gain: int, xp_gain: int) -> void:
	money += net_income
	quality += quality_gain
	creativity += creativity_gain
	care += care_gain
	experience += xp_gain
	completed_projects += 1
	save_game()
	changed.emit()


func complete_project(project_id: String, net_income: int, quality_gain: int, creativity_gain: int, care_gain: int, xp_gain: int) -> bool:
	if is_project_completed(project_id):
		return false
	match project_id:
		"cafe": cafe_completed = true
		"kite_workshop": kite_workshop_completed = true
		"greenhouse": greenhouse_completed = true
		"observatory": observatory_completed = true
		_: return false
	money += net_income
	quality += quality_gain
	creativity += creativity_gain
	care += care_gain
	experience += xp_gain
	completed_projects += 1
	save_game()
	changed.emit()
	return true


func is_project_completed(project_id: String) -> bool:
	match project_id:
		"cafe": return cafe_completed
		"kite_workshop": return kite_workshop_completed
		"canal_cottage": return cottage_completed
		"greenhouse": return greenhouse_completed
		"observatory": return observatory_completed
		_: return false


func purchase_upgrade(upgrade_id: String, cost: int) -> bool:
	if money < cost:
		return false
	match upgrade_id:
		"tools":
			if tools_level > 0: return false
			tools_level = 1
		"design":
			if design_level > 0: return false
			design_level = 1
		"client":
			if client_level > 0: return false
			client_level = 1
		_: return false
	money -= cost
	save_game()
	changed.emit()
	return true


func available_skill_points() -> int:
	var earned := int(experience / 50)
	var spent := int(bruno_skill) + int(lika_skill) + int(topa_skill) + int(iskra_skill)
	return maxi(0, earned - spent)


func unlock_hero_skill(hero_id: String) -> bool:
	if available_skill_points() <= 0:
		return false
	match hero_id:
		"bruno":
			if bruno_skill: return false
			bruno_skill = true
		"lika":
			if lika_skill: return false
			lika_skill = true
		"topa":
			if topa_skill: return false
			topa_skill = true
		"iskra":
			if iskra_skill: return false
			iskra_skill = true
		_: return false
	save_game()
	changed.emit()
	return true


func can_draw_event() -> bool:
	return current_event == "none" and last_event_project_count != completed_projects


func draw_event() -> String:
	if not can_draw_event():
		return current_event
	var events := ["supplier_discount", "storm_warning", "great_review", "antique_find"]
	current_event = events[randi() % events.size()]
	last_event_project_count = completed_projects
	save_game()
	changed.emit()
	return current_event


func consume_event() -> void:
	if current_event == "none":
		return
	current_event = "none"
	save_game()
	changed.emit()


func mark_tutorial_seen() -> void:
	if tutorial_seen:
		return
	tutorial_seen = true
	save_game()
	changed.emit()


func mark_finale_seen() -> void:
	if finale_seen:
		return
	finale_seen = true
	save_game()
	changed.emit()


func purchase_cottage(cost: int) -> bool:
	if cottage_owned or cottage_completed or money < cost:
		return false
	money -= cost
	cottage_owned = true
	save_game()
	changed.emit()
	return true


func complete_cottage(sale_income: int, quality_gain: int, creativity_gain: int, care_gain: int, xp_gain: int) -> bool:
	if not cottage_owned or cottage_completed:
		return false
	cottage_owned = false
	cottage_completed = true
	money += sale_income
	quality += quality_gain
	creativity += creativity_gain
	care += care_gain
	experience += xp_gain
	completed_projects += 1
	save_game()
	changed.emit()
	return true


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("company", "money", money)
	config.set_value("company", "quality", quality)
	config.set_value("company", "creativity", creativity)
	config.set_value("company", "care", care)
	config.set_value("company", "experience", experience)
	config.set_value("company", "completed_projects", completed_projects)
	config.set_value("company", "cafe_completed", cafe_completed)
	config.set_value("company", "kite_workshop_completed", kite_workshop_completed)
	config.set_value("company", "cottage_owned", cottage_owned)
	config.set_value("company", "cottage_completed", cottage_completed)
	config.set_value("company", "greenhouse_completed", greenhouse_completed)
	config.set_value("company", "observatory_completed", observatory_completed)
	config.set_value("company", "tools_level", tools_level)
	config.set_value("company", "design_level", design_level)
	config.set_value("company", "client_level", client_level)
	config.set_value("skills", "bruno", bruno_skill)
	config.set_value("skills", "lika", lika_skill)
	config.set_value("skills", "topa", topa_skill)
	config.set_value("skills", "iskra", iskra_skill)
	config.set_value("events", "current", current_event)
	config.set_value("events", "last_project_count", last_event_project_count)
	config.set_value("story", "tutorial_seen", tutorial_seen)
	config.set_value("story", "finale_seen", finale_seen)
	config.set_value("puzzle", "session", puzzle_session)
	config.set_value("puzzle", "records", puzzle_records)
	config.set_value("story", "chapters", story_chapters)
	config.set_value("story", "journey", journey)
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "text_speed", text_speed)
	config.set_value("settings", "fullscreen", fullscreen)
	if OS.has_feature("web"):
		Platform.save_text(config.encode_to_text())
		return
	# Write the new save fully before replacing the previous valid save.
	var temporary := save_path + ".tmp"
	var error := config.save(temporary)
	if error != OK:
		push_error("Cannot write save: %s" % error_string(error))
		return
	var previous := ConfigFile.new()
	if previous.load(save_path) == OK:
		error = DirAccess.copy_absolute(save_path, save_path + ".bak")
		if error != OK:
			push_error("Cannot back up save: %s" % error_string(error))
			return
	error = DirAccess.rename_absolute(temporary, save_path)
	if error != OK:
		push_error("Cannot replace save: %s" % error_string(error))


func load_game() -> void:
	var config := ConfigFile.new()
	if OS.has_feature("web"):
		if config.parse(Platform.load_text()) != OK: return
	elif config.load(save_path) != OK:
		if config.load(save_path + ".bak") != OK:
			return
	money = int(config.get_value("company", "money", 1200))
	quality = int(config.get_value("company", "quality", 0))
	creativity = int(config.get_value("company", "creativity", 0))
	care = int(config.get_value("company", "care", 0))
	experience = int(config.get_value("company", "experience", 0))
	completed_projects = int(config.get_value("company", "completed_projects", 0))
	cafe_completed = bool(config.get_value("company", "cafe_completed", completed_projects > 0))
	kite_workshop_completed = bool(config.get_value("company", "kite_workshop_completed", completed_projects > 1))
	cottage_owned = bool(config.get_value("company", "cottage_owned", false))
	cottage_completed = bool(config.get_value("company", "cottage_completed", completed_projects > 2))
	greenhouse_completed = bool(config.get_value("company", "greenhouse_completed", completed_projects > 3))
	observatory_completed = bool(config.get_value("company", "observatory_completed", completed_projects > 4))
	tools_level = int(config.get_value("company", "tools_level", 0))
	design_level = int(config.get_value("company", "design_level", 0))
	client_level = int(config.get_value("company", "client_level", 0))
	bruno_skill = bool(config.get_value("skills", "bruno", false))
	lika_skill = bool(config.get_value("skills", "lika", false))
	topa_skill = bool(config.get_value("skills", "topa", false))
	iskra_skill = bool(config.get_value("skills", "iskra", false))
	current_event = str(config.get_value("events", "current", "none"))
	last_event_project_count = int(config.get_value("events", "last_project_count", -1))
	tutorial_seen = bool(config.get_value("story", "tutorial_seen", completed_projects > 0))
	finale_seen = bool(config.get_value("story", "finale_seen", false))
	puzzle_session = config.get_value("puzzle", "session", {})
	puzzle_records = config.get_value("puzzle", "records", {})
	story_chapters = config.get_value("story", "chapters", {})
	journey = config.get_value("story", "journey", {})
	master_volume = float(config.get_value("settings", "master_volume", 80.0))
	music_volume = float(config.get_value("settings", "music_volume", 55.0))
	sfx_volume = float(config.get_value("settings", "sfx_volume", 75.0))
	text_speed = float(config.get_value("settings", "text_speed", 45.0))
	fullscreen = bool(config.get_value("settings", "fullscreen", false))


func save_settings(volume: float, speed: float, use_fullscreen: bool, music := music_volume, sfx := sfx_volume) -> void:
	master_volume = clampf(volume, 0.0, 100.0)
	music_volume = clampf(float(music), 0.0, 100.0)
	sfx_volume = clampf(float(sfx), 0.0, 100.0)
	text_speed = clampf(speed, 20.0, 100.0)
	fullscreen = use_fullscreen
	apply_settings()
	save_game()
	changed.emit()


func apply_settings() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume / 100.0) if master_volume > 0.0 else -80.0)
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume / 100.0) if music_volume > 0.0 else -80.0)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume / 100.0) if sfx_volume > 0.0 else -80.0)
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		var mode_changed := DisplayServer.window_get_mode() != target_mode
		if mode_changed:
			DisplayServer.window_set_mode(target_mode)
		if not fullscreen and (mode_changed or not window_initialized):
			fit_window_to_screen()
		window_initialized = true


func fit_window_to_screen() -> void:
	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var available := Vector2(area.size) - Vector2(48, 80)
	var factor := minf(1.0, minf(available.x / 1280.0, available.y / 720.0))
	var fitted := Vector2i(Vector2(1280, 720) * maxf(0.1, factor))
	DisplayServer.window_set_size(fitted)
	DisplayServer.window_set_position(area.position + (area.size - fitted) / 2)
