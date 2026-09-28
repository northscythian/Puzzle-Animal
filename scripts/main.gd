extends Control

const OFFICE_TEXTURE := preload("res://assets/backgrounds/office.png")
const CAFE_BEFORE_TEXTURE := preload("res://assets/backgrounds/cafe_before.png")
const CAFE_AFTER_TEXTURE := preload("res://assets/backgrounds/cafe_after.png")
const CITY_MAP_TEXTURE := preload("res://assets/backgrounds/city_map.png")
const KITE_BEFORE_TEXTURE := preload("res://assets/backgrounds/kite_workshop_before.png")
const KITE_AFTER_TEXTURE := preload("res://assets/backgrounds/kite_workshop_after.png")
const COTTAGE_BEFORE_TEXTURE := preload("res://assets/backgrounds/canal_cottage_before.png")
const COTTAGE_AFTER_TEXTURE := preload("res://assets/backgrounds/canal_cottage_after.png")
const GREENHOUSE_BEFORE_TEXTURE := preload("res://assets/backgrounds/greenhouse_before.png")
const GREENHOUSE_AFTER_TEXTURE := preload("res://assets/backgrounds/greenhouse_after.png")
const OBSERVATORY_BEFORE_TEXTURE := preload("res://assets/backgrounds/observatory_before.png")
const OBSERVATORY_AFTER_TEXTURE := preload("res://assets/backgrounds/observatory_after.png")
const BRUNO_PORTRAITS := preload("res://assets/characters/bruno_expressions.png")
const LIKA_PORTRAITS := preload("res://assets/characters/lika_expressions.png")
const TOPA_PORTRAITS := preload("res://assets/characters/topa_expressions.png")
const ISKRA_PORTRAITS := preload("res://assets/characters/iskra_expressions.png")
const RUDI_PORTRAITS := preload("res://assets/characters/rudi_expressions.png")
const MIRA_PORTRAITS := preload("res://assets/characters/mira_expressions.png")
const FILIN_PORTRAITS := preload("res://assets/characters/professor_filin_expressions.png")
const TORTILLA_PORTRAITS := preload("res://assets/characters/tortilla_expressions.png")

var scene_image: TextureRect
var gallery: Control
var pending_stars := 0
const PROJECT_IDS := ["cafe", "kite_workshop", "canal_cottage", "greenhouse", "observatory"]
const PROJECT_TITLES := ["Кафе, которое накренилось", "Мастерская ветра", "Домик у канала", "Теплица над пекарней", "Старая обсерватория"]
var top_bar: PanelContainer
var money_label: Label
var reputation_label: Label
var mission_label: Label
var title_panel: PanelContainer
var title_button: Button
var hub_panel: PanelContainer
var hub_box: VBoxContainer
var contracts_panel: PanelContainer
var contracts_box: VBoxContainer
var map_panel: PanelContainer
var garden_button: Button
var hill_button: Button
var portfolio_panel: PanelContainer
var portfolio_box: VBoxContainer
var skills_panel: PanelContainer
var skills_box: VBoxContainer
var skills_button: Button
var event_button: Button
var upgrades_panel: PanelContainer
var upgrades_box: VBoxContainer
var workshop_button: Button
var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_text: RichTextLabel
var dialogue_choices: VBoxContainer
var next_button: Button
var portrait_rect: TextureRect
var hotspots_layer: Control
var inspection_panel: PanelContainer
var inspection_text: Label
var inspection_continue: Button
var result_panel: PanelContainer
var result_text: RichTextLabel
var result_button: Button
var credits_panel: PanelContainer
var credits_box: VBoxContainer
var toast: Label
var splash_layer: ColorRect
var settings_layer: ColorRect
var settings_panel: PanelContainer
var volume_slider: HSlider
var volume_value: Label
var music_slider: HSlider
var music_value: Label
var sfx_slider: HSlider
var sfx_value: Label
var text_speed_slider: HSlider
var text_speed_value: Label
var fullscreen_toggle: CheckButton
var pause_layer: ColorRect
var confirm_layer: ColorRect
var confirm_title: Label
var confirm_text: Label
var pause_button: Button

var current_dialogue: Array[Dictionary] = []
var dialogue_index: int = -1
var dialogue_finished_callback: Callable
var inspected: Dictionary = {}
var selected_plan := ""
var grinder_choice := ""
var current_job := "cafe"
var inspection_messages: Dictionary = {}
var inspection_name := ""
var settings_return_target := "title"
var confirm_action: Callable
var dialogue_revealing := false
var reveal_tween: Tween
var portrait_tween: Tween
var background_fade: ColorRect
var background_tween: Tween
var money_tween: Tween
var last_money := -1
var splash_finishing := false
var toast_tween: Tween
var puzzle_panel: Control
var puzzle_resume_button: Button
var puzzle_job := "practice"
var puzzle_bonus := 0
var restoring_journey := false
const SAFE_RESUME_METHODS := ["show_office", "show_contracts", "begin_inspection", "begin_kite_inspection", "begin_cottage_inspection", "begin_greenhouse_inspection", "begin_observatory_inspection", "show_grinder_choices", "show_telescope_choices", "show_vine_choices", "show_fireplace_choices", "show_kite_keepsake_choices", "start_project_puzzle", "show_credits", "choose_plan", "choose_grinder", "choose_kite_plan", "choose_kite_keepsake", "choose_cottage_plan", "choose_fireplace", "choose_greenhouse_plan", "choose_vine", "choose_observatory_plan", "choose_telescope", "buy_cottage"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_interface()
	puzzle_panel = preload("res://scripts/puzzle_panel.gd").new()
	add_child(puzzle_panel)
	move_child(puzzle_panel, get_children().find(settings_layer))
	puzzle_panel.completed.connect(finish_puzzle)
	puzzle_panel.leave_requested.connect(show_office)
	puzzle_panel.checkpoint.connect(save_puzzle_checkpoint)
	gallery = preload("res://scripts/project_gallery.gd").new()
	add_child(gallery)
	move_child(gallery, get_children().find(settings_layer))
	gallery.accepted.connect(accept_project_design)
	gallery.closed.connect(func(): gallery.hide(); show_office())
	configure_responsive_panels()
	GameState.changed.connect(update_top_bar)
	show_splash()


func configure_responsive_panels() -> void:
	for panel in [title_panel, hub_panel, contracts_panel, map_panel, portfolio_panel, skills_panel, upgrades_panel, dialogue_panel, inspection_panel, result_panel, credits_panel, settings_panel]:
		panel.set_meta("preferred_size", panel.size)
		panel.minimum_size_changed.connect(fit_panel.bind(panel), CONNECT_DEFERRED)
		panel.visibility_changed.connect(fit_panel.bind(panel), CONNECT_DEFERRED)
		fit_panel.call_deferred(panel)


func fit_panel(panel: PanelContainer) -> void:
	if not is_instance_valid(panel):
		return
	var available := get_viewport_rect().size
	var preferred: Vector2 = panel.get_meta("preferred_size")
	var desired := preferred.max(panel.get_combined_minimum_size())
	var top := 96.0 if panel != settings_panel and panel != title_panel else 24.0
	var factor := minf(1.0, minf((available.x - 48.0) / desired.x, (available.y - top - 24.0) / desired.y))
	panel.scale = Vector2.ONE * factor
	panel.size = desired
	var visual := desired * factor
	if panel == dialogue_panel:
		panel.position = Vector2((available.x - visual.x) / 2.0, available.y - 28.0 - visual.y)
	elif panel == hub_panel:
		panel.position = Vector2(available.x - 24.0 - visual.x, maxf(top, (available.y - visual.y) / 2.0))
	elif panel == inspection_panel or panel == map_panel:
		panel.position = Vector2(28.0, top)
		if panel == inspection_panel:
			for button in hotspots_layer.get_children():
				avoid_inspection_overlap(button)
	else:
		panel.position = Vector2((available.x - visual.x) / 2.0, maxf(top, (available.y - visual.y) / 2.0))


func build_interface() -> void:
	scene_image = TextureRect.new()
	scene_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(scene_image)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.03, 0.06, 0.07, 0.15)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	background_fade = ColorRect.new()
	background_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_fade.color = Color(0.03, 0.10, 0.12, 0.0)
	background_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_fade)

	build_top_bar()
	build_title_panel()
	build_hub_panel()
	build_contracts_panel()
	build_map_panel()
	build_upgrades_panel()
	build_portfolio_panel()
	build_skills_panel()
	build_hotspots()
	build_inspection_panel()
	build_dialogue_panel()
	build_result_panel()
	build_credits_panel()
	build_settings_panel()
	build_pause_menu()
	build_confirmation()
	build_splash()

	toast = Label.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-300, 88)
	toast.size = Vector2(600, 54)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 20)
	toast.add_theme_color_override("font_color", Color("fff7de"))
	toast.add_theme_stylebox_override("normal", panel_style(Color("19363bd9"), 18, Color("65c6b5")))
	toast.visible = false
	add_child(toast)


func build_top_bar() -> void:
	top_bar = PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 24
	top_bar.offset_top = 18
	top_bar.offset_right = -24
	top_bar.offset_bottom = 78
	top_bar.add_theme_stylebox_override("panel", panel_style(Color("17343ee8"), 18, Color("65c6b5")))
	add_child(top_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	top_bar.add_child(row)

	var company := Label.new()
	company.text = "ПУШИСТЫЕ СТРОИТЕЛИ"
	company.add_theme_font_size_override("font_size", 24)
	company.add_theme_color_override("font_color", Color("ffd166"))
	company.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(company)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 20)
	row.add_child(money_label)

	reputation_label = Label.new()
	reputation_label.add_theme_font_size_override("font_size", 18)
	row.add_child(reputation_label)

	pause_button = make_button("Пауза", false)
	pause_button.custom_minimum_size = Vector2(120, 42)
	pause_button.pressed.connect(open_pause_menu)
	row.add_child(pause_button)


func build_title_panel() -> void:
	title_panel = PanelContainer.new()
	title_panel.set_anchors_preset(Control.PRESET_CENTER)
	title_panel.position = Vector2(-330, -285)
	title_panel.size = Vector2(660, 570)
	title_panel.add_theme_stylebox_override("panel", panel_style(Color("123239f2"), 28, Color("ffd166"), 2))
	add_child(title_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	title_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "УЮТНОЕ СТРОИТЕЛЬНОЕ ПРИКЛЮЧЕНИЕ"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color("65c6b5"))
	box.add_child(eyebrow)

	var title := Label.new()
	title.text = "ПУШИСТЫЕ СТРОИТЕЛИ\nКомпания мечты"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("fff7de"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Четыре друга. Один старый гараж.\nИ первый заказ, который уже идёт немного вкривь."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color("d9eee8"))
	box.add_child(subtitle)

	title_button = make_button("Начать игру", true)
	title_button.pressed.connect(_on_title_button_pressed)
	box.add_child(title_button)

	var new_game := make_button("Новая компания", false)
	new_game.pressed.connect(_on_new_game_pressed)
	box.add_child(new_game)

	var settings := make_button("Настройки", false)
	settings.pressed.connect(open_settings.bind("title"))
	box.add_child(settings)

	var exit := make_button("Выйти из игры", false)
	exit.pressed.connect(request_exit_game)
	box.add_child(exit)
	exit.visible = not OS.has_feature("web")


func build_hub_panel() -> void:
	hub_panel = PanelContainer.new()
	hub_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	# Keep the office menu inside the viewport even when a translated button label
	# raises the container's minimum width.
	hub_panel.offset_left = -500
	hub_panel.offset_top = -267
	hub_panel.offset_right = -24
	hub_panel.offset_bottom = 267
	hub_panel.add_theme_stylebox_override("panel", panel_style(Color("17343eed"), 24, Color("65c6b5")))
	add_child(hub_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	hub_panel.add_child(margin)
	hub_box = VBoxContainer.new()
	hub_box.add_theme_constant_override("separation", 12)
	margin.add_child(hub_box)

	mission_label = Label.new()
	mission_label.text = "ОФИС В ГАРАЖЕ"
	mission_label.add_theme_font_size_override("font_size", 25)
	mission_label.add_theme_color_override("font_color", Color("ffd166"))
	hub_box.add_child(mission_label)

	var hint := Label.new()
	hint.text = "Первый рабочий день. Выберите, чем заняться."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	hub_box.add_child(hint)

	var phone := make_button("☎  Контракты", true)
	phone.pressed.connect(show_contracts)
	hub_box.add_child(phone)

	var board := make_button("▣  Портфолио компании", false)
	board.pressed.connect(show_portfolio)
	hub_box.add_child(board)

	var map := make_button("◇  Карта города", false)
	map.pressed.connect(show_city_map)
	hub_box.add_child(map)

	skills_button = make_button("★  Навыки героев", false)
	skills_button.pressed.connect(show_hero_skills)
	hub_box.add_child(skills_button)

	event_button = make_button("✦  Событие дня", false)
	event_button.pressed.connect(show_daily_event)
	hub_box.add_child(event_button)

	workshop_button = make_button("⚒  Развитие компании", false)
	workshop_button.pressed.connect(show_upgrades)
	hub_box.add_child(workshop_button)
	puzzle_resume_button = make_button("◆  Мастерская комбинаций", true)
	puzzle_resume_button.pressed.connect(open_puzzle_from_office)
	hub_box.add_child(puzzle_resume_button)
	var daily := make_button("Испытание дня", false)
	daily.pressed.connect(func(): open_puzzle("daily_" + Time.get_date_string_from_system(true)))
	hub_box.add_child(daily)


func build_contracts_panel() -> void:
	contracts_panel = PanelContainer.new()
	contracts_panel.set_anchors_preset(Control.PRESET_CENTER)
	contracts_panel.position = Vector2(-380, -300)
	contracts_panel.size = Vector2(760, 600)
	contracts_panel.add_theme_stylebox_override("panel", panel_style(Color("123239f2"), 28, Color("ffd166"), 2))
	add_child(contracts_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	contracts_panel.add_child(margin)
	contracts_box = VBoxContainer.new()
	contracts_box.add_theme_constant_override("separation", 14)
	margin.add_child(contracts_box)


func build_map_panel() -> void:
	map_panel = PanelContainer.new()
	map_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map_panel.position = Vector2(26, 96)
	map_panel.size = Vector2(350, 305)
	map_panel.add_theme_stylebox_override("panel", panel_style(Color("123239ed"), 24, Color("65c6b5"), 2))
	add_child(map_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	map_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "КАРТА ПУШИСТОГРАДА"
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(heading)
	var old_quarter := make_button("Старый квартал  •  3 объекта", true)
	old_quarter.pressed.connect(show_contracts)
	box.add_child(old_quarter)
	garden_button = make_button("Садовый район  •  закрыт", false)
	garden_button.disabled = true
	garden_button.pressed.connect(show_contracts)
	box.add_child(garden_button)
	hill_button = make_button("Верхний город  •  закрыт", false)
	hill_button.disabled = true
	hill_button.pressed.connect(show_contracts)
	box.add_child(hill_button)
	var back := make_button("← В офис", false)
	back.pressed.connect(show_office)
	box.add_child(back)


func build_upgrades_panel() -> void:
	upgrades_panel = PanelContainer.new()
	upgrades_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrades_panel.position = Vector2(-390, -270)
	upgrades_panel.size = Vector2(780, 540)
	upgrades_panel.add_theme_stylebox_override("panel", panel_style(Color("123239f2"), 28, Color("65c6b5"), 2))
	add_child(upgrades_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	upgrades_panel.add_child(margin)
	upgrades_box = VBoxContainer.new()
	upgrades_box.add_theme_constant_override("separation", 10)
	margin.add_child(upgrades_box)


func build_portfolio_panel() -> void:
	portfolio_panel = PanelContainer.new()
	portfolio_panel.set_anchors_preset(Control.PRESET_CENTER)
	portfolio_panel.position = Vector2(-390, -275)
	portfolio_panel.size = Vector2(780, 550)
	portfolio_panel.add_theme_stylebox_override("panel", panel_style(Color("123239f2"), 28, Color("ffd166"), 2))
	add_child(portfolio_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	portfolio_panel.add_child(margin)
	portfolio_box = VBoxContainer.new()
	portfolio_box.add_theme_constant_override("separation", 10)
	margin.add_child(portfolio_box)


func build_skills_panel() -> void:
	skills_panel = PanelContainer.new()
	skills_panel.set_anchors_preset(Control.PRESET_CENTER)
	skills_panel.position = Vector2(-400, -290)
	skills_panel.size = Vector2(800, 580)
	skills_panel.add_theme_stylebox_override("panel", panel_style(Color("123239f2"), 28, Color("ffd166"), 2))
	add_child(skills_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	skills_panel.add_child(margin)
	skills_box = VBoxContainer.new()
	skills_box.add_theme_constant_override("separation", 9)
	margin.add_child(skills_box)


func build_dialogue_panel() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 36
	dialogue_panel.offset_top = -280
	dialogue_panel.offset_right = -36
	dialogue_panel.offset_bottom = -28
	dialogue_panel.add_theme_stylebox_override("panel", panel_style(Color("112f38f5"), 24, Color("65c6b5"), 2))
	add_child(dialogue_panel)

	portrait_rect = TextureRect.new()
	portrait_rect.set_anchor(SIDE_LEFT, 0.0)
	portrait_rect.set_anchor(SIDE_RIGHT, 0.0)
	portrait_rect.set_anchor(SIDE_TOP, 1.0)
	portrait_rect.set_anchor(SIDE_BOTTOM, 1.0)
	portrait_rect.offset_left = 48
	portrait_rect.offset_right = 308
	portrait_rect.offset_top = -326
	portrait_rect.offset_bottom = -30
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_rect.visible = false
	add_child(portrait_rect)
	dialogue_panel.visibility_changed.connect(sync_portrait_visibility)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 290)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialogue_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(speaker_label)

	dialogue_text = RichTextLabel.new()
	dialogue_text.bbcode_enabled = true
	dialogue_text.fit_content = true
	dialogue_text.custom_minimum_size = Vector2(0, 74)
	dialogue_text.add_theme_font_size_override("normal_font_size", 20)
	dialogue_text.add_theme_color_override("default_color", Color("f5f0df"))
	box.add_child(dialogue_text)

	dialogue_choices = VBoxContainer.new()
	dialogue_choices.add_theme_constant_override("separation", 8)
	box.add_child(dialogue_choices)

	next_button = make_button("Дальше →", true)
	next_button.custom_minimum_size = Vector2(180, 46)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	next_button.pressed.connect(advance_dialogue)
	box.add_child(next_button)


func build_hotspots() -> void:
	hotspots_layer = Control.new()
	hotspots_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hotspots_layer)


func clear_hotspots() -> void:
	for child in hotspots_layer.get_children():
		child.free()


func create_hotspot(key: String, label_text: String, anchor: Vector2) -> void:
	var button := Button.new()
	button.name = key
	button.text = "◎  " + label_text
	button.set_anchor(SIDE_LEFT, anchor.x)
	button.set_anchor(SIDE_RIGHT, anchor.x)
	button.set_anchor(SIDE_TOP, anchor.y)
	button.set_anchor(SIDE_BOTTOM, anchor.y)
	button.offset_left = -78
	button.offset_right = 78
	button.offset_top = -24
	button.offset_bottom = 24
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("fff7de"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("d9eee8"))
	button.add_theme_stylebox_override("normal", panel_style(Color("12343df2"), 22, Color("ffd166"), 2))
	button.add_theme_stylebox_override("hover", panel_style(Color("2b6d70f2"), 22, Color("fff2b2"), 3))
	button.add_theme_stylebox_override("pressed", panel_style(Color("f08a5df2"), 22, Color("fff7de"), 2))
	button.add_theme_stylebox_override("disabled", panel_style(Color("17343ef2"), 22, Color("65c6b5"), 2))
	button.pressed.connect(inspect_hotspot.bind(key, button))
	hotspots_layer.add_child(button)
	avoid_inspection_overlap.call_deferred(button)
	button.modulate = Color(1, 1, 1, 0)
	var appear := create_tween()
	appear.tween_interval(float(hotspots_layer.get_child_count() - 1) * 0.07)
	appear.tween_property(button, "modulate:a", 1.0, 0.22)


func avoid_inspection_overlap(button) -> void:
	if not is_instance_valid(button):
		return
	var panel_rect := inspection_panel.get_global_rect().grow(12.0)
	if panel_rect.intersects(button.get_global_rect()):
		button.position.x = panel_rect.end.x


func build_inspection_panel() -> void:
	inspection_panel = PanelContainer.new()
	inspection_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	inspection_panel.position = Vector2(28, 100)
	inspection_panel.size = Vector2(330, 180)
	inspection_panel.add_theme_stylebox_override("panel", panel_style(Color("17343eed"), 22, Color("ffd166")))
	add_child(inspection_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	inspection_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	inspection_text = Label.new()
	inspection_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection_text.add_theme_font_size_override("font_size", 18)
	box.add_child(inspection_text)
	inspection_continue = make_button("Составить план →", true)
	inspection_continue.disabled = true
	inspection_continue.pressed.connect(show_plan_choices)
	box.add_child(inspection_continue)


func build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(-360, -245)
	result_panel.size = Vector2(720, 490)
	result_panel.add_theme_stylebox_override("panel", panel_style(Color("123239f2"), 28, Color("ffd166"), 2))
	add_child(result_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	result_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "ЗАКАЗ ЗАВЕРШЁН!"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(heading)
	result_text = RichTextLabel.new()
	result_text.bbcode_enabled = true
	result_text.fit_content = true
	result_text.custom_minimum_size = Vector2(0, 290)
	result_text.add_theme_font_size_override("normal_font_size", 20)
	box.add_child(result_text)
	result_button = make_button("Вернуться в офис", true)
	result_button.pressed.connect(continue_after_result)
	box.add_child(result_button)


func build_credits_panel() -> void:
	credits_panel = PanelContainer.new()
	credits_panel.set_anchors_preset(Control.PRESET_CENTER)
	credits_panel.position = Vector2(-420, -310)
	credits_panel.size = Vector2(840, 620)
	credits_panel.add_theme_stylebox_override("panel", panel_style(Color("0d2932f7"), 30, Color("ffd166"), 3))
	add_child(credits_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	credits_panel.add_child(margin)
	credits_box = VBoxContainer.new()
	credits_box.alignment = BoxContainer.ALIGNMENT_CENTER
	credits_box.add_theme_constant_override("separation", 14)
	margin.add_child(credits_box)
	credits_panel.visible = false


func build_settings_panel() -> void:
	settings_layer = ColorRect.new()
	settings_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_layer.color = Color("07191ddb")
	settings_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(settings_layer)

	settings_panel = PanelContainer.new()
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-330, -330)
	settings_panel.size = Vector2(660, 660)
	settings_panel.add_theme_stylebox_override("panel", panel_style(Color("123239fa"), 28, Color("65c6b5"), 2))
	settings_layer.add_child(settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	settings_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = "НАСТРОЙКИ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(heading)

	volume_value = Label.new()
	volume_value.add_theme_font_size_override("font_size", 19)
	box.add_child(volume_value)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 5
	volume_slider.custom_minimum_size = Vector2(0, 42)
	volume_slider.value_changed.connect(_on_volume_changed)
	box.add_child(volume_slider)

	music_value = Label.new()
	music_value.add_theme_font_size_override("font_size", 19)
	box.add_child(music_value)
	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 5
	music_slider.custom_minimum_size = Vector2(0, 34)
	music_slider.value_changed.connect(_on_music_changed)
	box.add_child(music_slider)

	sfx_value = Label.new()
	sfx_value.add_theme_font_size_override("font_size", 19)
	box.add_child(sfx_value)
	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 5
	sfx_slider.custom_minimum_size = Vector2(0, 34)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	box.add_child(sfx_slider)

	text_speed_value = Label.new()
	text_speed_value.add_theme_font_size_override("font_size", 19)
	box.add_child(text_speed_value)
	text_speed_slider = HSlider.new()
	text_speed_slider.min_value = 20
	text_speed_slider.max_value = 100
	text_speed_slider.step = 5
	text_speed_slider.custom_minimum_size = Vector2(0, 42)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	box.add_child(text_speed_slider)

	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "Полноэкранный режим"
	fullscreen_toggle.add_theme_font_size_override("font_size", 19)
	box.add_child(fullscreen_toggle)
	fullscreen_toggle.visible = not OS.has_feature("web")

	var save := make_button("Сохранить и вернуться", true)
	save.pressed.connect(save_and_close_settings)
	box.add_child(save)
	settings_layer.visible = false


func build_pause_menu() -> void:
	pause_layer = ColorRect.new()
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.color = Color("07191de6")
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-250, -235)
	panel.size = Vector2(500, 470)
	panel.add_theme_stylebox_override("panel", panel_style(Color("123239fa"), 28, Color("ffd166"), 2))
	pause_layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "ПАУЗА"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(heading)
	var hint := Label.new()
	hint.text = "Команда решила немного перевести дух."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	box.add_child(hint)
	var resume := make_button("Продолжить", true)
	resume.pressed.connect(resume_game)
	box.add_child(resume)
	var settings := make_button("Настройки", false)
	settings.pressed.connect(open_settings.bind("pause"))
	box.add_child(settings)
	var menu := make_button("В главное меню", false)
	menu.pressed.connect(request_main_menu)
	box.add_child(menu)
	var exit := make_button("Выйти из игры", false)
	exit.pressed.connect(request_exit_game)
	box.add_child(exit)
	exit.visible = not OS.has_feature("web")
	pause_layer.visible = false


func build_confirmation() -> void:
	confirm_layer = ColorRect.new()
	confirm_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_layer.color = Color("07191df0")
	confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(confirm_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-290, -155)
	panel.size = Vector2(580, 310)
	panel.add_theme_stylebox_override("panel", panel_style(Color("123239ff"), 26, Color("f08a5d"), 2))
	confirm_layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)
	confirm_title = Label.new()
	confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_title.add_theme_font_size_override("font_size", 30)
	confirm_title.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(confirm_title)
	confirm_text = Label.new()
	confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_text.add_theme_font_size_override("font_size", 18)
	box.add_child(confirm_text)
	var yes := make_button("Да", true)
	yes.pressed.connect(confirm_selected_action)
	box.add_child(yes)
	var no := make_button("Отмена", false)
	no.pressed.connect(close_confirmation)
	box.add_child(no)
	confirm_layer.visible = false


func build_splash() -> void:
	splash_layer = ColorRect.new()
	splash_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_layer.color = Color("09242aff")
	splash_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	splash_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	splash_layer.gui_input.connect(_on_splash_gui_input)
	add_child(splash_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_layer.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var small := Label.new()
	small.text = "МАЛЕНЬКАЯ КОМАНДА ПРЕДСТАВЛЯЕТ"
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	small.add_theme_font_size_override("font_size", 18)
	small.add_theme_color_override("font_color", Color("65c6b5"))
	box.add_child(small)
	var logo := Label.new()
	logo.text = "ПУШИСТЫЕ СТРОИТЕЛИ"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 66)
	logo.add_theme_color_override("font_color", Color("ffd166"))
	box.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "Компания мечты"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 30)
	box.add_child(subtitle)
	var prompt := Label.new()
	prompt.text = "Нажмите любую кнопку"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 17)
	prompt.add_theme_color_override("font_color", Color("d9eee8"))
	box.add_child(prompt)
	splash_layer.visible = false


func show_splash() -> void:
	get_tree().paused = false
	splash_finishing = false
	scene_image.texture = OFFICE_TEXTURE
	top_bar.visible = false
	title_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	dialogue_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	result_panel.visible = false
	credits_panel.visible = false
	settings_layer.visible = false
	pause_layer.visible = false
	confirm_layer.visible = false
	splash_layer.visible = true
	splash_layer.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(splash_layer, "modulate:a", 1.0, 0.55)
	get_tree().create_timer(2.5).timeout.connect(func():
		if splash_layer.visible:
			finish_splash()
	)


func finish_splash() -> void:
	if not splash_layer.visible or splash_finishing:
		return
	splash_finishing = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(splash_layer, "modulate:a", 0.0, 0.25)
	tween.tween_callback(show_title)


func show_title() -> void:
	if is_instance_valid(puzzle_panel): puzzle_panel.visible = false
	Platform.ready_for_play()
	get_tree().paused = false
	splash_finishing = false
	scene_image.texture = OFFICE_TEXTURE
	top_bar.visible = false
	splash_layer.visible = false
	title_panel.visible = true
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	dialogue_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	result_panel.visible = false
	credits_panel.visible = false
	settings_layer.visible = false
	pause_layer.visible = false
	confirm_layer.visible = false
	if GameState.completed_projects > 0:
		title_button.text = "Продолжить компанию"
	else:
		title_button.text = "Начать игру"


func open_settings(return_target: String) -> void:
	settings_return_target = return_target
	volume_slider.set_value_no_signal(GameState.master_volume)
	music_slider.set_value_no_signal(GameState.music_volume)
	sfx_slider.set_value_no_signal(GameState.sfx_volume)
	text_speed_slider.set_value_no_signal(GameState.text_speed)
	fullscreen_toggle.set_pressed_no_signal(GameState.fullscreen)
	update_settings_labels()
	settings_layer.visible = true
	title_panel.visible = false
	pause_layer.visible = false


func _on_volume_changed(value: float) -> void:
	volume_value.text = "Общая громкость: %d%%" % int(value)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0) if value > 0.0 else -80.0)


func _on_text_speed_changed(value: float) -> void:
	text_speed_value.text = "Скорость текста: %d знаков/сек" % int(value)


func _on_music_changed(value: float) -> void:
	music_value.text = "Музыка: %d%%" % int(value)
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0) if value > 0.0 else -80.0)


func _on_sfx_changed(value: float) -> void:
	sfx_value.text = "Звуковые эффекты: %d%%" % int(value)
	var bus := AudioServer.get_bus_index("SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0) if value > 0.0 else -80.0)


func update_settings_labels() -> void:
	_on_volume_changed(volume_slider.value)
	_on_music_changed(music_slider.value)
	_on_sfx_changed(sfx_slider.value)
	_on_text_speed_changed(text_speed_slider.value)


func save_and_close_settings() -> void:
	GameState.save_settings(volume_slider.value, text_speed_slider.value, fullscreen_toggle.button_pressed, music_slider.value, sfx_slider.value)
	close_settings()


func close_settings() -> void:
	GameState.apply_settings()
	settings_layer.visible = false
	if settings_return_target == "pause":
		pause_layer.visible = true
	else:
		title_panel.visible = true


func open_pause_menu() -> void:
	if title_panel.visible or splash_layer.visible or settings_layer.visible or confirm_layer.visible:
		return
	get_tree().paused = true
	pause_layer.visible = true


func resume_game() -> void:
	pause_layer.visible = false
	confirm_layer.visible = false
	get_tree().paused = false


func request_main_menu() -> void:
	show_confirmation(
		"В главное меню?",
		"Текущий незавершённый заказ будет закрыт. Завершённые проекты уже сохранены.",
		Callable(self, "show_title")
	)


func request_exit_game() -> void:
	show_confirmation(
		"Выйти из игры?",
		"Прогресс будет сохранён, а игра закрыта." if not OS.has_feature("web") else "Прогресс будет сохранён, игра и звук остановятся. После этого можно закрыть вкладку браузера.",
		Callable(self, "exit_game")
	)


func show_confirmation(title_text: String, body_text: String, action: Callable) -> void:
	confirm_title.text = title_text
	confirm_text.text = body_text
	confirm_action = action
	confirm_layer.visible = true


func close_confirmation() -> void:
	confirm_layer.visible = false
	confirm_action = Callable()


func confirm_selected_action() -> void:
	var action := confirm_action
	close_confirmation()
	if action.is_valid():
		action.call()


func exit_game() -> void:
	GameState.save_game()
	if OS.has_feature("web") and Platform.bridge != null:
		Platform.bridge.exit()
		return
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and event.keycode == KEY_F11 and not OS.has_feature("web"):
		GameState.fullscreen = not GameState.fullscreen
		GameState.apply_settings()
		GameState.save_game()
		fullscreen_toggle.set_pressed_no_signal(GameState.fullscreen)
		get_viewport().set_input_as_handled()
		return
	if splash_layer.visible:
		finish_splash()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if confirm_layer.visible:
			close_confirmation()
		elif settings_layer.visible:
			close_settings()
		elif pause_layer.visible:
			resume_game()
		elif not title_panel.visible:
			open_pause_menu()
		get_viewport().set_input_as_handled()


func _on_splash_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		finish_splash()
		splash_layer.accept_event()


func _on_title_button_pressed() -> void:
	if not GameState.journey.is_empty():
		restore_journey()
	elif GameState.tutorial_seen:
		show_office()
	else:
		start_company_intro()


func _on_new_game_pressed() -> void:
	GameState.reset()
	start_company_intro()


func start_company_intro() -> void:
	GameState.mark_tutorial_seen()
	set_scene_background(OFFICE_TEXTURE)
	top_bar.visible = true
	var lines: Array[Dictionary] = [
		{"speaker": "Бруно", "emotion": "determined", "text": "Добро пожаловать в наш новый офис! Пока это старый гараж, но однажды здесь будет лучшая строительная компания Пушистограда."},
		{"speaker": "Лика", "emotion": "happy", "text": "Мы будем слушать клиентов, сохранять историю домов и превращать каждую проблему в красивую идею."},
		{"speaker": "Топа", "emotion": "neutral", "text": "На объектах сначала осматривай отмеченные места. Чем внимательнее осмотр, тем больше вариантов плана откроется."},
		{"speaker": "Искра", "emotion": "happy", "text": "Решения меняют прибыль и репутацию. А опыт открывает наши особые навыки. Телефон уже звонит — пора строить мечту!"}
	]
	start_dialogue(lines, Callable(self, "show_office"))


func show_office() -> void:
	if is_instance_valid(gallery): gallery.hide()
	if not restoring_journey:
		GameState.journey = {}
		GameState.save_game()
	if is_instance_valid(puzzle_panel): puzzle_panel.visible = false
	splash_layer.visible = false
	set_scene_background(OFFICE_TEXTURE)
	top_bar.visible = true
	title_panel.visible = false
	hub_panel.visible = true
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	dialogue_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	result_panel.visible = false
	credits_panel.visible = false
	toast.visible = false
	update_top_bar()
	mission_label.text = "ОФИС РАСТЁТ" if GameState.completed_projects > 0 else "ОФИС В ГАРАЖЕ"
	workshop_button.disabled = GameState.completed_projects < 1
	workshop_button.text = "⚒  Развитие компании" if not workshop_button.disabled else "⚒  Развитие — после первого заказа"
	skills_button.text = "★  Навыки героев  •  %d очк." % GameState.available_skill_points()
	puzzle_resume_button.text = "◆  Продолжить ремонт-пазл" if not GameState.puzzle_session.is_empty() else "◆  Мастерская комбинаций"
	if GameState.current_event != "none":
		event_button.text = "✦  Активно: %s" % event_title(GameState.current_event)
	elif GameState.can_draw_event():
		event_button.text = "✦  Открыть событие дня"
	else:
		event_button.text = "✦  Новое событие — после проекта"
	if OS.has_feature("web"):
		for button in [workshop_button, skills_button, puzzle_resume_button, event_button]:
			for symbol in ["★", "✦", "⚒", "◆"]:
				button.text = button.text.replace(symbol, "").strip_edges()


func show_city_map() -> void:
	set_scene_background(CITY_MAP_TEXTURE)
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = true
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	dialogue_panel.visible = false
	result_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	garden_button.disabled = not GameState.cottage_completed
	garden_button.text = "Садовый район  •  1 объект" if GameState.cottage_completed else "Садовый район  •  закрыт"
	hill_button.disabled = not GameState.greenhouse_completed
	hill_button.text = "Верхний город  •  1 объект" if GameState.greenhouse_completed else "Верхний город  •  закрыт"


func show_contracts() -> void:
	set_scene_background(OFFICE_TEXTURE)
	hub_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	contracts_panel.visible = true
	dialogue_panel.visible = false
	result_panel.visible = false
	for child in contracts_box.get_children():
		child.free()
	var heading := Label.new()
	heading.text = "ДОСКА КОНТРАКТОВ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	contracts_box.add_child(heading)
	var hint := Label.new()
	hint.text = "Выберите историю. Завершённые заказы можно пересмотреть без повторной награды."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	contracts_box.add_child(hint)
	var cafe_status := "Завершено • переиграть" if GameState.cafe_completed else "Новый заказ • награда 900"
	var cafe := make_button("Кафе, которое накренилось\n%s" % cafe_status, true)
	cafe.custom_minimum_size.y = 62
	cafe.pressed.connect(start_first_job)
	contracts_box.add_child(cafe)
	var kite_status := "Завершено • переиграть" if GameState.kite_workshop_completed else "Новый заказ • награда 1100"
	var kite := make_button("Мастерская ветра\n%s" % kite_status, false)
	kite.custom_minimum_size.y = 62
	kite.disabled = not GameState.cafe_completed
	if kite.disabled:
		kite.text = "Мастерская ветра\nЗакрыто: завершите ремонт кафе"
	else:
		kite.pressed.connect(start_kite_job)
	contracts_box.add_child(kite)
	var cottage := make_button("Домик у канала\nПервый объект для флиппинга", false)
	cottage.custom_minimum_size.y = 62
	if not GameState.kite_workshop_completed:
		cottage.text = "Домик у канала\nЗакрыто: завершите мастерскую Руди"
		cottage.disabled = true
	elif GameState.cottage_completed:
		cottage.text = "Домик у канала\nПродан • объект завершён"
		cottage.disabled = true
	elif GameState.cottage_owned:
		cottage.text = "Домик у канала\nКуплен • продолжить ремонт"
		cottage.pressed.connect(start_cottage_flip)
	else:
		cottage.text = "Домик у канала\nКупить за 900 кирпичиков"
		cottage.pressed.connect(show_cottage_offer)
	contracts_box.add_child(cottage)
	var greenhouse_status := "Завершено • переиграть" if GameState.greenhouse_completed else "Новая история • награда 1350"
	var greenhouse := make_button("Теплица над пекарней\n%s" % greenhouse_status, false)
	greenhouse.custom_minimum_size.y = 62
	greenhouse.disabled = not GameState.cottage_completed
	if greenhouse.disabled:
		greenhouse.text = "Теплица над пекарней\nЗакрыто: завершите флиппинг домика"
	else:
		greenhouse.pressed.connect(start_greenhouse_job)
	contracts_box.add_child(greenhouse)
	var observatory_status := "Завершено • переиграть" if GameState.observatory_completed else "Большой заказ • награда 1800"
	var observatory := make_button("Старая обсерватория\n%s" % observatory_status, false)
	observatory.custom_minimum_size.y = 62
	observatory.disabled = not GameState.greenhouse_completed
	if observatory.disabled:
		observatory.text = "Старая обсерватория\nЗакрыто: завершите теплицу"
	else:
		observatory.pressed.connect(start_observatory_job)
	contracts_box.add_child(observatory)
	var back := make_button("← Вернуться в офис", false)
	back.pressed.connect(show_office)
	contracts_box.add_child(back)


func show_upgrades() -> void:
	set_scene_background(OFFICE_TEXTURE)
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = true
	portfolio_panel.visible = false
	skills_panel.visible = false
	dialogue_panel.visible = false
	result_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	toast.visible = false
	for child in upgrades_box.get_children():
		child.free()
	var heading := Label.new()
	heading.text = "РАЗВИТИЕ КОМПАНИИ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	upgrades_box.add_child(heading)
	var level := 1 + int(GameState.experience / 50)
	var xp := Label.new()
	xp.text = "Уровень команды: %d   •   Опыт: %d   •   Кирпичики: %d" % [level, GameState.experience, GameState.money]
	xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp.add_theme_font_size_override("font_size", 18)
	upgrades_box.add_child(xp)
	add_upgrade_button("tools", "Профессиональные инструменты", "Каждый будущий объект получает +1 к качеству.", 300, GameState.tools_level)
	add_upgrade_button("design", "Уголок дизайнера", "Каждый будущий объект получает +1 к креативности.", 350, GameState.design_level)
	add_upgrade_button("client", "Уютная зона для клиентов", "Каждый будущий объект получает +1 к заботе.", 300, GameState.client_level)
	var back := make_button("← Вернуться в офис", false)
	back.pressed.connect(show_office)
	upgrades_box.add_child(back)


func add_upgrade_button(upgrade_id: String, title: String, description: String, cost: int, level: int) -> void:
	var status := "Куплено" if level > 0 else "%d кирпичиков" % cost
	var button := make_button("%s\n%s  •  %s" % [title, description, status], level == 0)
	button.custom_minimum_size.y = 82
	button.disabled = level > 0
	if not button.disabled:
		button.pressed.connect(buy_upgrade.bind(upgrade_id, cost, title))
	upgrades_box.add_child(button)


func buy_upgrade(upgrade_id: String, cost: int, title: String) -> void:
	if GameState.purchase_upgrade(upgrade_id, cost):
		show_toast("Улучшение установлено: %s" % title)
		show_upgrades()
	else:
		show_toast("Не хватает кирпичиков для улучшения.")


func show_hero_skills() -> void:
	set_scene_background(OFFICE_TEXTURE)
	splash_layer.visible = false
	title_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = true
	dialogue_panel.visible = false
	result_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	for child in skills_box.get_children():
		child.free()
	var heading := Label.new()
	heading.text = "НАВЫКИ ГЕРОЕВ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 31)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	skills_box.add_child(heading)
	var points := Label.new()
	points.text = "Свободные очки: %d   •   Новое очко за каждые 50 опыта" % GameState.available_skill_points()
	points.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points.add_theme_font_size_override("font_size", 18)
	skills_box.add_child(points)
	add_hero_skill_button("bruno", "Бруно — Мастер переговоров", "+100 кирпичиков к награде будущих проектов", GameState.bruno_skill)
	add_hero_skill_button("lika", "Лика — Взгляд дизайнера", "Особый план после 3 находок и +1 к креативности", GameState.lika_skill)
	add_hero_skill_button("topa", "Топа — Запас прочности", "+1 к качеству каждого будущего проекта", GameState.topa_skill)
	add_hero_skill_button("iskra", "Искра — Бережная технология", "Реставрационные решения дешевле на 75 кирпичиков", GameState.iskra_skill)
	var back := make_button("← Вернуться в офис", false)
	back.pressed.connect(show_office)
	skills_box.add_child(back)


func add_hero_skill_button(hero_id: String, title: String, description: String, unlocked: bool) -> void:
	var status := "Открыто" if unlocked else "Потратить 1 очко"
	var button := make_button("%s\n%s  •  %s" % [title, description, status], not unlocked)
	button.custom_minimum_size.y = 76
	button.disabled = unlocked or GameState.available_skill_points() <= 0
	if not button.disabled:
		button.pressed.connect(unlock_hero_skill.bind(hero_id, title))
	skills_box.add_child(button)


func unlock_hero_skill(hero_id: String, title: String) -> void:
	if GameState.unlock_hero_skill(hero_id):
		AudioManager.play_reward()
		show_toast("Открыт навык: %s" % title)
		show_hero_skills()
	else:
		show_toast("Сначала заработайте ещё опыта.")


func show_portfolio() -> void:
	set_scene_background(OFFICE_TEXTURE)
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = true
	skills_panel.visible = false
	dialogue_panel.visible = false
	result_panel.visible = false
	credits_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	for child in portfolio_box.get_children():
		child.free()
	var heading := Label.new()
	heading.text = "ПОРТФОЛИО ПУШИСТЫХ СТРОИТЕЛЕЙ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 29)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	portfolio_box.add_child(heading)
	var level := 1 + int(GameState.experience / 50)
	var rank := "Новички с большими планами"
	if GameState.completed_projects >= 5:
		rank = "Легенды Пушистограда"
	elif GameState.completed_projects >= 3:
		rank = "Мастера уютных перемен"
	elif GameState.completed_projects >= 1:
		rank = "Надёжная строительная команда"
	var summary := Label.new()
	summary.text = "%s\nУровень %d  •  Опыт %d  •  Проектов %d\nКачество %d  •  Креатив %d  •  Забота %d" % [rank, level, GameState.experience, GameState.completed_projects, GameState.quality, GameState.creativity, GameState.care]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 18)
	portfolio_box.add_child(summary)
	add_portfolio_line("Кафе, которое накренилось", GameState.cafe_completed)
	add_portfolio_line("Мастерская ветра", GameState.kite_workshop_completed)
	add_portfolio_line("Домик у канала", GameState.cottage_completed)
	add_portfolio_line("Теплица над пекарней", GameState.greenhouse_completed)
	add_portfolio_line("Старая обсерватория", GameState.observatory_completed)
	var achievements := Label.new()
	var badges: Array[String] = []
	if GameState.cottage_completed:
		badges.append("Удачный флип")
	if GameState.quality >= 10:
		badges.append("Знак качества")
	if GameState.creativity >= 10:
		badges.append("Смелый дизайн")
	if GameState.care >= 10:
		badges.append("Сердце города")
	if GameState.observatory_completed:
		badges.append("Звёздный подрядчик")
	achievements.text = "Награды: " + (", ".join(badges) if not badges.is_empty() else "ещё впереди")
	achievements.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievements.add_theme_font_size_override("font_size", 16)
	achievements.add_theme_color_override("font_color", Color("65c6b5"))
	portfolio_box.add_child(achievements)
	if GameState.observatory_completed:
		var finale := make_button("★  Финал и титры", true)
		finale.custom_minimum_size.y = 44
		finale.pressed.connect(start_finale)
		portfolio_box.add_child(finale)
	var back := make_button("← Вернуться в офис", false)
	back.custom_minimum_size.y = 44
	back.pressed.connect(show_office)
	portfolio_box.add_child(back)


func add_portfolio_line(project_name: String, completed: bool) -> void:
	if completed:
		var entry := make_button(project_name + " • до / после", false)
		entry.custom_minimum_size.y = 32
		entry.pressed.connect(show_project_card.bind(PROJECT_TITLES.find(project_name), false))
		portfolio_box.add_child(entry)
		return
	var label := Label.new()
	label.text = ("★  " if completed else "○  ") + project_name + (" — завершено" if completed else " — ещё впереди")
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("ffd166") if completed else Color("a9c1bd"))
	portfolio_box.add_child(label)


func show_cottage_offer() -> void:
	show_choices("Бруно", "Домик у канала стоит 900 кирпичиков. После ремонта его можно продать гораздо дороже. Рискнём?", [
		{"label": "Купить домик за 900", "callback": Callable(self, "buy_cottage")},
		{"label": "Пока не покупать", "callback": Callable(self, "show_contracts")}
	], "determined")


func buy_cottage() -> void:
	if not GameState.purchase_cottage(900):
		var lines: Array[Dictionary] = [{"speaker": "Бруно", "emotion": "worried", "text": "На покупку пока не хватает кирпичиков. Возьмём ещё заказ или выберем более экономные решения."}]
		start_dialogue(lines, Callable(self, "show_contracts"))
		return
	start_cottage_flip()


func update_top_bar() -> void:
	if not is_instance_valid(money_label):
		return
	var money_changed := last_money >= 0 and last_money != GameState.money
	money_label.text = "Кирпичики: %d" % GameState.money
	last_money = GameState.money
	var level := 1 + int(GameState.experience / 50)
	reputation_label.text = "Ур. %d  •  Качество %d  •  Креатив %d  •  Забота %d" % [level, GameState.quality, GameState.creativity, GameState.care]
	if money_changed and money_label.visible:
		money_label.pivot_offset = money_label.size / 2.0
		money_label.scale = Vector2(1.12, 1.12)
		money_label.modulate = Color("ffd166")
		if money_tween and money_tween.is_valid():
			money_tween.kill()
		money_tween = create_tween()
		money_tween.set_parallel(true)
		money_tween.tween_property(money_label, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		money_tween.tween_property(money_label, "modulate", Color.WHITE, 0.32)


func show_company_board() -> void:
	var lines: Array[Dictionary] = [
		{"speaker": "Бруно", "emotion": "neutral", "text": "В нашей копилке [color=#ffd166]%d кирпичиков[/color]. Завершённых проектов: %d." % [GameState.money, GameState.completed_projects]},
		{"speaker": "Лика", "emotion": "happy", "text": "Репутация — качество %d, креативность %d, забота %d. Пока скромно, зато честно!" % [GameState.quality, GameState.creativity, GameState.care]}
	]
	start_dialogue(lines, Callable(self, "show_office"))


func event_title(event_id: String) -> String:
	match event_id:
		"supplier_discount": return "Скидка поставщика"
		"storm_warning": return "Штормовое предупреждение"
		"great_review": return "Восторженный отзыв"
		"antique_find": return "Антикварная находка"
		_: return "Без события"


func event_description(event_id: String) -> String:
	match event_id:
		"supplier_discount": return "Поставщик древесины устроил распродажу. Затраты следующего нового проекта уменьшатся на [color=#ffd166]100 кирпичиков[/color]."
		"storm_warning": return "Синоптики обещают сильный ветер. Следующий проект обойдётся на 80 дороже, зато подготовка команды даст [color=#ffd166]+1 к качеству[/color]."
		"great_review": return "История о работе команды разошлась по городу. Следующий заказ принесёт [color=#ffd166]+50 кирпичиков и +1 к заботе[/color]."
		"antique_find": return "В старом ящике обнаружилась ценная фурнитура. Следующий проект получит [color=#ffd166]+150 кирпичиков и +1 к креативности[/color]."
		_: return "Сегодня в городе спокойно. Новое событие появится после завершения проекта."


func show_daily_event() -> void:
	var event_id := GameState.current_event
	if event_id == "none" and GameState.can_draw_event():
		event_id = GameState.draw_event()
		AudioManager.play_reward()
	var emotion := "happy"
	if event_id == "storm_warning":
		emotion = "worried"
	var lines: Array[Dictionary] = [{
		"speaker": "Бруно",
		"emotion": emotion,
		"text": "[font_size=24][color=#ffd166]%s[/color][/font_size]\n%s\n\nЭффект сработает на следующем новом проекте." % [event_title(event_id), event_description(event_id)]
	}]
	start_dialogue(lines, Callable(self, "show_office"))


func start_first_job() -> void:
	current_job = "cafe"
	hub_panel.visible = false
	contracts_panel.visible = false
	var lines: Array[Dictionary] = [
		{"speaker": "Бруно", "emotion": "determined", "text": "Команда, внимание! Наш [color=#ffd166]первый настоящий звонок[/color]. Постарайтесь выглядеть так, будто мы точно знаем, что делаем."},
		{"speaker": "Госпожа Тортилла", "text": "Здравствуйте! Моё семейное кафе почему-то стало... немного наклонным. Чашки сами уезжают со столов."},
		{"speaker": "Искра", "emotion": "happy", "text": "Самодвижущиеся чашки? Звучит как инновация! Или как очень плохой пол."},
		{"speaker": "Лика", "emotion": "neutral", "text": "Мы всё осмотрим. И постараемся сохранить душу кафе, а не только его стены."},
		{"speaker": "Топа", "emotion": "worried", "text": "Берём инструменты. И уровень. Очень большой уровень."}
	]
	start_dialogue(lines, Callable(self, "begin_inspection"))


func start_dialogue(lines: Array[Dictionary], finished: Callable) -> void:
	if reveal_tween and reveal_tween.is_valid():
		reveal_tween.kill()
	dialogue_revealing = false
	dialogue_panel.offset_top = -280
	current_dialogue = lines
	dialogue_index = -1
	if finished.get_method() in ["finish_job", "finish_kite_job", "finish_cottage_flip", "finish_greenhouse_job", "finish_observatory_job"]:
		dialogue_finished_callback = Callable(self, "start_project_puzzle")
	else:
		dialogue_finished_callback = finished
	title_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	result_panel.visible = false
	credits_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	toast.visible = false
	dialogue_panel.visible = true
	dialogue_panel.modulate = Color(1, 1, 1, 0)
	var dialogue_tween := create_tween()
	dialogue_tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.18)
	clear_choices()
	next_button.visible = true
	advance_dialogue()


func advance_dialogue() -> void:
	if dialogue_revealing:
		if reveal_tween and reveal_tween.is_valid():
			reveal_tween.kill()
		dialogue_text.visible_ratio = 1.0
		dialogue_revealing = false
		return
	dialogue_index += 1
	if dialogue_index >= current_dialogue.size():
		dialogue_panel.visible = false
		var callback := dialogue_finished_callback
		dialogue_finished_callback = Callable()
		if callback.is_valid():
			callback.call()
		return
	var line: Dictionary = current_dialogue[dialogue_index]
	save_journey({"type": "dialogue", "lines": current_dialogue, "index": dialogue_index, "callback": str(dialogue_finished_callback.get_method())})
	speaker_label.text = str(line.get("speaker", ""))
	dialogue_text.text = str(line.get("text", ""))
	update_portrait(speaker_label.text, str(line.get("emotion", "neutral")))
	dialogue_text.visible_ratio = 0.0
	dialogue_revealing = true
	var reveal_duration := maxf(0.12, float(dialogue_text.get_parsed_text().length()) / GameState.text_speed)
	reveal_tween = create_tween()
	reveal_tween.tween_property(dialogue_text, "visible_ratio", 1.0, reveal_duration)
	reveal_tween.tween_callback(func(): dialogue_revealing = false)
	next_button.text = "К делу >" if dialogue_index == current_dialogue.size() - 1 else "Дальше >"


func begin_inspection() -> void:
	current_job = "cafe"
	set_scene_background(CAFE_BEFORE_TEXTURE)
	clear_hotspots()
	create_hotspot("floor", "Пол", Vector2(0.55, 0.80))
	create_hotspot("crack", "Трещина", Vector2(0.25, 0.27))
	create_hotspot("wiring", "Проводка", Vector2(0.77, 0.18))
	create_hotspot("grinder", "Кофемолка", Vector2(0.33, 0.44))
	inspection_name = "ОСМОТР КАФЕ"
	inspection_messages = {
		"floor": "Топа: Пол просел из-за сгнившей опорной балки. Косметикой это не спрячешь.",
		"crack": "Лика: Трещина старая, но растёт. Здесь понадобится усиление стены.",
		"wiring": "Искра: Проводка держится на честном слове. А честное слово не изолятор!",
		"grinder": "Лика: Эта кофемолка принадлежала дедушке хозяйки. Её можно сделать центром интерьера."
	}
	hotspots_layer.visible = true
	inspection_panel.visible = true
	dialogue_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	inspected.clear()
	for child in hotspots_layer.get_children():
		if child is Button:
			child.disabled = false
			child.modulate = Color.WHITE
	update_inspection_panel()


func inspect_hotspot(key: String, button: Button) -> void:
	if inspected.has(key):
		return
	inspected[key] = true
	button.text = button.text.replace("◎", "✓")
	button.disabled = true
	button.modulate = Color.WHITE
	AudioManager.play_inspect()
	show_toast(str(inspection_messages[key]))
	update_inspection_panel()


func update_inspection_panel() -> void:
	save_journey({"type": "inspection", "found": inspected.keys()})
	inspection_text.text = "%s\nНайдено деталей: %d из 4\n\nНайдите хотя бы три важных детали." % [inspection_name, inspected.size()]
	inspection_continue.disabled = inspected.size() < 3


func show_toast(message: String) -> void:
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast.text = message
	toast.visible = true
	toast.modulate = Color.WHITE
	toast_tween = create_tween()
	toast_tween.tween_interval(3.4)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	toast_tween.tween_callback(func(): toast.visible = false)


func show_plan_choices() -> void:
	hotspots_layer.visible = false
	inspection_panel.visible = false
	toast.visible = false
	if current_job == "kite_workshop":
		show_kite_plan_choices()
		return
	if current_job == "canal_cottage":
		show_cottage_plan_choices()
		return
	if current_job == "greenhouse":
		show_greenhouse_plan_choices()
		return
	if current_job == "observatory":
		show_observatory_plan_choices()
		return
	var options: Array[Dictionary] = [
		{"label": "Надёжно усилить основание  •  350 кирпичиков", "callback": Callable(self, "choose_plan").bind("solid")},
		{"label": "Сделать временный ремонт  •  150 кирпичиков", "callback": Callable(self, "choose_plan").bind("quick")}
	]
	if inspected.size() == 4 or (GameState.lika_skill and inspected.size() >= 3):
		options.append({"label": "Использовать все находки и перепланировать работы  •  250", "callback": Callable(self, "choose_plan").bind("smart")})
	show_choices("Бруно", "Мы нашли основные проблемы. Как поступим с просевшим полом?", options, "determined")


func show_choices(speaker: String, text: String, options: Array[Dictionary], emotion := "neutral") -> void:
	var serialized: Array = []
	for option in options:
		var action: Callable = option["callback"]
		serialized.append({"label": option["label"], "method": str(action.get_method()), "args": action.get_bound_arguments()})
	save_journey({"type": "choices", "speaker": speaker, "text": text, "emotion": emotion, "options": serialized})
	# Choice buttons need more vertical room than an ordinary dialogue line.
	# Grow upward so the panel keeps its safe bottom margin at every resolution.
	dialogue_panel.offset_top = -maxf(320.0, 204.0 + float(options.size()) * 58.0)
	dialogue_panel.visible = true
	speaker_label.text = speaker
	dialogue_text.text = text
	update_portrait(speaker, emotion)
	dialogue_text.visible_ratio = 1.0
	dialogue_revealing = false
	next_button.visible = false
	clear_choices()
	for option in options:
		var button := make_button(str(option["label"]), false)
		button.pressed.connect(_on_choice_pressed.bind(option["callback"]))
		dialogue_choices.add_child(button)


func update_portrait(speaker: String, emotion: String) -> void:
	var sheet: Texture2D
	match speaker:
		"Бруно": sheet = BRUNO_PORTRAITS
		"Лика": sheet = LIKA_PORTRAITS
		"Топа": sheet = TOPA_PORTRAITS
		"Искра": sheet = ISKRA_PORTRAITS
		"Руди": sheet = RUDI_PORTRAITS
		"Мира": sheet = MIRA_PORTRAITS
		"Профессор Филин": sheet = FILIN_PORTRAITS
		"Госпожа Тортилла": sheet = TORTILLA_PORTRAITS
		_:
			portrait_rect.texture = null
			portrait_rect.visible = false
			return
	var emotion_index: int = int({
		"neutral": 0,
		"happy": 1,
		"worried": 2,
		"determined": 3
	}.get(emotion, 0))
	var cell_width := float(sheet.get_width()) / 2.0
	var cell_height := float(sheet.get_height()) / 2.0
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		cell_width * float(emotion_index % 2),
		cell_height * float(emotion_index / 2),
		cell_width,
		cell_height
	)
	portrait_rect.texture = atlas
	portrait_rect.visible = dialogue_panel.visible
	portrait_rect.modulate = Color(1, 1, 1, 0)
	if portrait_tween and portrait_tween.is_valid():
		portrait_tween.kill()
	portrait_tween = create_tween()
	portrait_tween.tween_property(portrait_rect, "modulate:a", 1.0, 0.18)


func sync_portrait_visibility() -> void:
	portrait_rect.visible = dialogue_panel.visible and portrait_rect.texture != null


func _on_choice_pressed(callback: Callable) -> void:
	clear_choices()
	dialogue_panel.visible = false
	callback.call()


func clear_choices() -> void:
	if not is_instance_valid(dialogue_choices):
		return
	for child in dialogue_choices.get_children():
		child.queue_free()


func choose_plan(plan: String) -> void:
	selected_plan = plan
	var reaction := ""
	var reacting_hero := "Бруно"
	var reaction_emotion := "neutral"
	match plan:
		"solid":
			reacting_hero = "Топа"
			reaction_emotion = "determined"
			reaction = "Заменим балку и усилим основание. Дольше, зато чашки перестанут путешествовать."
		"quick":
			reacting_hero = "Искра"
			reaction_emotion = "worried"
			reaction = "Подлатаем быстро, но я бы не ставила на этот пол полный чайник."
		"smart":
			reacting_hero = "Лика"
			reaction_emotion = "determined"
			reaction = "Если перенесём тяжёлую стойку, нагрузка уйдёт с повреждённой части. Красиво и разумно!"
	var lines: Array[Dictionary] = [
		{"speaker": reacting_hero, "emotion": reaction_emotion, "text": reaction},
		{"speaker": "Лика", "emotion": "worried", "text": "Остался один вопрос: старая кофемолка занимает много места, но для госпожи Тортиллы она очень важна."}
	]
	start_dialogue(lines, Callable(self, "show_grinder_choices"))


func show_grinder_choices() -> void:
	show_choices("Лика", "Что сделаем со старой семейной кофемолкой?", [
		{"label": "Восстановить и сделать центром интерьера  •  150", "callback": Callable(self, "choose_grinder").bind("restore")},
		{"label": "Продать коллекционеру  •  получить 120", "callback": Callable(self, "choose_grinder").bind("sell")}
	], "worried")


func choose_grinder(choice: String) -> void:
	grinder_choice = choice
	var lines: Array[Dictionary]
	if choice == "restore":
		lines = [
			{"speaker": "Искра", "emotion": "happy", "text": "Я почистила механизм. Теперь она мелет кофе, а не терпение владельца!"},
			{"speaker": "Госпожа Тортилла", "text": "Дедушкина кофемолка снова работает... Спасибо вам."}
		]
	else:
		lines = [
			{"speaker": "Бруно", "emotion": "neutral", "text": "Коллекционер хорошо заплатил. Бюджет спасён."},
			{"speaker": "Госпожа Тортилла", "text": "Жаль, что кофемолки больше нет. Но кафе и правда стало просторнее."}
		]
	start_dialogue(lines, Callable(self, "finish_job"))


func start_observatory_job() -> void:
	current_job = "observatory"
	var lines: Array[Dictionary] = [
		{"speaker": "Профессор Филин", "emotion": "worried", "text": "Обсерватория пережила сто зим, но купол заклинило перед редким метеорным дождём. Без ремонта город не увидит это небо."},
		{"speaker": "Искра", "emotion": "happy", "text": "Огромные шестерни, старый пульт и вращающийся зал! Это либо лучший заказ в жизни, либо самый круглый."},
		{"speaker": "Топа", "emotion": "determined", "text": "Проверим рельс купола и несущие узлы. Такая махина должна двигаться плавно и безопасно."},
		{"speaker": "Бруно", "emotion": "determined", "text": "Пушистые строители добрались до Верхнего города. Сделаем обсерваторию достойной звёзд."}
	]
	start_dialogue(lines, Callable(self, "begin_observatory_inspection"))


func begin_observatory_inspection() -> void:
	current_job = "observatory"
	set_scene_background(OBSERVATORY_BEFORE_TEXTURE)
	clear_hotspots()
	create_hotspot("dome", "Створка купола", Vector2(0.60, 0.16))
	create_hotspot("rotation_track", "Круговой рельс", Vector2(0.57, 0.82))
	create_hotspot("telescope", "Телескоп", Vector2(0.49, 0.42))
	create_hotspot("control", "Пульт управления", Vector2(0.86, 0.54))
	inspection_name = "ОСМОТР ОБСЕРВАТОРИИ"
	inspection_messages = {
		"dome": "Топа: Створка цела, но привод сорван. Купол можно спасти без полной замены.",
		"rotation_track": "Бруно: Рельс забит ржавчиной и мусором. После очистки потребуется точная регулировка.",
		"telescope": "Профессор Филин: Линзы старые, но уникальные. Через них впервые увидели комету над Пушистоградом.",
		"control": "Искра: Проводка древняя, а схема гениальная. Добавим защиту и сохраним механическое управление."
	}
	hotspots_layer.visible = true
	inspection_panel.visible = true
	dialogue_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	result_panel.visible = false
	inspected.clear()
	update_inspection_panel()


func show_observatory_plan_choices() -> void:
	var options: Array[Dictionary] = [
		{"label": "Полностью заменить привод и восстановить рельс  •  650", "callback": Callable(self, "choose_observatory_plan").bind("solid")},
		{"label": "Оставить ручное вращение и починить створку  •  300", "callback": Callable(self, "choose_observatory_plan").bind("quick")}
	]
	if inspected.size() == 4 or (GameState.lika_skill and inspected.size() >= 3):
		options.append({"label": "Соединить старый механизм с новым безопасным приводом  •  480", "callback": Callable(self, "choose_observatory_plan").bind("smart")})
	show_choices("Бруно", "До метеорного дождя одна ночь. Как вернём куполу движение?", options, "determined")


func choose_observatory_plan(plan: String) -> void:
	selected_plan = plan
	var reaction := ""
	var emotion := "determined"
	match plan:
		"solid": reaction = "Ставим новый привод и перебираем рельс. Дорого, зато купол будет двигаться как часы."
		"quick":
			reaction = "Вернём ручной механизм. Для этой ночи хватит, но хранителю снова понадобится помощник."
			emotion = "worried"
		"smart": reaction = "Старые противовесы снимут нагрузку, а новый мотор добавит безопасность. История и техника сработаются."
	var lines: Array[Dictionary] = [
		{"speaker": "Топа", "emotion": emotion, "text": reaction},
		{"speaker": "Искра", "emotion": "worried", "text": "Проверка привода! Купол пошёл... и застрял в трёх пальцах от нужного положения."},
		{"speaker": "Профессор Филин", "emotion": "worried", "text": "Первый метеор уже скоро. Но главный телескоп тоже требует решения — сохранить старые линзы или превратить зал в планетарий?"}
	]
	start_dialogue(lines, Callable(self, "show_telescope_choices"))


func show_telescope_choices() -> void:
	var restore_cost := 145 if GameState.iskra_skill else 220
	show_choices("Профессор Филин", "Каким станет сердце новой обсерватории?", [
		{"label": "Восстановить исторический телескоп и линзы  •  %d" % restore_cost, "callback": Callable(self, "choose_telescope").bind("restore")},
		{"label": "Установить современный проектор-планетарий  •  150", "callback": Callable(self, "choose_telescope").bind("projector")}
	], "neutral")


func choose_telescope(choice: String) -> void:
	grinder_choice = choice
	var lines: Array[Dictionary]
	if choice == "restore":
		lines = [
			{"speaker": "Лика", "emotion": "happy", "text": "Мы очистили каждую линзу и сохранили латунный корпус. Телескоп снова смотрит в небо."},
			{"speaker": "Профессор Филин", "emotion": "happy", "text": "Через него смотрели мои учителя. А сегодня посмотрят дети всего города!"}
		]
	else:
		lines = [
			{"speaker": "Искра", "emotion": "happy", "text": "Проектор покажет туманности даже в дождливый день, а старый телескоп отправится в городской музей."},
			{"speaker": "Профессор Филин", "emotion": "neutral", "text": "Новая обсерватория станет доступнее, хотя живого света старых линз мне будет не хватать."}
		]
	start_dialogue(lines, Callable(self, "finish_observatory_job"))


func finish_observatory_job() -> void:
	var cost := 0
	var quality_gain := 0
	var creativity_gain := 0
	var care_gain := 0
	var verdict := ""
	match selected_plan:
		"solid":
			cost += 650
			quality_gain += 4
			verdict = "Новый привод и восстановленный рельс вернули куполу точное и надёжное движение."
		"quick":
			cost += 300
			quality_gain += 0
			verdict = "Ручной механизм успел открыть купол к метеорному дождю, но работа всё ещё требует сил."
		"smart":
			cost += 480
			quality_gain += 2
			creativity_gain += 2
			verdict = "Старые противовесы и новый привод заработали вместе — купол открылся ровно к первому метеору."
	if grinder_choice == "restore":
		cost += 145 if GameState.iskra_skill else 220
		creativity_gain += 1
		care_gain += 3
		verdict += " Исторический телескоп снова стал окном Пушистограда во Вселенную."
	else:
		cost += 150
		creativity_gain += 3
		care_gain += 1
		verdict += " Новый планетарий сделал звёзды доступными в любую погоду."
	quality_gain += GameState.tools_level
	creativity_gain += GameState.design_level
	care_gain += GameState.client_level
	quality_gain += int(GameState.topa_skill)
	creativity_gain += int(GameState.lika_skill)
	var revenue := 1800 + (100 if GameState.bruno_skill else 0)
	var event_result := resolve_project_event(cost, revenue, quality_gain, creativity_gain, care_gain)
	var net_income: int = event_result["net_income"]
	quality_gain = event_result["quality"]
	creativity_gain = event_result["creativity"]
	care_gain = event_result["care"]
	verdict += event_result["note"]
	var rewarded := GameState.complete_project("observatory", net_income, quality_gain, creativity_gain, care_gain, 110)
	if rewarded:
		GameState.consume_event()
	show_result(net_income, quality_gain, creativity_gain, care_gain, verdict, OBSERVATORY_AFTER_TEXTURE, 110, rewarded)


func start_greenhouse_job() -> void:
	current_job = "greenhouse"
	var lines: Array[Dictionary] = [
		{"speaker": "Мира", "emotion": "worried", "text": "Я выращиваю травы для пекарни внизу. Но вчера ветер разбил стёкла, а старая балка наклонилась прямо над редкой лунной лианой."},
		{"speaker": "Лика", "emotion": "happy", "text": "Теплица на крыше! Если спасти лиану и открыть вид на сады, сюда захотят приходить экскурсии."},
		{"speaker": "Топа", "emotion": "determined", "text": "Сначала конструкция. На крыше ветер ошибок не прощает."},
		{"speaker": "Искра", "emotion": "happy", "text": "А бак и полив беру на себя. Сделаем так, чтобы вода текла только туда, где растут цветы."}
	]
	start_dialogue(lines, Callable(self, "begin_greenhouse_inspection"))


func begin_greenhouse_inspection() -> void:
	current_job = "greenhouse"
	set_scene_background(GREENHOUSE_BEFORE_TEXTURE)
	clear_hotspots()
	create_hotspot("glass", "Стеклянная крыша", Vector2(0.58, 0.17))
	create_hotspot("support", "Опорная балка", Vector2(0.70, 0.43))
	create_hotspot("water_tank", "Бак с водой", Vector2(0.87, 0.30))
	create_hotspot("moon_vine", "Лунная лиана", Vector2(0.43, 0.47))
	inspection_name = "ОСМОТР ТЕПЛИЦЫ"
	inspection_messages = {
		"glass": "Топа: Часть рам цела. Если точно снять размеры, не придётся менять всю крышу.",
		"support": "Бруно: Балка согнулась у старого соединения. Её нужно усилить до следующего порыва ветра.",
		"water_tank": "Искра: Бак не пробит — течёт соединение. Новые трубы спасут и воду, и соседей снизу.",
		"moon_vine": "Мира: Этой лиане больше сорока лет. Она цветёт только несколько ночей каждое лето."
	}
	hotspots_layer.visible = true
	inspection_panel.visible = true
	dialogue_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	result_panel.visible = false
	inspected.clear()
	update_inspection_panel()


func show_greenhouse_plan_choices() -> void:
	var options: Array[Dictionary] = [
		{"label": "Полностью укрепить каркас и заменить стёкла  •  500", "callback": Callable(self, "choose_greenhouse_plan").bind("solid")},
		{"label": "Заменить только разбитые панели  •  250", "callback": Callable(self, "choose_greenhouse_plan").bind("quick")}
	]
	if inspected.size() == 4 or (GameState.lika_skill and inspected.size() >= 3):
		options.append({"label": "Сохранить рамы и усилить только слабые узлы  •  380", "callback": Callable(self, "choose_greenhouse_plan").bind("smart")})
	show_choices("Топа", "Ветер усиливается. Как ремонтируем каркас теплицы?", options, "determined")


func choose_greenhouse_plan(plan: String) -> void:
	selected_plan = plan
	var reaction := ""
	var emotion := "determined"
	match plan:
		"solid": reaction = "Меняем слабые секции и ставим дополнительные связи. Теперь каркас выдержит настоящий шторм."
		"quick":
			reaction = "Стёкла закроем быстро, но старая рама всё ещё будет требовать осторожности."
			emotion = "worried"
		"smart": reaction = "Осмотр показал точные слабые места. Усилим их, сохранив лёгкость старой конструкции."
	var lines: Array[Dictionary] = [
		{"speaker": "Топа", "emotion": emotion, "text": reaction},
		{"speaker": "Искра", "emotion": "worried", "text": "Держитесь! Порыв ветра открыл последнюю треснувшую раму. Я перекрываю воду, Топа фиксирует балку!"},
		{"speaker": "Бруно", "emotion": "determined", "text": "Команда справилась. Но лунная лиана оплела старую центральную опору — без отдельной работы её не сохранить."}
	]
	start_dialogue(lines, Callable(self, "show_vine_choices"))


func show_vine_choices() -> void:
	var preserve_cost := 85 if GameState.iskra_skill else 160
	show_choices("Мира", "Что будет с сорокалетней лунной лианой?", [
		{"label": "Бережно перенести на новый усиленный трельяж  •  %d" % preserve_cost, "callback": Callable(self, "choose_vine").bind("preserve")},
		{"label": "Взять черенки и освободить старую опору  •  получить 100", "callback": Callable(self, "choose_vine").bind("cuttings")}
	], "worried")


func choose_vine(choice: String) -> void:
	grinder_choice = choice
	var lines: Array[Dictionary]
	if choice == "preserve":
		lines = [
			{"speaker": "Лика", "emotion": "determined", "text": "Мы перенесли каждую ветвь по отдельности. Ни один цветок не пострадал."},
			{"speaker": "Мира", "emotion": "happy", "text": "Она снова тянется к свету! Теперь теплица сохранит свою живую историю."}
		]
	else:
		lines = [
			{"speaker": "Искра", "emotion": "neutral", "text": "Черенки уже в новых горшках. Молодые растения разойдутся по всему району."},
			{"speaker": "Мира", "emotion": "worried", "text": "Буду ждать, пока они вырастут. Но старой лианы здесь больше не будет."}
		]
	start_dialogue(lines, Callable(self, "finish_greenhouse_job"))


func finish_greenhouse_job() -> void:
	var cost := 0
	var quality_gain := 0
	var creativity_gain := 0
	var care_gain := 0
	var verdict := ""
	match selected_plan:
		"solid":
			cost += 500
			quality_gain += 3
			verdict = "Новый усиленный каркас превратил старую теплицу в безопасный сад над городом."
		"quick":
			cost += 250
			quality_gain -= 1
			verdict = "Теплица снова закрыта от дождя, но старый каркас потребует регулярных проверок."
		"smart":
			cost += 380
			quality_gain += 2
			creativity_gain += 2
			verdict = "Точные усиления сохранили лёгкий характер теплицы и заметно сократили расходы."
	if grinder_choice == "preserve":
		cost += 85 if GameState.iskra_skill else 160
		creativity_gain += 1
		care_gain += 3
		verdict += " Лунная лиана стала центром обновлённого сада."
	else:
		cost -= 100
		creativity_gain += 1
		care_gain -= 2
		verdict += " Черенки лианы разошлись по Садовому району, но старое растение было утрачено."
	quality_gain += GameState.tools_level
	creativity_gain += GameState.design_level
	care_gain += GameState.client_level
	quality_gain += int(GameState.topa_skill)
	creativity_gain += int(GameState.lika_skill)
	var revenue := 1350 + (100 if GameState.bruno_skill else 0)
	var event_result := resolve_project_event(cost, revenue, quality_gain, creativity_gain, care_gain)
	var net_income: int = event_result["net_income"]
	quality_gain = event_result["quality"]
	creativity_gain = event_result["creativity"]
	care_gain = event_result["care"]
	verdict += event_result["note"]
	var rewarded := GameState.complete_project("greenhouse", net_income, quality_gain, creativity_gain, care_gain, 85)
	if rewarded:
		GameState.consume_event()
	show_result(net_income, quality_gain, creativity_gain, care_gain, verdict, GREENHOUSE_AFTER_TEXTURE, 85, rewarded)


func start_cottage_flip() -> void:
	current_job = "canal_cottage"
	var lines: Array[Dictionary] = [
		{"speaker": "Бруно", "emotion": "happy", "text": "Наш первый собственный объект! Теперь мы не просто выполняем заказ — мы сами отвечаем за идею, бюджет и будущую продажу."},
		{"speaker": "Лика", "emotion": "happy", "text": "У домика прекрасный вид на канал и редкое арочное окно. Если сохранить характер, покупатели это почувствуют."},
		{"speaker": "Топа", "emotion": "worried", "text": "Сначала проверим дыру в потолке и пол. Видом на канал провалившуюся доску не починишь."},
		{"speaker": "Искра", "emotion": "determined", "text": "А я уже вижу, как здесь всё засияет. Осматриваем и считаем каждую кирпичику!"}
	]
	start_dialogue(lines, Callable(self, "begin_cottage_inspection"))


func begin_cottage_inspection() -> void:
	current_job = "canal_cottage"
	set_scene_background(COTTAGE_BEFORE_TEXTURE)
	clear_hotspots()
	create_hotspot("cottage_floor", "Пол", Vector2(0.68, 0.79))
	create_hotspot("cottage_roof", "Протечка", Vector2(0.64, 0.16))
	create_hotspot("fireplace", "Камин", Vector2(0.15, 0.59))
	create_hotspot("arched_window", "Арочное окно", Vector2(0.31, 0.34))
	inspection_name = "ОСМОТР ДОМИКА"
	inspection_messages = {
		"cottage_floor": "Топа: Несколько лаг сгнили, но большую часть старых досок можно спасти и отшлифовать.",
		"cottage_roof": "Искра: Протечка локальная. Заменим участок кровли и просушим перекрытие.",
		"fireplace": "Бруно: Камин требует новой кладки, зато станет сильным аргументом при продаже.",
		"arched_window": "Лика: Такое окно нельзя прятать! Вокруг него можно построить весь образ гостиной."
	}
	hotspots_layer.visible = true
	inspection_panel.visible = true
	dialogue_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	result_panel.visible = false
	inspected.clear()
	update_inspection_panel()


func show_cottage_plan_choices() -> void:
	var options: Array[Dictionary] = [
		{"label": "Классическая капитальная реставрация  •  450", "callback": Callable(self, "choose_cottage_plan").bind("solid")},
		{"label": "Бюджетное обновление для быстрой продажи  •  220", "callback": Callable(self, "choose_cottage_plan").bind("quick")}
	]
	if inspected.size() == 4 or (GameState.lika_skill and inspected.size() >= 3):
		options.append({"label": "Сохранить старые детали и сделать современную планировку  •  350", "callback": Callable(self, "choose_cottage_plan").bind("smart")})
	show_choices("Бруно", "Это наш бюджет, поэтому решение повлияет и на цену продажи. Какой план выбираем?", options, "determined")


func choose_cottage_plan(plan: String) -> void:
	selected_plan = plan
	var reaction := ""
	match plan:
		"solid": reaction = "Восстановим дом основательно. Дороже, зато покупатель увидит качество в каждой детали."
		"quick": reaction = "Освежим самое заметное и быстро выставим объект. Главное — не маскировать настоящие проблемы."
		"smart": reaction = "Старый пол, новая кухня и арочное окно будут работать вместе. У домика появится своя история."
	var lines: Array[Dictionary] = [
		{"speaker": "Лика", "emotion": "determined", "text": reaction},
		{"speaker": "Топа", "emotion": "neutral", "text": "Осталось решить судьбу камина. Восстановление недешёвое, но без него комната станет просторнее."}
	]
	start_dialogue(lines, Callable(self, "show_fireplace_choices"))


func show_fireplace_choices() -> void:
	var restore_cost := 105 if GameState.iskra_skill else 180
	show_choices("Топа", "Что делаем со старым кирпичным камином?", [
		{"label": "Восстановить настоящий камин  •  %d" % restore_cost, "callback": Callable(self, "choose_fireplace").bind("restore")},
		{"label": "Разобрать и освободить пространство  •  80", "callback": Callable(self, "choose_fireplace").bind("remove")}
	], "neutral")


func choose_fireplace(choice: String) -> void:
	grinder_choice = choice
	var lines: Array[Dictionary]
	if choice == "restore":
		lines = [
			{"speaker": "Топа", "emotion": "happy", "text": "Переложил топку и проверил тягу. Теперь камин снова греет, а не пугает."},
			{"speaker": "Лика", "emotion": "happy", "text": "Именно рядом с ним будущие хозяева представят свой первый уютный вечер."}
		]
	else:
		lines = [
			{"speaker": "Искра", "emotion": "happy", "text": "Кирпичи сохраним для следующего объекта, а здесь появилось место для большого стола."},
			{"speaker": "Лика", "emotion": "worried", "text": "Практично, хотя домик потерял одну из своих самых тёплых деталей."}
		]
	start_dialogue(lines, Callable(self, "finish_cottage_flip"))


func finish_cottage_flip() -> void:
	var renovation_cost := 0
	var sale_price := 0
	var quality_gain := 0
	var creativity_gain := 0
	var care_gain := 0
	var verdict := ""
	match selected_plan:
		"solid":
			renovation_cost = 450
			sale_price = 2050
			quality_gain = 3
			verdict = "Капитальное восстановление убедило покупателей в надёжности домика."
		"quick":
			renovation_cost = 220
			sale_price = 1700
			quality_gain = 0
			verdict = "Свежий и аккуратный интерьер быстро нашёл покупателя, хотя цена осталась умеренной."
		"smart":
			renovation_cost = 350
			sale_price = 2100
			quality_gain = 2
			creativity_gain = 2
			verdict = "Сочетание старых деталей и новой планировки вызвало настоящий ажиотаж."
	if grinder_choice == "restore":
		renovation_cost += 105 if GameState.iskra_skill else 180
		sale_price += 200
		care_gain += 2
		verdict += " Восстановленный камин стал главным украшением объявления."
	else:
		renovation_cost += 80
		sale_price += 100
		creativity_gain += 1
		care_gain -= 1
		verdict += " Дополнительное пространство понравилось практичным покупателям."
	quality_gain += GameState.tools_level
	creativity_gain += GameState.design_level
	care_gain += GameState.client_level
	quality_gain += int(GameState.topa_skill)
	creativity_gain += int(GameState.lika_skill)
	var revenue := sale_price + (100 if GameState.bruno_skill else 0)
	var event_result := resolve_project_event(renovation_cost, revenue, quality_gain, creativity_gain, care_gain)
	var sale_income: int = event_result["net_income"]
	quality_gain = event_result["quality"]
	creativity_gain = event_result["creativity"]
	care_gain = event_result["care"]
	verdict += event_result["note"]
	var rewarded := GameState.complete_cottage(sale_income, quality_gain, creativity_gain, care_gain, 70)
	if rewarded:
		GameState.consume_event()
	show_result(sale_income, quality_gain, creativity_gain, care_gain, verdict, COTTAGE_AFTER_TEXTURE, 70, rewarded, "После ремонта и продажи")


func start_kite_job() -> void:
	current_job = "kite_workshop"
	contracts_panel.visible = false
	var lines: Array[Dictionary] = [
		{"speaker": "Руди", "emotion": "worried", "text": "Я Руди, мастер воздушных змеев. Через три дня фестиваль, а дождь пробил окно прямо над моей главной птицей!"},
		{"speaker": "Искра", "emotion": "happy", "text": "Гигантский летающий механизм и аварийная крыша? Кажется, этот заказ сам выбрал нас."},
		{"speaker": "Топа", "emotion": "determined", "text": "Сначала проверим перекрытия и лестницу. Красота должна стоять на крепких лапах."},
		{"speaker": "Лика", "emotion": "happy", "text": "А потом устроим мастерскую так, чтобы каждый змей здесь захотел взлететь."}
	]
	start_dialogue(lines, Callable(self, "begin_kite_inspection"))


func begin_kite_inspection() -> void:
	current_job = "kite_workshop"
	set_scene_background(KITE_BEFORE_TEXTURE)
	clear_hotspots()
	create_hotspot("skylight", "Окно", Vector2(0.48, 0.18))
	create_hotspot("stairs", "Лестница", Vector2(0.86, 0.50))
	create_hotspot("beam", "Антресоль", Vector2(0.64, 0.36))
	create_hotspot("cords", "Шнуры", Vector2(0.72, 0.69))
	inspection_name = "ОСМОТР МАСТЕРСКОЙ"
	inspection_messages = {
		"skylight": "Искра: Рама сгнила, но проём отличный. Новое остекление даст много рабочего света.",
		"stairs": "Топа: Ступени шатаются, а перил почти нет. Исправим до первого подъёма материалов.",
		"beam": "Бруно: Антресоль выдержит фестиваль только после усиления опор.",
		"cords": "Лика: Шнуры перепутаны, зато их цвета подскажут систему хранения и оформление."
	}
	hotspots_layer.visible = true
	inspection_panel.visible = true
	dialogue_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	result_panel.visible = false
	inspected.clear()
	update_inspection_panel()


func show_kite_plan_choices() -> void:
	var options: Array[Dictionary] = [
		{"label": "Усилить антресоль и заменить остекление  •  420", "callback": Callable(self, "choose_kite_plan").bind("solid")},
		{"label": "Быстро залатать окно к фестивалю  •  180", "callback": Callable(self, "choose_kite_plan").bind("quick")}
	]
	if inspected.size() == 4 or (GameState.lika_skill and inspected.size() >= 3):
		options.append({"label": "Перестроить зоны по движению света и материалов  •  300", "callback": Callable(self, "choose_kite_plan").bind("smart")})
	show_choices("Бруно", "Фестиваль близко. Как спасём мастерскую Руди?", options, "determined")


func choose_kite_plan(plan: String) -> void:
	selected_plan = plan
	var reaction := ""
	match plan:
		"solid": reaction = "Топа усилит опоры, а Искра заменит всё остекление. Надёжно и светло."
		"quick": reaction = "Успеем раньше срока, но после фестиваля сюда придётся вернуться."
		"smart": reaction = "Разнесём раскрой, сборку и хранение по световым зонам. Ни одного лишнего шага!"
	var lines: Array[Dictionary] = [
		{"speaker": "Лика", "emotion": "determined", "text": reaction},
		{"speaker": "Руди", "emotion": "worried", "text": "Есть ещё огромная птица. Я строил её год, но теперь она занимает половину мастерской."}
	]
	start_dialogue(lines, Callable(self, "show_kite_keepsake_choices"))


func show_kite_keepsake_choices() -> void:
	show_choices("Руди", "Что сделать с большой птицей-змеем?", [
		{"label": "Сохранить и превратить в главный экспонат  •  120", "callback": Callable(self, "choose_kite_keepsake").bind("display")},
		{"label": "Разобрать на украшения для фестиваля  •  бесплатно", "callback": Callable(self, "choose_kite_keepsake").bind("reuse")}
	], "worried")


func choose_kite_keepsake(choice: String) -> void:
	grinder_choice = choice
	var lines: Array[Dictionary]
	if choice == "display":
		lines = [
			{"speaker": "Лика", "emotion": "happy", "text": "Подвесим птицу над центральным столом. Она станет сердцем мастерской."},
			{"speaker": "Руди", "emotion": "happy", "text": "Теперь она встречает каждого ученика. Именно об этом я мечтал!"}
		]
	else:
		lines = [
			{"speaker": "Искра", "emotion": "happy", "text": "Крылья стали вывесками, а хвост — гирляндой. Ничего не пропало!"},
			{"speaker": "Руди", "emotion": "neutral", "text": "Немного жаль птицу, зато её цвета увидит весь фестиваль."}
		]
	start_dialogue(lines, Callable(self, "finish_kite_job"))


func finish_kite_job() -> void:
	var cost := 0
	var quality_gain := 0
	var creativity_gain := 0
	var care_gain := 0
	var verdict := ""
	match selected_plan:
		"solid":
			cost += 420
			quality_gain += 3
			verdict = "Антресоль укреплена, лестница безопасна, а новая крыша готова к любой погоде."
		"quick":
			cost += 180
			quality_gain -= 1
			verdict = "Мастерская открылась вовремя, но временная заплата потребует внимания после фестиваля."
		"smart":
			cost += 300
			quality_gain += 2
			creativity_gain += 2
			verdict = "Свет, хранение и рабочие зоны теперь образуют одну удобную систему."
	if grinder_choice == "display":
		cost += 120
		creativity_gain += 2
		care_gain += 2
		verdict += " Большая птица стала символом обновлённой мастерской."
	else:
		creativity_gain += 1
		care_gain -= 1
		verdict += " Детали старой птицы украсили городской фестиваль."
	quality_gain += GameState.tools_level
	creativity_gain += GameState.design_level
	care_gain += GameState.client_level
	quality_gain += int(GameState.topa_skill)
	creativity_gain += int(GameState.lika_skill)
	var revenue := 1100 + (100 if GameState.bruno_skill else 0)
	var event_result := resolve_project_event(cost, revenue, quality_gain, creativity_gain, care_gain)
	var net_income: int = event_result["net_income"]
	quality_gain = event_result["quality"]
	creativity_gain = event_result["creativity"]
	care_gain = event_result["care"]
	verdict += event_result["note"]
	var rewarded := GameState.complete_project("kite_workshop", net_income, quality_gain, creativity_gain, care_gain, 55)
	if rewarded:
		GameState.consume_event()
	show_result(net_income, quality_gain, creativity_gain, care_gain, verdict, KITE_AFTER_TEXTURE, 55, rewarded)


func finish_job() -> void:
	var cost := 0
	var quality_gain := 0
	var creativity_gain := 0
	var care_gain := 0
	var verdict := ""
	match selected_plan:
		"solid":
			cost += 350
			quality_gain += 2
			verdict = "Основание укреплено надёжно. Кафе готово простоять ещё много лет."
		"quick":
			cost += 150
			quality_gain -= 1
			verdict = "Заказ завершён быстро, но временное решение немного тревожит команду."
		"smart":
			cost += 250
			quality_gain += 2
			creativity_gain += 1
			verdict = "Тщательный осмотр позволил найти красивое и экономное решение."
	if grinder_choice == "restore":
		cost += 150
		creativity_gain += 2
		care_gain += 2
		verdict += " Семейная кофемолка стала сердцем нового интерьера."
	else:
		cost -= 120
		care_gain -= 1
		verdict += " Продажа кофемолки помогла бюджету, но огорчила хозяйку."
	quality_gain += GameState.tools_level
	creativity_gain += GameState.design_level
	care_gain += GameState.client_level
	quality_gain += int(GameState.topa_skill)
	creativity_gain += int(GameState.lika_skill)
	var revenue := 900 + (100 if GameState.bruno_skill else 0)
	var event_result := resolve_project_event(cost, revenue, quality_gain, creativity_gain, care_gain)
	var net_income: int = event_result["net_income"]
	quality_gain = event_result["quality"]
	creativity_gain = event_result["creativity"]
	care_gain = event_result["care"]
	verdict += event_result["note"]
	var rewarded := GameState.complete_project("cafe", net_income, quality_gain, creativity_gain, care_gain, 40)
	if rewarded:
		GameState.consume_event()
	show_result(net_income, quality_gain, creativity_gain, care_gain, verdict, CAFE_AFTER_TEXTURE, 40, rewarded)


func resolve_project_event(cost: int, revenue: int, quality_gain: int, creativity_gain: int, care_gain: int) -> Dictionary:
	var note := ""
	if GameState.puzzle_records.get("rival_choice", "") == "cooperate":
		cost = maxi(0, cost - 40)
		note += " Соседняя бригада поделилась доставкой: экономия 40."
	elif GameState.puzzle_records.get("rival_choice", "") == "challenge":
		quality_gain += 1
		note += " Честное соперничество помогло улучшить качество."
	if current_job == "greenhouse" and GameState.puzzle_records.get("kept_fireplace", false):
		revenue += 100
		note += " Хозяин сохранённого камина порекомендовал вас Мире: +100."
	if puzzle_bonus > 0:
		revenue += puzzle_bonus * 50
		quality_gain += 1 if puzzle_bonus >= 2 else 0
		note = " Звёзд за комбинации: %d, премия %d кирпичиков." % [puzzle_bonus, puzzle_bonus * 50]
		puzzle_bonus = 0
	match GameState.current_event:
		"supplier_discount":
			cost = maxi(0, cost - 100)
			note += " Скидка поставщика уменьшила расходы на материалы."
		"storm_warning":
			cost += 80
			quality_gain += 1
			note += " Подготовка к шторму повысила надёжность, но увеличила расходы."
		"great_review":
			revenue += 50
			care_gain += 1
			note += " Восторженный отзыв привёл щедрого клиента."
		"antique_find":
			revenue += 150
			creativity_gain += 1
			note += " Найденная фурнитура добавила проекту ценности."
	return {
		"net_income": revenue - cost,
		"quality": quality_gain,
		"creativity": creativity_gain,
		"care": care_gain,
		"note": note
	}


func continue_after_result() -> void:
	if GameState.completed_projects >= 5 and not GameState.finale_seen:
		start_finale()
	elif GameState.completed_projects > 0 and not GameState.story_chapters.has(str(GameState.completed_projects)):
		show_story_chapter()
	else:
		show_office()


func show_story_chapter() -> void:
	var chapter := GameState.completed_projects
	GameState.story_chapters[str(chapter)] = true
	GameState.save_game()
	var scenes: Array = [
		[
			{"speaker": "Лика", "emotion": "worried", "text": "Под половицей кафе лежал синий конверт. На нём — звезда и надпись: «Город держится на тех, кто умеет замечать»..."},
			{"speaker": "Топа", "emotion": "neutral", "text": "Это почерк моего учителя. Он строил старую обсерваторию. Но зачем спрятал чертёж в кафе?"},
			{"speaker": "Искра", "emotion": "happy", "text": "На обороте нарисован воздушный змей! Я за расследование. Но сначала — чай: спасать город на пустой желудок нельзя."}
		],
		[
			{"speaker": "Руди", "emotion": "happy", "text": "Такую звезду я видел на каркасе большой птицы. Дед говорил: это знак мастеров, которые когда-то построили наш город."},
			{"speaker": "Бруно", "emotion": "worried", "text": "В конверте второй чертёж — домик у канала. Его хотят разобрать и вывезти кирпичи. Если купим его, придётся рискнуть своими деньгами."},
			{"speaker": "Лика", "emotion": "determined", "text": "Мы открыли компанию не ради одинаковых коробок. У этого домика есть история — дадим ей ещё одну главу."}
		],
		[
			{"speaker": "Топа", "emotion": "worried", "text": "За каминной стенкой оказалась капсула. Учитель оставил записку: «Когда купол перестанет вращаться, ищите решение в живом саду»."},
			{"speaker": "Искра", "emotion": "neutral", "text": "В записях схема полива и противовесов. Кто-то использовал один механизм для воды и для звёзд. Красиво придумано!"},
			{"speaker": "Бруно", "emotion": "happy", "text": "Мира как раз просила осмотреть теплицу над пекарней. Похоже, город сам передаёт нам следующую подсказку."}
		],
		[
			{"speaker": "Мира", "emotion": "happy", "text": "Эти чертежи хранила моя бабушка! Мастера мечтали, чтобы каждый ребёнок мог посмотреть на звёзды. Но привод купола так и не закончили."},
			{"speaker": "Топа", "emotion": "worried", "text": "Я думал, что учитель всё умел. А он оставил нам незавершённую работу... Боюсь, не справлюсь."},
			{"speaker": "Лика", "emotion": "happy", "text": "Ты не один, Топа. У тебя есть мы. Он оставил не задачу для одного гения, а приглашение для целой команды."},
			{"speaker": "Бруно", "emotion": "determined", "text": "Тогда собираем чертежи. Сегодня Пушистоград снова увидит звёзды!"}
		]
	]
	if chapter >= 1 and chapter <= scenes.size():
		var lines: Array[Dictionary] = []
		lines.assign(scenes[chapter - 1])
		lines.append({"speaker": "Искра", "emotion": "happy", "text": "Бригада «Хвост и молоток» прислала вызов: кто построит уютнее? Их молоток на вывеске больше нашего гаража!"})
		if GameState.puzzle_records.has("rival_choice"):
			lines.append({"speaker": "Бруно", "emotion": "happy", "text": "Наши соседи уже помогают с доставкой. Даже соревнование может стать дружбой." if GameState.puzzle_records.rival_choice == "cooperate" else "Продолжим честное соревнование: каждый новый объект должен быть надёжнее предыдущего."})
		start_dialogue(lines, Callable(self, "show_rival_offer"))
	else: show_office()


func start_project_puzzle() -> void:
	open_puzzle(current_job)

func show_rival_offer() -> void:
	if GameState.puzzle_records.has("rival_choice"):
		show_office()
		return
	show_choices("Бруно", "«Хвост и молоток» предлагает соревнование. Как ответим? Решение повлияет на следующие заказы.", [
		{"label": "Дружить: общая доставка, расходы -40", "callback": Callable(self, "choose_rival").bind("cooperate")},
		{"label": "Соревноваться честно: качество +1", "callback": Callable(self, "choose_rival").bind("challenge")}
	], "happy")

func choose_rival(choice: String) -> void:
	GameState.puzzle_records["rival_choice"] = choice
	GameState.save_game()
	show_office()


func save_journey(data: Dictionary) -> void:
	if restoring_journey: return
	data["job"] = current_job
	data["plan"] = selected_plan
	data["choice"] = grinder_choice
	data["background"] = str(scene_image.get_meta("original_path", scene_image.texture.resource_path if scene_image.texture else ""))
	GameState.journey = data
	GameState.save_game()


func restore_journey() -> void:
	var data: Dictionary = GameState.journey.duplicate(true)
	restoring_journey = true
	show_office()
	if background_tween and background_tween.is_valid(): background_tween.kill()
	background_fade.color.a = 0
	hub_panel.visible = false
	current_job = str(data.get("job", "cafe"))
	selected_plan = str(data.get("plan", ""))
	grinder_choice = str(data.get("choice", ""))
	for texture in [OFFICE_TEXTURE, CAFE_BEFORE_TEXTURE, CAFE_AFTER_TEXTURE, KITE_BEFORE_TEXTURE, KITE_AFTER_TEXTURE, COTTAGE_BEFORE_TEXTURE, COTTAGE_AFTER_TEXTURE, GREENHOUSE_BEFORE_TEXTURE, GREENHOUSE_AFTER_TEXTURE, OBSERVATORY_BEFORE_TEXTURE, OBSERVATORY_AFTER_TEXTURE]:
		if texture.resource_path == data.get("background", ""):
			scene_image.set_meta("original_path", texture.resource_path)
			var project: String = texture.resource_path.get_file().trim_suffix("_after.png")
			scene_image.texture = preload("res://scripts/repair_view.gd").decorated_texture(texture, int(GameState.puzzle_records.get("decor_" + project, 0))) if PROJECT_IDS.has(project) else texture
	match data.get("type", ""):
		"dialogue":
			var method := str(data.get("callback", "show_office"))
			if method not in SAFE_RESUME_METHODS and method != "show_rival_offer": method = "show_office"
			var lines: Array[Dictionary] = []
			lines.assign(data.get("lines", []))
			var index := clampi(int(data.get("index", 0)), 0, maxi(0, lines.size() - 1))
			start_dialogue(lines.slice(index), Callable(self, method))
		"choices":
			var options: Array[Dictionary] = []
			for option in data.get("options", []):
				var method := str(option.get("method", ""))
				if method in SAFE_RESUME_METHODS or method == "choose_rival":
					options.append({"label": str(option.get("label", "")), "callback": Callable(self, method).bindv(option.get("args", []))})
			show_choices(str(data.get("speaker", "Бруно")), str(data.get("text", "")), options, str(data.get("emotion", "neutral")))
		"inspection":
			match current_job:
				"cafe": begin_inspection()
				"kite_workshop": begin_kite_inspection()
				"canal_cottage": begin_cottage_inspection()
				"greenhouse": begin_greenhouse_inspection()
				"observatory": begin_observatory_inspection()
			for key in data.get("found", []):
				var node := hotspots_layer.get_node_or_null(NodePath(str(key)))
				if node is Button: inspect_hotspot(str(key), node)
		_: show_office()
	restoring_journey = false


func open_puzzle_from_office() -> void:
	if not GameState.puzzle_session.is_empty():
		current_job = str(GameState.puzzle_session.get("job", "practice"))
		selected_plan = str(GameState.puzzle_session.get("plan", "smart"))
		grinder_choice = str(GameState.puzzle_session.get("choice", "restore"))
		open_puzzle(current_job, GameState.puzzle_session.get("board", {}))
	else: open_puzzle("practice")


func open_puzzle(job: String, saved: Dictionary = {}) -> void:
	GameState.journey = {}
	puzzle_job = job
	for node in [title_panel, hub_panel, contracts_panel, map_panel, portfolio_panel, skills_panel, upgrades_panel, dialogue_panel, result_panel, inspection_panel, hotspots_layer, credits_panel]:
		node.visible = false
	top_bar.visible = true
	var ids := ["cafe", "kite_workshop", "canal_cottage", "greenhouse", "observatory"]
	var titles := ["Кафе • укрепляем основание", "Мастерская • собираем каркас", "Домик • создаём уют", "Теплица • спасаем сад", "Купол • запускаем привод"]
	var level := ids.find(job)
	var title: String = titles[level] if level >= 0 else "Тренировка • рекорд %d" % int(GameState.puzzle_records.get("practice_score", 0))
	var daily_seed := 0
	if job.begins_with("daily_"):
		daily_seed = job.hash()
		title = "Испытание • " + job.trim_prefix("daily_")
	puzzle_panel.begin(maxi(0, level), title, saved, daily_seed)
	var textures := project_textures(maxi(0, level))
	puzzle_panel.repair_view.set("before", textures[0])
	puzzle_panel.repair_view.set("after", textures[1])
	puzzle_panel.repair_view.queue_redraw()


func save_puzzle_checkpoint(board: Dictionary) -> void:
	GameState.puzzle_session = {"job": puzzle_job, "plan": selected_plan, "choice": grinder_choice, "board": board}
	GameState.save_game()


func finish_puzzle(stars: int) -> void:
	if PROJECT_IDS.has(puzzle_job):
		pending_stars = stars
		show_project_card(PROJECT_IDS.find(puzzle_job), true)
		return
	award_puzzle(stars)

func project_textures(index: int) -> Array:
	return [[CAFE_BEFORE_TEXTURE, CAFE_AFTER_TEXTURE], [KITE_BEFORE_TEXTURE, KITE_AFTER_TEXTURE], [COTTAGE_BEFORE_TEXTURE, COTTAGE_AFTER_TEXTURE], [GREENHOUSE_BEFORE_TEXTURE, GREENHOUSE_AFTER_TEXTURE], [OBSERVATORY_BEFORE_TEXTURE, OBSERVATORY_AFTER_TEXTURE]][clampi(index, 0, 4)]

func show_project_card(index: int, choosing: bool) -> void:
	if index < 0: return
	var textures := project_textures(index)
	gallery.show_project(PROJECT_TITLES[index], textures[0], textures[1], int(GameState.puzzle_records.get("decor_" + PROJECT_IDS[index], 0)), str(GameState.puzzle_records.get("company_name", "Пушистые строители")), choosing)

func accept_project_design(style: int, company: String) -> void:
	if not gallery.visible or not puzzle_panel.model.won() or GameState.puzzle_session.is_empty(): return
	GameState.puzzle_records["decor_" + puzzle_job] = style
	GameState.puzzle_records["company_name"] = company if not company.is_empty() else "Пушистые строители"
	if puzzle_job == "canal_cottage": GameState.puzzle_records["kept_fireplace"] = grinder_choice == "restore"
	gallery.hide()
	award_puzzle(pending_stars)

func award_puzzle(stars: int) -> void:
	GameState.puzzle_records[puzzle_job] = maxi(stars, int(GameState.puzzle_records.get(puzzle_job, 0)))
	GameState.puzzle_session = {}
	if puzzle_job == "practice" or puzzle_job.begins_with("daily_"):
		var record_key := puzzle_job + "_score"
		GameState.puzzle_records[record_key] = maxi(puzzle_panel.model.score + puzzle_panel.model.total_score, int(GameState.puzzle_records.get(record_key, 0)))
		GameState.save_game()
		show_office()
		show_toast("Испытание пройдено: %d звезды • %d материалов" % [stars, puzzle_panel.model.score + puzzle_panel.model.total_score])
		return
	puzzle_bonus = stars
	match puzzle_job:
		"cafe": finish_job()
		"kite_workshop": finish_kite_job()
		"canal_cottage": finish_cottage_flip()
		"greenhouse": finish_greenhouse_job()
		"observatory": finish_observatory_job()
	GameState.save_game()


func start_finale() -> void:
	set_scene_background(OBSERVATORY_AFTER_TEXTURE)
	var lines: Array[Dictionary] = [
		{"speaker": "Профессор Филин", "emotion": "happy", "text": "Купол открыт! Посмотрите: весь Пушистоград собрался на холме, чтобы увидеть первый метеор."},
		{"speaker": "Бруно", "emotion": "happy", "text": "Когда мы открывали компанию в старом гараже, у нас были только инструменты, долги и очень смелая вывеска."},
		{"speaker": "Топа", "emotion": "happy", "text": "Теперь за нами стоят крепкие дома, спасённая теплица и мастерские, в которых снова кипит работа."},
		{"speaker": "Лика", "emotion": "happy", "text": "Мы строили не просто стены. Мы помогали героям сохранять воспоминания и начинать новые истории."},
		{"speaker": "Искра", "emotion": "determined", "text": "А значит, это не конец. Это первый настоящий день компании мечты!"},
		{"speaker": "Бруно", "emotion": "happy", "text": "Команда, желание уже загадано. Пушистые строители официально открыты!"}
	]
	start_dialogue(lines, Callable(self, "show_credits"))


func company_ending_title() -> String:
	var best := maxi(GameState.quality, maxi(GameState.creativity, GameState.care))
	var leaders := 0
	leaders += int(GameState.quality == best)
	leaders += int(GameState.creativity == best)
	leaders += int(GameState.care == best)
	if leaders > 1:
		return "КОМПАНИЯ МЕЧТЫ"
	if GameState.quality == best:
		return "САМАЯ НАДЁЖНАЯ КОМАНДА"
	if GameState.creativity == best:
		return "ГЛАВНЫЕ ВЫДУМЩИКИ ГОРОДА"
	return "СЕРДЦЕ ПУШИСТОГРАДА"


func show_credits() -> void:
	GameState.mark_finale_seen()
	set_scene_background(OFFICE_TEXTURE)
	top_bar.visible = false
	title_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	dialogue_panel.visible = false
	portrait_rect.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	result_panel.visible = false
	credits_panel.visible = true
	for child in credits_box.get_children():
		child.free()
	var eyebrow := Label.new()
	eyebrow.text = "ИСТОРИЯ ЗАВЕРШЕНА"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 18)
	eyebrow.add_theme_color_override("font_color", Color("65c6b5"))
	credits_box.add_child(eyebrow)
	var heading := Label.new()
	heading.text = company_ending_title()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	credits_box.add_child(heading)
	var stats := Label.new()
	stats.text = "5 больших историй  •  %d опыта  •  %d кирпичиков\nКачество %d  •  Креатив %d  •  Забота %d" % [GameState.experience, GameState.money, GameState.quality, GameState.creativity, GameState.care]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	credits_box.add_child(stats)
	var thanks := Label.new()
	thanks.text = "Бруно • Лика • Топа • Искра\nи все жители Пушистограда\n\nСпасибо за игру!"
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.add_theme_font_size_override("font_size", 23)
	thanks.add_theme_color_override("font_color", Color("fff7de"))
	credits_box.add_child(thanks)
	var continue_button := make_button("Вернуться в офис", true)
	continue_button.pressed.connect(show_office)
	credits_box.add_child(continue_button)
	var menu_button := make_button("В главное меню", false)
	menu_button.pressed.connect(show_title)
	credits_box.add_child(menu_button)
	AudioManager.play_reward()


func show_result(net_income: int, quality_gain: int, creativity_gain: int, care_gain: int, verdict: String, result_texture: Texture2D, xp_gain: int, rewarded: bool, income_label := "Прибыль") -> void:
	GameState.journey = {}
	GameState.save_game()
	set_scene_background(result_texture)
	dialogue_panel.visible = false
	hotspots_layer.visible = false
	inspection_panel.visible = false
	hub_panel.visible = false
	contracts_panel.visible = false
	map_panel.visible = false
	upgrades_panel.visible = false
	portfolio_panel.visible = false
	skills_panel.visible = false
	credits_panel.visible = false
	result_panel.visible = true
	result_panel.pivot_offset = result_panel.size / 2.0
	result_panel.scale = Vector2(0.92, 0.92)
	result_panel.modulate = Color(1, 1, 1, 0)
	var result_tween := create_tween()
	result_tween.set_parallel(true)
	result_tween.tween_property(result_panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	result_tween.tween_property(result_panel, "modulate:a", 1.0, 0.22)
	if rewarded:
		AudioManager.play_reward()
	if rewarded:
		result_text.text = "[center][font_size=23]%s[/font_size]\n\n[color=#ffd166]%s: +%d кирпичиков[/color]\nОпыт команды: +%d\nКачество: %+d   Креатив: %+d   Забота: %+d\n\nВсего в кассе: %d[/center]" % [verdict, income_label, net_income, xp_gain, quality_gain, creativity_gain, care_gain, GameState.money]
	else:
		result_text.text = "[center][font_size=23]%s[/font_size]\n\n[color=#65c6b5]История пройдена повторно.[/color]\nНаграда за этот объект уже получена.\n\nВсего в кассе: %d[/center]" % [verdict, GameState.money]
	result_button.text = "Финал истории →" if rewarded and GameState.completed_projects >= 5 and not GameState.finale_seen else "Вернуться в офис"
	update_top_bar()


func make_button(label_text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = label_text
	if OS.has_feature("web"):
		for symbol in ["☎", "▣", "◇", "★", "✦", "⚒", "◆"]:
			button.text = button.text.replace(symbol, "")
		button.text = button.text.replace("→", ">").replace("←", "<")
	button.custom_minimum_size = Vector2(0, 50)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_disabled_color", Color("a9c1bd"))
	button.add_theme_stylebox_override("disabled", panel_style(Color("193a42d9"), 14, Color("41656a")))
	if primary:
		button.add_theme_color_override("font_color", Color("17343e"))
		button.add_theme_color_override("font_hover_color", Color("17343e"))
		button.add_theme_stylebox_override("normal", panel_style(Color("ffd166"), 14))
		button.add_theme_stylebox_override("hover", panel_style(Color("ffe39a"), 14, Color("fff7de"), 2))
		button.add_theme_stylebox_override("pressed", panel_style(Color("efb94f"), 14))
	else:
		button.add_theme_stylebox_override("normal", panel_style(Color("28515be6"), 14, Color("65c6b5")))
		button.add_theme_stylebox_override("hover", panel_style(Color("376b70f2"), 14, Color("ffd166"), 2))
		button.add_theme_stylebox_override("pressed", panel_style(Color("1c4149f2"), 14))
	button.pressed.connect(AudioManager.play_click)
	button.mouse_entered.connect(AudioManager.play_hover)
	return button


func set_scene_background(texture: Texture2D) -> void:
	scene_image.set_meta("original_path", texture.resource_path)
	var project := texture.resource_path.get_file().trim_suffix("_after.png")
	if PROJECT_IDS.has(project):
		texture = preload("res://scripts/repair_view.gd").decorated_texture(texture, int(GameState.puzzle_records.get("decor_" + project, 0)))
	if scene_image.texture == texture:
		return
	if background_tween and background_tween.is_valid():
		background_tween.kill()
	AudioManager.play_transition()
	background_fade.color.a = 0.0
	background_tween = create_tween()
	background_tween.tween_property(background_fade, "color:a", 0.48, 0.12)
	background_tween.tween_callback(func(): scene_image.texture = texture)
	background_tween.tween_property(background_fade, "color:a", 0.0, 0.24)


func panel_style(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
