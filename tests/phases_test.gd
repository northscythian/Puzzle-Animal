extends SceneTree
const Board = preload("res://scripts/match_board.gd")
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state = root.get_node("GameState")
	state.save_path = "user://phases_test.cfg"
	state.reset()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_office()
	game.open_puzzle("cafe")
	var panel = game.puzzle_panel
	var board = panel.model
	for phase in range(3):
		assert(board.phase == phase)
		assert(not board.phase_done())
		var initial: Array = board.cells.duplicate()
		var pair: Array = board.find_move()
		board.play(pair[0], pair[1])
		panel.retry()
		assert(board.phase == phase and board.cells == initial)
		board.score = board.target
		board.work = board.required_work
		board.collected = [100, 100, 100, 100, 100]
		board.weeds = []
		board.delivered = 3
		assert(board.phase_done())
		game.save_puzzle_checkpoint(panel.snapshot())
		state.load_game()
		game.open_puzzle_from_office()
		assert(board.phase == phase and board.phase_done())
		panel.finish()
		if phase < 2:
			assert(not state.cafe_completed)
			assert(board.phase == phase + 1 and board.cells != initial)
		else:
			assert(game.gallery.visible)
	game.accept_project_design(2, "Новый интерьер")
	assert(state.cafe_completed)
	var legacy: Dictionary = board.snapshot()
	legacy.erase("phased")
	legacy.erase("phase")
	legacy["version"] = 2
	var old = Board.new()
	assert(old.restore(legacy) and not old.phased and old.won())
	for project in range(5):
		var originals: Array = game.project_textures(project)
		for style in [1, 2]:
			var texture = preload("res://scripts/repair_view.gd").decorated_texture(originals[1], style)
			assert(texture is AtlasTexture and texture.get_width() > 500)
	await create_timer(0.5).timeout
	game.show_project_card(0, false)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview/interiors_1_3.png")
		await game.gallery.export_card()
	game.queue_free()
	await process_frame
	print("PHASES PASSED: transitions, retry, checkpoint at boundary, final reward, legacy save, ten interior variants")
	quit()
