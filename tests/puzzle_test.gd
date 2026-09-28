extends SceneTree

const Board = preload("res://scripts/match_board.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Crafted four/five runs create different specials and activate area/colour effects.
	for count in [4, 5]:
		var special_board = Board.new()
		special_board.start(0, 77)
		for i in range(count): special_board.cells[42 + i] = 0
		special_board.cells[42 + count] = 1
		special_board.resolve([])
		var kind := 20 if count == 5 else 10
		var found := -1
		for i in range(49):
			if int(special_board.cells[i]) >= kind: found = i
		assert(found >= 0)
		special_board.score = 0
		var effects: Array = special_board.smash(found)
		assert(not effects.is_empty())
		assert(effects[0]["clear"].size() >= 4)
		assert(special_board.hammer == 0)
	var wins := 0
	var shortest := 1000
	var longest := 0
	var started := Time.get_ticks_msec()
	for seed_value in range(1, 101):
		var board = Board.new()
		board.start(seed_value % 5, seed_value)
		assert(board.matches().is_empty())
		assert(not board.find_move().is_empty())
		assert(not board.adjacent(6, 7))
		var saved: Dictionary = board.snapshot()
		var copy = Board.new()
		assert(copy.restore(saved))
		var total_swaps := 0
		while board.moves > 0 and not board.won():
			if board.phase_done():
				assert(board.next_phase())
				assert(copy.next_phase())
				continue
			var pair: Array = board.find_move()
			assert(not pair.is_empty())
			var before: int = board.moves
			assert(not board.play(pair[0], pair[1]).is_empty())
			assert(board.moves == before - 1)
			total_swaps += 1
			assert(board.matches().is_empty())
			assert(board.cells.size() == 49)
			assert(not copy.play(pair[0], pair[1]).is_empty())
			assert(copy.snapshot() == board.snapshot())
		if board.won():
			wins += 1
			assert(board.work >= board.required_work)
			shortest = mini(shortest, total_swaps)
			longest = maxi(longest, total_swaps)
	print("BOARD: 100 seeded runs, ", wins, " wins, deterministic saves verified")
	print("BALANCE: winning runs ", shortest, "–", longest, " valid swaps; simulation ", Time.get_ticks_msec() - started, " ms")
	var state = root.get_node("GameState")
	state.save_path = "user://puzzle_test.cfg"
	state.reset()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.begin_inspection()
	for key in ["floor", "crack", "wiring"]:
		game.inspect_hotspot(key, game.hotspots_layer.get_node(key))
	state.load_game()
	game.restore_journey()
	assert(game.inspected.size() == 3)
	assert(game.inspection_panel.visible)
	game.show_plan_choices()
	state.load_game()
	game.restore_journey()
	await process_frame
	assert(game.dialogue_choices.get_child_count() == 2)
	game.dialogue_choices.get_child(1).pressed.emit()
	assert(game.selected_plan == "quick")
	var dialogue_before: String = game.dialogue_text.text
	state.load_game()
	game.restore_journey()
	assert(game.dialogue_text.text == dialogue_before)
	game.show_office()
	game.current_job = "cafe"
	game.selected_plan = "smart"
	game.grinder_choice = "restore"
	game.start_project_puzzle()
	assert(game.puzzle_panel.visible)
	var board = game.puzzle_panel.model
	board.start(0, 42)
	var invalid_found := false
	for i in range(48):
		if not board.adjacent(i, i + 1): continue
		var before: Dictionary = board.snapshot()
		var frames: Array = board.play(i, i + 1)
		if frames.is_empty():
			assert(before == board.snapshot())
			invalid_found = true
			break
		board.restore(before)
	assert(invalid_found)
	while not board.won() and board.moves > 0:
		if board.phase_done():
			board.next_phase()
			continue
		var pair: Array = best_move(board)
		board.play(pair[0], pair[1])
	print("CAFE phase ", board.phase, " ", board.objective_text(), " moves ", board.moves)
	assert(board.won())
	game.save_puzzle_checkpoint(game.puzzle_panel.snapshot())
	var expected: Dictionary = state.puzzle_session.duplicate(true)
	state.puzzle_session = {}
	state.load_game()
	assert(state.puzzle_session == expected)
	game.puzzle_panel.leave()
	game.open_puzzle_from_office()
	assert(game.puzzle_panel.model.score == board.score)
	game.puzzle_panel.finish()
	assert(game.gallery.visible)
	game.accept_project_design(1, "Тестовая компания")
	assert(state.cafe_completed)
	assert(state.money > 1700)
	assert(state.puzzle_session.is_empty())
	var money: int = state.money
	game.puzzle_panel.finish()
	assert(state.money == money)
	game.continue_after_result()
	assert(game.dialogue_panel.visible)
	assert(state.story_chapters.has("1"))
	for job in ["kite_workshop", "canal_cottage", "greenhouse", "observatory"]:
		if job == "canal_cottage": assert(state.purchase_cottage(900))
		game.current_job = job
		game.selected_plan = "smart"
		game.grinder_choice = "display" if job == "kite_workshop" else ("preserve" if job == "greenhouse" else "restore")
		game.start_project_puzzle()
		var puzzle = game.puzzle_panel.model
		puzzle.start(game.PROJECT_IDS.find(job), 42)
		while not puzzle.won() and puzzle.moves > 0:
			if puzzle.phase_done():
				puzzle.next_phase()
				continue
			if puzzle.phase == 2 and puzzle.stage_id == 4 and puzzle.charge >= 6 and not puzzle.cargo.is_empty():
				# Use the same free ability available to players: clear a row under a component.
				puzzle.use_hero(mini(48, int(puzzle.cargo[0]) + 7))
				continue
			var pair: Array = best_move(puzzle)
			puzzle.play(pair[0], pair[1])
		print("PROJECT ", job, " work ", puzzle.work, " score ", puzzle.score, " objective ", puzzle.objective_text(), " remaining ", puzzle.moves)
		assert(puzzle.won())
		game.puzzle_panel.finish()
		game.accept_project_design(2, "Тестовая компания")
		assert(state.is_project_completed(job))
	assert(state.completed_projects == 5)
	game.continue_after_result()
	assert(game.dialogue_finished_callback.get_method() == "show_credits")
	game.open_puzzle("daily_2026-09-22")
	var daily_cells: Array = game.puzzle_panel.model.cells.duplicate()
	game.puzzle_panel.retry()
	assert(daily_cells == game.puzzle_panel.model.cells)
	assert(game.puzzle_panel.model.target == 6000)
	assert(game.puzzle_panel.model.moves == 30)
	game.show_office()
	game.open_puzzle("practice")
	await create_timer(0.5).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://preview/puzzle_ui.png")
	print("PUZZLE INTEGRATION PASSED: repair, reward, resume, replay guard and story")
	game.queue_free()
	root.get_node("AudioManager").queue_free()
	await process_frame
	quit()

func best_move(board) -> Array:
	var best: Array = board.find_move()
	var best_value := -1.0
	var trial = Board.new()
	var saved: Dictionary = board.snapshot()
	for a in range(49):
		for b in [a + 1, a + 7]:
			if not board.adjacent(a, b): continue
			trial.restore(saved)
			if trial.play(a, b).is_empty(): continue
			var value: float = mini(trial.score, trial.target) - mini(board.score, board.target)
			var needed: Array = [3, 4] if board.stage_id == 0 else ([1] if board.stage_id == 1 else ([0, 2] if board.stage_id == 2 else []))
			if board.phased and board.phase < 2: needed = [0, 1] if board.phase == 1 else []
			for material in needed:
				var quota := 45 if board.stage_id == 1 else 24
				if board.phased and board.phase == 1: quota = 30
				value += (mini(trial.collected[material], quota) - mini(board.collected[material], quota)) * 150
			value += (board.weeds.size() - trial.weeds.size()) * 1200
			value += (trial.delivered - board.delivered) * 3000
			for pos in trial.cargo: value += int(pos) / 7 * 80
			for pos in board.cargo: value -= int(pos) / 7 * 80
			if trial.objective_done(): value += 1000
			if value > best_value:
				best_value = value
				best = [a, b]
	return best
