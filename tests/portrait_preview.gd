extends SceneTree


func _initialize() -> void:
	call_deferred("capture_preview")


func capture_preview() -> void:
	var state = root.get_node_or_null("GameState")
	if state == null:
		state = load("res://scripts/game_state.gd").new()
		state.name = "GameState"
		root.add_child(state)
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.show_office()
	game.start_first_job()
	await process_frame
	await process_frame
	var screenshot := root.get_texture().get_image()
	screenshot.save_png("res://preview/dialogue_portrait.png")
	print("PORTRAIT PREVIEW SAVED")
	quit(0)

