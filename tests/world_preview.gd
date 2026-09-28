extends SceneTree


func _initialize() -> void:
	call_deferred("capture_previews")


func capture_previews() -> void:
	var state = root.get_node_or_null("GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		root.add_child(state)
	state.save_path = "user://world_preview_save.cfg"
	state.reset()
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.show_office()
	game.show_city_map()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/city_map_ui.png")
	game.start_kite_job()
	game.dialogue_text.visible_ratio = 1.0
	await process_frame
	root.get_texture().get_image().save_png("res://preview/rudi_dialogue_ui.png")
	game.begin_kite_inspection()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/kite_workshop_ui.png")
	game.show_upgrades()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/company_upgrades_ui.png")
	game.begin_cottage_inspection()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/canal_cottage_ui.png")
	game.start_greenhouse_job()
	game.dialogue_text.visible_ratio = 1.0
	await process_frame
	root.get_texture().get_image().save_png("res://preview/mira_dialogue_ui.png")
	game.begin_greenhouse_inspection()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/greenhouse_ui.png")
	game.start_observatory_job()
	game.dialogue_text.visible_ratio = 1.0
	await process_frame
	root.get_texture().get_image().save_png("res://preview/filin_dialogue_ui.png")
	game.begin_observatory_inspection()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/observatory_ui.png")
	state.cafe_completed = true
	state.kite_workshop_completed = true
	state.cottage_completed = true
	state.greenhouse_completed = true
	state.observatory_completed = true
	state.completed_projects = 5
	state.experience = 360
	state.quality = 13
	state.creativity = 18
	state.care = 15
	game.show_portfolio()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/final_portfolio_ui.png")
	game.open_settings("title")
	await process_frame
	root.get_texture().get_image().save_png("res://preview/audio_settings_ui.png")
	game.close_settings()
	state.experience = 150
	state.bruno_skill = true
	state.lika_skill = false
	state.topa_skill = false
	state.iskra_skill = false
	game.show_hero_skills()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/hero_skills_ui.png")
	state.current_event = "storm_warning"
	game.show_daily_event()
	game.dialogue_text.visible_ratio = 1.0
	await process_frame
	root.get_texture().get_image().save_png("res://preview/daily_event_ui.png")
	state.finale_seen = false
	game.show_credits()
	await process_frame
	root.get_texture().get_image().save_png("res://preview/final_credits_ui.png")
	print("WORLD PREVIEWS SAVED")
	quit(0)
