extends Control

signal accepted(style: int, company: String)
signal closed
var after_view: Control
var before_view: Control
var title_label: Label
var company_edit: LineEdit
var accept_button: Button
var export_button: Button
var note: Label
var styles: Array[Button] = []
var chosen := 0
var portraits: Array[TextureRect] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("14243afc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	title_label = make_label("", Vector2(60, 35), 30)
	make_label("ДО РЕМОНТА", Vector2(60, 95), 18)
	make_label("ПОСЛЕ • ВАШ ДИЗАЙН", Vector2(660, 95), 18)
	before_view = preload("res://scripts/repair_view.gd").new()
	before_view.position = Vector2(60, 130)
	before_view.size = Vector2(550, 300)
	add_child(before_view)
	after_view = preload("res://scripts/repair_view.gd").new()
	after_view.position = Vector2(660, 130)
	after_view.size = Vector2(550, 300)
	after_view.set("completion", 1.0)
	add_child(after_view)
	make_label("Бруно • Лика • Топа • Искра — команда, которая строит с душой", Vector2(60, 447), 19)
	company_edit = LineEdit.new()
	company_edit.position = Vector2(60, 485)
	company_edit.size = Vector2(550, 40)
	company_edit.max_length = 32
	company_edit.placeholder_text = "Название вашей компании"
	add_child(company_edit)
	var sheets := [preload("res://assets/characters/bruno_expressions.png"), preload("res://assets/characters/lika_expressions.png"), preload("res://assets/characters/topa_expressions.png"), preload("res://assets/characters/iskra_expressions.png")]
	for i in range(4):
		var portrait := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = sheets[i]
		atlas.region = Rect2(Vector2(sheets[i].get_width() / 2.0, 0), sheets[i].get_size() / 2)
		portrait.texture = atlas
		portrait.position = Vector2(700 + i * 115, 475)
		portrait.size = Vector2(62, 62)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(portrait)
		portrait.size = Vector2(62, 62)
		portraits.append(portrait)
	for i in range(3):
		var b := make_button(["Тёплая классика", "Зелёный дворик", "Лиловая мастерская"][i], Vector2(60 + i * 390, 545), Vector2(370, 44))
		b.pressed.connect(select_style.bind(i))
		styles.append(b)
	accept_button = make_button("Утвердить дизайн и сдать объект", Vector2(60, 610), Vector2(420, 48))
	accept_button.pressed.connect(func(): accepted.emit(chosen, company_edit.text.strip_edges().left(32)))
	export_button = make_button("Сохранить карточку PNG", Vector2(500, 610), Vector2(360, 48))
	export_button.pressed.connect(export_card)
	var back := make_button("Вернуться", Vector2(880, 610), Vector2(330, 48))
	back.pressed.connect(func(): closed.emit())
	note = make_label("", Vector2(60, 673), 15)
	visible = false

func make_label(text: String, pos: Vector2, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.position = pos
	result.add_theme_font_size_override("font_size", font_size)
	add_child(result)
	return result

func make_button(text: String, pos: Vector2, dimensions: Vector2) -> Button:
	var result := Button.new()
	result.text = text
	result.position = pos
	result.size = dimensions
	add_child(result)
	return result

func show_project(title: String, before: Texture2D, after: Texture2D, style: int, company: String, choosing: bool) -> void:
	title_label.text = "ПУШИСТЫЕ СТРОИТЕЛИ • " + title
	before_view.set("before", before)
	after_view.set("before", before)
	after_view.set("after", after)
	company_edit.text = company
	company_edit.editable = choosing
	accept_button.visible = choosing
	export_button.visible = not choosing
	for b in styles: b.disabled = not choosing
	select_style(style)
	note.text = "Выберите оформление: оно сохранится в портфолио." if choosing else "Карточка сохраняется на устройство. Публиковать её необязательно."
	visible = true
	before_view.queue_redraw()

func select_style(index: int) -> void:
	chosen = clampi(index, 0, 2)
	after_view.set("decor", chosen)
	after_view.queue_redraw()
	for i in range(styles.size()): styles[i].modulate = Color("ffd166") if i == chosen else Color.WHITE

func export_card() -> void:
	# Capture only this gallery, independent of the user's window size.
	export_button.disabled = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("14243a")
	background.size = Vector2(1280, 720)
	viewport.add_child(background)
	for source in [title_label, before_view, after_view]:
		var copy: Node = source.duplicate()
		if source == before_view or source == after_view:
			for property in ["before", "after", "completion", "decor"]: copy.set(property, source.get(property))
		viewport.add_child(copy)
	for i in range(portraits.size()):
		var portrait := TextureRect.new()
		portrait.texture = portraits[i].texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		viewport.add_child(portrait)
		portrait.position = Vector2(720 + i * 115, 495)
		portrait.size = Vector2(90, 90)
	for i in range(2):
		var heading := Label.new()
		heading.text = "ДО РЕМОНТА" if i == 0 else "ПОСЛЕ РЕМОНТА"
		heading.position = Vector2(60 + i * 600, 95)
		heading.add_theme_font_size_override("font_size", 18)
		viewport.add_child(heading)
	var caption := Label.new()
	caption.text = company_edit.text + "\n\nБруно • Лика • Топа • Искра\nМой проект в Пушистограде"
	caption.position = Vector2(60, 480)
	caption.add_theme_font_size_override("font_size", 28)
	viewport.add_child(caption)
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(picture.save_png_to_buffer(), "Pushistye-stroiteli.png", "image/png")
		note.text = "Карточка передана браузеру для сохранения."
	else:
		var path := "user://Pushistye-stroiteli-%d.png" % int(Time.get_unix_time_from_system())
		var error := picture.save_png(path)
		note.text = "Сохранено: " + ProjectSettings.globalize_path(path) if error == OK else "Не удалось сохранить карточку."
	viewport.queue_free()
	export_button.disabled = false
