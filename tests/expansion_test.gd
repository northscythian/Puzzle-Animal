extends SceneTree
const Board = preload("res://scripts/match_board.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var board = Board.new()
	board.start(0, 42)
	board.score = 100000
	board.collected = [100, 100, 100, 100, 100]
	for i in range(4):
		var pair: Array = board.find_move()
		board.play(pair[0], pair[1])
	assert(not board.won(), "Four moves must never complete construction")
	assert(board.work == 4 and board.moves == 32)
	for hero in range(4):
		board.start(3, 99)
		board.hero = hero
		assert(board.use_hero(23).is_empty())
		board.charge = 6
		assert(not board.use_hero(23).is_empty())
		assert(board.charge == 0 and board.moves == 36 and board.work == 0)
		assert(board.use_hero(23).is_empty())
		assert(board.matches().is_empty())
		var clone = Board.new()
		assert(clone.restore(board.snapshot()))
		assert(clone.snapshot() == board.snapshot())
	board.start(0, 21)
	board.cells[23] = 10
	board.cells[24] = 11
	var frames: Array = board.play(23, 24)
	assert(frames[0].clear.size() >= 25)
	board.start(0, 21)
	board.cells[23] = 20
	board.cells[24] = 11
	frames = board.play(23, 24)
	assert(frames[0].clear.size() >= 10)
	board.start(4, 21)
	board.cargo = [35]
	board.cells[42] = 0
	board.smash(42)
	assert(board.delivered == 1 and board.cargo.is_empty())
	var state = root.get_node("GameState")
	state.save_path = "user://expansion_test.cfg"
	state.reset()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_office()
	game.open_puzzle("greenhouse")
	game.puzzle_panel.model.work = 10
	game.puzzle_panel.model.score = 2400
	game.puzzle_panel.model.charge = 6
	game.puzzle_panel.refresh()
	await create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview/expansion_puzzle.png")
	game.puzzle_panel.hide()
	game.show_project_card(0, true)
	game.gallery.select_style(2)
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview/expansion_gallery.png")
		await game.gallery.export_card()
		assert(game.gallery.note.text.begins_with("Сохранено:"))
	game.gallery.hide()
	game.choose_rival("cooperate")
	var result: Dictionary = game.resolve_project_event(100, 200, 0, 0, 0)
	assert(result.net_income == 140)
	state.load_game()
	assert(state.puzzle_records.rival_choice == "cooperate")
	game.queue_free()
	await process_frame
	print("EXPANSION PASSED: minimum duration, four heroes, combined bonuses, delivery, gallery export, persistent consequences")
	quit()
