extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://release_audit.cfg"
	state.reset()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	if DisplayServer.get_name() != "headless":
		var audio = root.get_node("AudioManager")
		if audio.music_player == null or not audio.music_player.playing:
			print("BACKGROUND MUSIC IS NOT PLAYING")
			failures += 1
		elif not audio.music_player.stream is AudioStreamMP3 or not audio.music_player.stream.loop:
			print("BACKGROUND MUSIC IS NOT A LOOPING MP3")
			failures += 1
	for action in ["show_title", "show_office", "show_contracts", "show_city_map", "show_upgrades", "show_hero_skills", "show_portfolio", "begin_inspection", "begin_kite_inspection", "begin_cottage_inspection", "begin_greenhouse_inspection", "begin_observatory_inspection", "show_credits"]:
		game.show_office()
		game.call(action)
		await settle()
		check_controls(game, action)
		if game.inspection_panel.visible:
			for button in game.hotspots_layer.get_children():
				if game.inspection_panel.get_global_rect().intersects(button.get_global_rect()):
					print("OVERLAP ", action, " ", button.name)
					failures += 1
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://preview/audit_%s.png" % action)
	game.show_office()
	game.begin_inspection()
	await settle()
	for button in game.hotspots_layer.get_children():
		game.inspect_hotspot(str(button.name), button)
	game.show_plan_choices()
	await settle()
	check_controls(game, "three_choices")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview/audit_three_choices.png")
	game.show_office()
	game.open_pause_menu()
	await settle()
	check_controls(game, "pause")
	game.open_settings("pause")
	await settle()
	check_controls(game, "settings")
	game.close_settings()
	game.resume_game()
	if DisplayServer.get_name() != "headless":
		for dimensions in [Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1600, 900), Vector2i(900, 900)]:
			root.size = dimensions
			game.show_office()
			game.show_contracts()
			await settle()
			check_controls(game, "window_%s" % dimensions)
			print("WINDOW CHECK: ", dimensions, " logical viewport ", root.get_visible_rect())
	state.money = 4321
	state.cafe_completed = true
	state.save_game()
	state.money = 0
	state.cafe_completed = false
	state.load_game()
	if state.money != 4321 or not state.cafe_completed:
		failures += 1
	state.save_game()
	var broken := FileAccess.open(state.save_path, FileAccess.WRITE)
	broken.store_string("[broken")
	broken.close()
	state.money = 0
	state.load_game()
	if state.money != 4321:
		print("BACKUP RECOVERY FAILED")
		failures += 1
	state.save_game()
	print("RELEASE AUDIT: ", failures, " failures")
	root.get_node("AudioManager").queue_free()
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

func settle() -> void:
	for i in range(8):
		await process_frame
	await create_timer(0.4).timeout

func check_controls(node: Node, screen: String) -> void:
	if node is Control and node.is_visible_in_tree() and (node is PanelContainer or node is Button):
		var rect: Rect2 = node.get_global_rect()
		var bounds := root.get_visible_rect().grow(1.0)
		if not bounds.encloses(rect):
			print("OUTSIDE ", screen, " ", node.name, " ", rect, " bounds ", bounds)
			failures += 1
	for child in node.get_children():
		check_controls(child, screen)
