extends Node

var bridge: JavaScriptObject
var blocked := false
var previous_pause := false
var overlay: ColorRect
var gameplay := false
var previous_process_mode := Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"): return
	bridge = JavaScriptBridge.get_interface("furryPlatform")
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.07, 0.09, 0.8)
	overlay.visible = false
	layer.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var text := Label.new()
	text.text = "Пауза • вернитесь в игру для продолжения"
	text.add_theme_font_size_override("font_size", 24)
	center.add_child(text)

func _process(_delta: float) -> void:
	if bridge == null: return
	var should_block := bool(bridge.blocked)
	var scene := get_tree().current_scene
	if scene != null and "title_panel" in scene:
		var active: bool = not scene.title_panel.visible and not scene.splash_layer.visible and not get_tree().paused and not scene.settings_layer.visible and not scene.confirm_layer.visible and not should_block
		if active != gameplay:
			gameplay = active
			bridge.setGameplay(active)
	if should_block != blocked:
		blocked = should_block
		if blocked:
			previous_pause = get_tree().paused
			if scene != null:
				previous_process_mode = scene.process_mode
				scene.process_mode = Node.PROCESS_MODE_PAUSABLE
			get_tree().paused = true
		else:
			if scene != null:
				scene.process_mode = previous_process_mode
			get_tree().paused = previous_pause
		overlay.visible = blocked
		AudioServer.set_bus_mute(0, blocked)

func ready_for_play() -> void:
	if bridge != null: bridge.ready()

func save_text(content: String) -> void:
	if bridge != null: bridge.save(content)

func load_text() -> String:
	return str(bridge.load()) if bridge != null else ""

func rewarded() -> bool:
	if bridge == null or bool(bridge.adPending): return false
	bridge.rewarded()
	while bool(bridge.adPending):
		await get_tree().process_frame
	return bool(bridge.reward)
