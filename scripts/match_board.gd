extends RefCounted

const SIZE := 7
const TYPES := 5
var cells: Array = []
var moves := 18
var score := 0
var target := 1100
var best_combo := 0
var hammer := 1
var rng := RandomNumberGenerator.new()
var work := 0
var required_work := 18
var stage_id := 0
var collected: Array = [0, 0, 0, 0, 0]
var weeds: Array = []
var cargo: Array = []
var delivered := 0
var hero := 0
var charge := 0
var phase := 0
var phased := true
var total_score := 0
var phase_seed := ""
const PHASE_NAMES := ["Демонтаж", "Строительство", "Отделка"]

func won() -> bool:
	return (not phased or phase == 2) and phase_done()

func phase_done() -> bool:
	return score >= target and work >= required_work and objective_done()

func next_phase() -> bool:
	if not phased or phase >= 2 or not phase_done(): return false
	total_score += score
	phase += 1
	configure_phase()
	generate()
	return true

func configure_phase() -> void:
	phase_seed = str(rng.state)
	score = 0
	work = 0
	collected = [0, 0, 0, 0, 0]
	delivered = 0
	hammer = 1
	weeds = []
	cargo = []
	if phase == 0:
		moves = 36
		target = 900
		required_work = 6
		weeds = [8, 10, 12, 22, 24, 26]
	elif phase == 1:
		moves = 36
		target = 1600
		required_work = 6
	else:
		moves = 42
		target = 3200 + stage_id * 500
		required_work = 6 + stage_id
		weeds = [9, 12, 23, 25, 37, 40] if stage_id == 3 else []
		cargo = [1, 3, 5] if stage_id == 4 else []

func retry_phase() -> void:
	if not phased:
		start(stage_id)
		return
	rng.state = int(phase_seed)
	configure_phase()
	generate()
	charge = 0

func objective_done() -> bool:
	if phased and phase == 0: return weeds.is_empty()
	if phased and phase == 1: return collected[0] >= 30 and collected[1] >= 30
	match stage_id:
		0: return int(collected[3]) >= 24 and int(collected[4]) >= 24
		1: return int(collected[1]) >= 45
		2: return int(collected[0]) >= 24 and int(collected[2]) >= 24
		3: return weeds.is_empty()
		4: return delivered >= 3
	return true

func objective_text() -> String:
	if phased and phase == 0: return "Разбери завалы: осталось %d" % weeds.size()
	if phased and phase == 1: return "Каркас: кирпич %d/30 • доски %d/30" % [mini(collected[0], 30), mini(collected[1], 30)]
	match stage_id:
		0: return "Краска %d/24 • плитка %d/24" % [mini(collected[3], 24), mini(collected[4], 24)]
		1: return "Доски для каркаса: %d/45" % mini(collected[1], 45)
		2: return "Кирпич %d/24 • стекло %d/24" % [mini(collected[0], 24), mini(collected[2], 24)]
		3: return "Убери сорняки: осталось %d" % weeds.size()
		4: return "Опусти детали вниз: %d/3" % mini(delivered, 3)
	return ""

func start(stage: int, seed_value: int = 0) -> void:
	rng.seed = seed_value if seed_value != 0 else Time.get_ticks_usec()
	moves = 42
	score = 0
	target = 3200 + clampi(stage, 0, 4) * 500
	best_combo = 0
	hammer = 1
	stage_id = clampi(stage, 0, 4)
	work = 0
	required_work = 18 + stage_id * 2
	collected = [0, 0, 0, 0, 0]
	weeds = [9, 12, 23, 25, 37, 40] if stage_id == 3 else []
	cargo = [1, 3, 5] if stage_id == 4 else []
	delivered = 0
	charge = 0
	phase = 0
	phased = true
	total_score = 0
	configure_phase()
	generate()

func generate() -> void:
	for attempt in range(100):
		cells.clear()
		for i in range(SIZE * SIZE):
			var value := rng.randi_range(0, TYPES - 1)
			while (i % SIZE >= 2 and cells[i - 1] == value and cells[i - 2] == value) or (i >= SIZE * 2 and cells[i - SIZE] == value and cells[i - SIZE * 2] == value):
				value = rng.randi_range(0, TYPES - 1)
			cells.append(value)
		if not find_move().is_empty():
			return

func adjacent(a: int, b: int) -> bool:
	return a >= 0 and b >= 0 and a < 49 and b < 49 and absi(a % SIZE - b % SIZE) + absi(a / SIZE - b / SIZE) == 1

func swap_cells(a: int, b: int) -> void:
	var value: int = cells[a]
	cells[a] = cells[b]
	cells[b] = value

func matches() -> Array:
	var groups: Array = []
	for axis in range(2):
		for line in range(SIZE):
			var run: Array = []
			for step in range(SIZE + 1):
				var i := line * SIZE + step if axis == 0 else step * SIZE + line
				if step < SIZE and (run.is_empty() or int(cells[i]) % 10 == int(cells[run[0]]) % 10):
					run.append(i)
				else:
					if run.size() >= 3:
						groups.append(run.duplicate())
					run = [i] if step < SIZE else []
	return groups

func find_move() -> Array:
	for a in range(49):
		for b in [a + 1, a + SIZE]:
			if not adjacent(a, b):
				continue
			if int(cells[a]) >= 10 or int(cells[b]) >= 10:
				return [a, b]
			swap_cells(a, b)
			var valid := not matches().is_empty()
			swap_cells(a, b)
			if valid:
				return [a, b]
	return []

func play(a: int, b: int) -> Array:
	if moves <= 0 or phase_done() or not adjacent(a, b):
		return []
	swap_cells(a, b)
	var forced: Array = []
	if int(cells[a]) >= 10: forced.append(a)
	if int(cells[b]) >= 10: forced.append(b)
	if matches().is_empty() and forced.is_empty():
		swap_cells(a, b)
		return []
	for i in range(cargo.size()):
		if cargo[i] == a: cargo[i] = b
		elif cargo[i] == b: cargo[i] = a
	# Two specials combine deliberately, rather than just firing independently.
	if forced.size() == 2:
		if int(cells[a]) >= 20 or int(cells[b]) >= 20:
			var color_id := int(cells[b] if int(cells[a]) >= 20 else cells[a]) % 10
			for i in range(49):
				if int(cells[i]) % 10 == color_id:
					cells[i] = color_id + 10
					forced.append(i)
		else:
			for i in range(49):
				if absi(i % 7 - a % 7) <= 2 and absi(i / 7 - a / 7) <= 2: forced.append(i)
	moves -= 1
	work += 1
	charge = mini(6, charge + 1)
	return resolve(forced)

func smash(index: int) -> Array:
	if hammer <= 0 or index < 0 or index >= 49 or moves <= 0 or phase_done():
		return []
	hammer -= 1
	return resolve([index])

func use_hero(index: int) -> Array:
	if charge < 6 or index < 0 or index >= 49 or moves <= 0 or phase_done(): return []
	charge = 0
	var forced: Array = []
	match hero:
		0:
			for i in range(7): forced.append(index / 7 * 7 + i)
		1:
			var color_id := int(cells[index]) % 10
			for i in range(7): cells[index / 7 * 7 + i] = color_id
		2:
			for i in range(49):
				if absi(i % 7 - index % 7) <= 1 and absi(i / 7 - index / 7) <= 1: forced.append(i)
		3:
			for i in range(49):
				if absi(i % 7 - index % 7) + absi(i / 7 - index / 7) <= 2: forced.append(i)
	return resolve(forced)

func resolve(forced: Array) -> Array:
	var frames: Array = []
	var combo := 0
	while combo < 12:
		var groups := matches()
		if groups.is_empty() and forced.is_empty(): break
		combo += 1
		var cleared: Dictionary = {}
		var specials: Dictionary = {}
		for index in forced: cleared[index] = true
		for group in groups:
			for index in group: cleared[index] = true
			if group.size() >= 4 and group.all(func(i): return int(cells[i]) < 10):
				var pivot: int = group[group.size() / 2]
				specials[pivot] = int(cells[pivot]) % 10 + (20 if group.size() >= 5 else 10)
		var processed: Dictionary = {}
		var growing := true
		while growing:
			growing = false
			for index in cleared.keys():
				if processed.has(index): continue
				processed[index] = true
				var value: int = cells[index]
				if value < 10: continue
				for other in range(49):
					var hit := (absi(other % SIZE - int(index) % SIZE) <= 1 and absi(other / SIZE - int(index) / SIZE) <= 1) if value < 20 else int(cells[other]) % 10 == value % 10
					if hit and not cleared.has(other):
						cleared[other] = true
						growing = true
		var gained := cleared.size() * 20 * mini(combo, 3)
		score += gained
		frames.append({"cells": cells.duplicate(), "clear": cleared.keys(), "combo": combo, "gain": gained, "weeds": weeds.duplicate(), "cargo": cargo.duplicate()})
		for index in cleared:
			collected[int(cells[index]) % 10] += 1
			weeds.erase(index)
		# Delivery tokens are attached to their tile; clearing a carrier drops the token.
		var next_cargo: Array = []
		var carriers := cargo.duplicate()
		for position in cargo:
			var below := 0
			for row in range(int(position) / 7 + 1, 7):
				var below_index: int = row * 7 + int(position) % 7
				if cleared.has(below_index) and not cargo.has(below_index) and not specials.has(below_index): below += 1
			var destination: int = mini(48, int(position) + below * 7)
			if destination / 7 == 6: delivered += 1
			else: next_cargo.append(destination)
		cargo = next_cargo
		for index in cleared:
			if not carriers.has(index): cells[index] = -1
		for index in specials: cells[index] = specials[index]
		for column in range(SIZE):
			var remaining: Array = []
			for row in range(SIZE - 1, -1, -1):
				if int(cells[row * SIZE + column]) >= 0: remaining.append(cells[row * SIZE + column])
			for row in range(SIZE - 1, -1, -1):
				cells[row * SIZE + column] = remaining.pop_front() if not remaining.is_empty() else rng.randi_range(0, TYPES - 1)
		forced = []
	best_combo = maxi(best_combo, combo)
	if combo == 12 or find_move().is_empty(): generate()
	return frames

func snapshot() -> Dictionary:
	return {"version": 3, "phase": phase, "phased": phased, "total_score": total_score, "phase_seed": phase_seed, "cells": cells.duplicate(), "moves": moves, "score": score, "target": target, "combo": best_combo, "hammer": hammer, "rng": str(rng.state), "work": work, "required_work": required_work, "stage": stage_id, "collected": collected.duplicate(), "weeds": weeds.duplicate(), "cargo": cargo.duplicate(), "delivered": delivered, "hero": hero, "charge": charge}

func restore(data: Dictionary) -> bool:
	if not data.get("cells") is Array or data["cells"].size() != 49: return false
	for value in data["cells"]:
		if int(value) < 0 or int(value) > 24 or int(value) % 10 >= TYPES: return false
	cells = data["cells"].duplicate()
	moves = clampi(int(data.get("moves", 42)), 0, 47)
	score = maxi(0, int(data.get("score", 0)))
	target = maxi(900, int(data.get("target", 900)))
	best_combo = maxi(0, int(data.get("combo", 0)))
	hammer = clampi(int(data.get("hammer", 1)), 0, 1)
	rng.state = int(data.get("rng", "1"))
	stage_id = clampi(int(data.get("stage", 0)), 0, 4)
	work = maxi(0, int(data.get("work", 0)))
	required_work = clampi(int(data.get("required_work", 18)), 6, 26)
	collected = data.get("collected", [0, 0, 0, 0, 0]).duplicate()
	if collected.size() != 5: collected = [0, 0, 0, 0, 0]
	weeds = data.get("weeds", []).duplicate()
	cargo = data.get("cargo", []).duplicate()
	delivered = int(data.get("delivered", 0))
	hero = clampi(int(data.get("hero", 0)), 0, 3)
	charge = clampi(int(data.get("charge", 0)), 0, 6)
	phased = bool(data.get("phased", false))
	phase = clampi(int(data.get("phase", 2)), 0, 2)
	total_score = maxi(0, int(data.get("total_score", 0)))
	phase_seed = str(data.get("phase_seed", data.get("rng", "1")))
	if not data.has("version"):
		# Preserve old scores while supplying enough turns for the new construction tasks.
		moves = maxi(moves, 36)
	return true
