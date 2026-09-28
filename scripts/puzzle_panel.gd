extends Control

signal completed(stars: int)
signal leave_requested
signal checkpoint(data: Dictionary)
const Board = preload("res://scripts/match_board.gd")
const COLORS := [Color("ff873e"), Color("ffd05c"), Color("39cfee"), Color("e964ee"), Color("98dc4b")]
const GLYPHS := ["▰", "✦", "◆", "●", "▥"]
const NAMES := ["Кирпич", "Доска", "Стекло", "Краска", "Плитка"]
var model = Board.new()
var tiles: Array[Button] = []
var heading: Label
var info: Label
var reaction: Label
var progress: ProgressBar
var hammer_button: Button
var finish_button: Button
var reward_button: Button
var retry_button: Button
var selected := -1
var busy := false
var hammer_mode := false
var claimed := false
var reward_used := false
var stage := 0
var challenge_seed := 0
var panel: PanelContainer
var repair_view: Control
var hero_picker: OptionButton
var hero_button: Button
var hero_mode := false
var normal_styles: Array[StyleBoxFlat] = []
var hover_styles: Array[StyleBoxFlat] = []
var selected_style: StyleBoxFlat
var assistant_portrait: TextureRect
var assistant_text: Label
var assistant_tween: Tween
var mobile_layout := false
const HERO_SHEETS := [preload("res://assets/characters/bruno_expressions.png"), preload("res://assets/characters/lika_expressions.png"), preload("res://assets/characters/topa_expressions.png"), preload("res://assets/characters/iskra_expressions.png")]
const HERO_NAMES := ["Бруно", "Лика", "Топа", "Искра"]

func _ready() -> void:
	if OS.has_feature("web"):
		mobile_layout = bool(JavaScriptBridge.eval("matchMedia('(pointer: coarse)').matches || innerWidth < 1000"))
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for color in COLORS:
		var style := StyleBoxFlat.new()
		style.bg_color = color.darkened(0.62)
		style.set_corner_radius_all(12)
		style.set_border_width_all(1)
		style.border_color = color.lightened(0.2)
		normal_styles.append(style)
		var hover: StyleBoxFlat = style.duplicate()
		hover.bg_color = color.darkened(0.2)
		hover_styles.append(hover)
	selected_style = normal_styles[0].duplicate()
	selected_style.border_color = Color.WHITE
	selected_style.set_border_width_all(4)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new()
	shade.color = Color("152345d9")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_top = 90
	add_child(shade)
	panel = PanelContainer.new()
	panel.position = Vector2(170, 95)
	panel.size = Vector2(940, 590)
	if mobile_layout:
		panel.position = Vector2(20, 95)
		panel.size = Vector2(1240, 600)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("202b50f5")
	frame.border_color = Color("ffce68")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(22)
	frame.content_margin_left = 20
	frame.content_margin_right = 20
	frame.content_margin_top = 16
	frame.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", frame)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	if mobile_layout: row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	row.add_child(grid)
	for i in range(49):
		var tile := preload("res://scripts/material_tile.gd").new()
		tile.custom_minimum_size = Vector2(65, 65)
		if mobile_layout: tile.custom_minimum_size = Vector2(76, 76)
		tile.add_theme_font_size_override("font_size", 33)
		tile.pressed.connect(choose.bind(i))
		grid.add_child(tile)
		tiles.append(tile)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 360
	if mobile_layout: box.custom_minimum_size.x = 570
	box.add_theme_constant_override("separation", 5)
	row.add_child(box)
	heading = label(box, "МАСТЕРСКАЯ КОМБИНАЦИЙ", 21)
	var rules := label(box, "3 в ряд — сбор; 4/5 — бонус. Соединяй бонусы!", 14)
	rules.tooltip_text = "Победа: собрать материалы, выполнить задачу и закончить монтаж. Один удачный обмен = один шаг монтажа. Зелёные ветки убираются совпадением или взрывом. Золотые детали нужно опустить до нижнего ряда. Способность заряжается за 6 удачных обменов."
	repair_view = preload("res://scripts/repair_view.gd").new()
	repair_view.custom_minimum_size = Vector2(360, 95)
	if mobile_layout: repair_view.custom_minimum_size = Vector2(570, 55)
	repair_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(repair_view)
	hero_picker = OptionButton.new()
	if mobile_layout: hero_picker.add_theme_font_size_override("font_size", 22)
	for title in ["Бруно: убрать ряд", "Лика: перекрасить ряд", "Топа: расчистить 3×3", "Искра: большой взрыв"]:
		hero_picker.add_item(title)
	hero_picker.item_selected.connect(func(index): model.hero = index; checkpoint.emit(snapshot()); refresh(); phase_intro())
	box.add_child(hero_picker)
	info = label(box, "", 16)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 22
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffbd43")
	fill.set_corner_radius_all(10)
	progress.add_theme_stylebox_override("fill", fill)
	box.add_child(progress)
	reaction = label(box, "", 15)
	reaction.custom_minimum_size.y = 36
	hero_button = button(box, "", func(): hero_mode = not hero_mode; hammer_mode = false; refresh())
	hammer_button = button(box, "Молоток Топы • 1 заряд", toggle_hammer)
	button(box, "Подсказка • бесплатно", hint)
	retry_button = button(box, "Попробовать заново • бесплатно", retry)
	reward_button = button(box, "Реклама → ещё 5 ходов", request_reward)
	reward_button.visible = false
	finish_button = button(box, "Ремонт готов →", finish)
	button(box, "Сохранить и вернуться в офис", leave)
	assistant_portrait = TextureRect.new()
	assistant_portrait.position = Vector2(194, 603)
	assistant_portrait.size = Vector2(78, 78)
	assistant_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	assistant_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	assistant_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(assistant_portrait)
	assistant_text = Label.new()
	assistant_text.position = Vector2(287, 610)
	assistant_text.size = Vector2(385, 70)
	assistant_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	assistant_text.add_theme_font_size_override("font_size", 16)
	add_child(assistant_text)
	if mobile_layout:
		assistant_portrait.hide()
		assistant_text.hide()
		reaction.custom_minimum_size.y = 0
	visible = false

func speak(message: String, emotion: int = 0) -> void:
	var sheet: Texture2D = HERO_SHEETS[model.hero]
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(Vector2(emotion % 2, emotion / 2) * sheet.get_size() / 2, sheet.get_size() / 2)
	assistant_portrait.texture = texture
	assistant_text.text = HERO_NAMES[model.hero] + ": " + message
	if assistant_tween and assistant_tween.is_valid(): assistant_tween.kill()
	assistant_portrait.position.y = 603
	assistant_tween = create_tween()
	assistant_tween.tween_property(assistant_portrait, "position:y", 595.0, 0.15).set_trans(Tween.TRANS_SINE)
	assistant_tween.tween_property(assistant_portrait, "position:y", 603.0, 0.2).set_trans(Tween.TRANS_SINE)

func phase_intro() -> void:
	var introductions := ["Сначала расчистим завалы. Собирай ряды на отмеченных клетках!", "Площадка готова! Соберём кирпич и доски для крепкого каркаса.", "Теперь отделка. Выполним особую просьбу нашего заказчика!"]
	if model.phase == 2 and model.stage_id == 4: introductions[2] = "Убирай фишки ПОД золотыми деталями. Способность героя поможет им спуститься!"
	speak(introductions[model.phase], 3)

func label(box: VBoxContainer, text: String, font_size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", maxi(font_size, 22) if mobile_layout else font_size)
	box.add_child(node)
	return node

func button(box: VBoxContainer, text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text.replace("→", ">")
	node.custom_minimum_size.y = 32
	node.add_theme_font_size_override("font_size", 15)
	if mobile_layout:
		node.custom_minimum_size.y = 42
		node.add_theme_font_size_override("font_size", 22)
	node.pressed.connect(action)
	box.add_child(node)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("28515b")
	style.set_corner_radius_all(10)
	node.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color("376b70")
	node.add_theme_stylebox_override("hover", hover)
	return node

func begin(level: int, title: String, saved: Dictionary = {}, fixed_seed: int = 0) -> void:
	stage = level
	challenge_seed = fixed_seed
	heading.text = title
	claimed = false
	busy = false
	selected = -1
	hammer_mode = false
	hero_mode = false
	reward_used = bool(saved.get("reward_used", false))
	if not model.restore(saved):
		model.start(stage, challenge_seed)
		if challenge_seed != 0:
			model.phase = 2
			model.phased = false
			model.configure_phase()
			model.generate()
			model.required_work = 18
			model.target = 6000
			model.moves = 30
	elif not saved.has("version"):
		model.stage_id = clampi(stage, 0, 4)
		model.required_work = 18 + model.stage_id * 2
		model.weeds = [9, 12, 23, 25, 37, 40] if stage == 3 else []
		model.cargo = [1, 3, 5] if stage == 4 else []
		model.moves = maxi(42, model.moves)
	visible = true
	hero_picker.select(model.hero)
	reaction.text = "Лика: найдём красивую комбинацию!"
	refresh()
	phase_intro()
	checkpoint.emit(snapshot())

func snapshot() -> Dictionary:
	var data: Dictionary = model.snapshot()
	data["reward_used"] = reward_used
	return data

func refresh(display: Array = []) -> void:
	var board: Array = model.cells if display.is_empty() else display
	for i in range(49):
		var value: int = board[i]
		var style: StyleBoxFlat = selected_style if selected == i else normal_styles[value % 10]
		tiles[i].add_theme_stylebox_override("normal", style)
		tiles[i].add_theme_stylebox_override("disabled", style)
		var hover: StyleBoxFlat = hover_styles[value % 10]
		tiles[i].add_theme_stylebox_override("hover", hover)
		tiles[i].add_theme_stylebox_override("pressed", hover)
		tiles[i].set("tile_kind", value)
		tiles[i].set("weed", model.weeds.has(i))
		tiles[i].set("rubble", model.phased and model.phase == 0)
		tiles[i].set("delivery", model.cargo.has(i))
		tiles[i].queue_redraw()
		tiles[i].tooltip_text = NAMES[value % 10] + (" • цветовой взрыв" if value >= 20 else (" • взрыв 3×3" if value >= 10 else ""))
		tiles[i].modulate = Color.WHITE
		tiles[i].disabled = busy or model.moves <= 0 or model.phase_done()
	var phases := ["Фундамент", "Стены", "Уют и отделка"]
	var fraction := minf(float(model.work) / model.required_work, float(model.score) / model.target)
	if not model.objective_done(): fraction = minf(fraction, 0.95)
	var phase_name: String = model.PHASE_NAMES[model.phase] if model.phased else phases[mini(2, int(fraction * 3))]
	info.text = "%d/3 %s • ходы %d\nРаботы %d/%d • материалы %d/%d\n%s" % [model.phase + 1, phase_name, model.moves, mini(model.work, model.required_work), model.required_work, mini(model.score, model.target), model.target, model.objective_text()]
	repair_view.set("completion", (model.phase + minf(1, fraction)) / 3.0 if model.phased else fraction)
	repair_view.queue_redraw()
	progress.max_value = 1
	progress.value = fraction
	finish_button.visible = model.phase_done()
	finish_button.text = "Ремонт готов >" if model.won() else "Этап готов! Следующее поле >"
	retry_button.visible = model.moves <= 0 and not model.phase_done()
	hero_picker.disabled = busy or model.work > 0
	hero_button.text = "Выбери фишку для способности" if hero_mode else "Способность героя • %d/6" % model.charge
	hero_button.disabled = busy or model.charge < 6 or model.moves <= 0 or model.phase_done()
	hammer_button.disabled = busy or model.hammer <= 0 or model.moves <= 0 or model.phase_done()
	hammer_button.text = "Выбери фишку для молотка" if hammer_mode else "Молоток Топы • %d заряд" % model.hammer
	reward_button.visible = not finish_button.visible and OS.has_feature("web") and not reward_used and Platform.bridge != null and str(Platform.bridge.status) == "yandex"
	reward_button.disabled = busy
	if finish_button.visible: reaction.text = "Объект готов! Звёзд: %d из 3" % stars() if model.won() else "Этап завершён. Продолжим ремонт!"
	elif retry_button.visible: reaction.text = "Повтори только этот этап бесплатно.\nПредыдущие этапы уже сохранены."

func choose(index: int) -> void:
	if busy or get_tree().paused: return
	if hero_mode:
		hero_mode = false
		speak("Сейчас помогу! Смотри, как работает моя способность!", 3)
		await animate(model.use_hero(index))
		return
	if hammer_mode:
		hammer_mode = false
		await animate(model.smash(index))
		return
	if selected < 0:
		selected = index
		refresh()
		return
	var first := selected
	selected = -1
	if first == index:
		refresh()
		return
	if not model.adjacent(first, index):
		selected = index
		refresh()
		return
	var frames: Array = model.play(first, index)
	if frames.is_empty():
		speak("Не беда! Попробуем другую пару — ход не потрачен.", 2)
		reaction.text = "Лика: нужен ряд из трёх.\nНеудачный обмен не тратит ход."
		refresh()
	else:
		await animate(frames)

func animate(frames: Array) -> void:
	if frames.is_empty(): return
	busy = true
	# Save the resolved move before playing cosmetic effects.
	checkpoint.emit(snapshot())
	for frame in frames:
		refresh(frame["cells"])
		reaction.text = "Искра: БУМ! Цепочка ×%d\n+%d материалов" % [frame["combo"], frame["gain"]]
		AudioManager.play_reward()
		var tween := create_tween().set_parallel(true)
		var particles := 0
		for index in frame["clear"]:
			if particles < 8:
				burst(tiles[index], COLORS[int(frame["cells"][index]) % 10])
				particles += 1
			tween.tween_property(tiles[index], "modulate", Color(2, 2, 2, 0), 0.22)
		await tween.finished
	busy = false
	refresh()
	speak("Этап завершён! Отличная работа команды!" if model.phase_done() else ("Вот это цепочка! Настоящее мастерство!" if frames.size() > 1 else "Отлично, стройка продвигается!"), 1)

func burst(tile: Button, color: Color) -> void:
	for i in range(6):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([Vector2(0, -5), Vector2(3, -1), Vector2(5, 0), Vector2(1, 3), Vector2(0, 5), Vector2(-3, 1), Vector2(-5, 0), Vector2(-1, -3)])
		spark.color = color.lightened(0.35)
		spark.position = tile.global_position - global_position + tile.size / 2
		add_child(spark)
		var effect := create_tween().set_parallel(true)
		effect.tween_property(spark, "position", spark.position + Vector2.from_angle(i * TAU / 6) * 55, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		effect.tween_property(spark, "modulate:a", 0.0, 0.45)
		effect.chain().tween_callback(spark.queue_free)

func toggle_hammer() -> void:
	if busy: return
	hammer_mode = not hammer_mode
	hero_mode = false
	selected = -1
	refresh()

func hint() -> void:
	if busy: return
	hero_mode = false
	hammer_mode = false
	var pair: Array = model.find_move()
	if pair.is_empty(): return
	selected = pair[0]
	refresh()
	tiles[pair[1]].modulate = Color(1.5, 1.5, 1.5)
	reaction.text = "Лика: поменяй местами\nдве подсвеченные фишки."

func retry() -> void:
	if busy: return
	hero_mode = false
	hammer_mode = false
	if model.phased: model.retry_phase()
	else: model.start(stage, challenge_seed)
	if challenge_seed != 0:
		model.phase = 2
		model.phased = false
		model.configure_phase()
		model.generate()
		model.required_work = 18
		model.target = 6000
		model.moves = 30
	selected = -1
	reward_used = false
	checkpoint.emit(snapshot())
	refresh()
	phase_intro()

func stars() -> int:
	return 3 if model.moves >= 10 else (2 if model.moves >= 5 else 1)

func finish() -> void:
	if busy or claimed or not model.phase_done(): return
	if model.next_phase():
		selected = -1
		hero_mode = false
		hammer_mode = false
		reward_used = false
		checkpoint.emit(snapshot())
		refresh()
		phase_intro()
		return
	claimed = true
	visible = false
	completed.emit(stars())

func leave() -> void:
	if busy: return
	checkpoint.emit(snapshot())
	visible = false
	leave_requested.emit()

func request_reward() -> void:
	if busy or reward_used: return
	busy = true
	refresh()
	var granted: bool = await Platform.rewarded()
	busy = false
	if granted:
		reward_used = true
		model.moves += 5
		checkpoint.emit(snapshot())
	else:
		reaction.text = "Реклама недоступна или закрыта.\nМожно бесплатно начать заново."
	refresh()
