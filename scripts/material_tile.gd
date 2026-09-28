extends Button

var tile_kind := 0:
	set(value):
		tile_kind = value
		queue_redraw()
var weed := false
var rubble := false
var delivery := false

func _draw() -> void:
	var center := size / 2.0
	var ink := Color("fff7de")
	var dark := Color("284650")
	var palette := [Color("ff783b"), Color("ffd068"), Color("40e5ff"), Color("f15bf4"), Color("a6ef58")]
	var hue: Color = palette[tile_kind % 10]
	draw_circle(center + Vector2(0, 4), 26, Color("102a3566"))
	draw_circle(center, 25, hue.darkened(0.35))
	draw_circle(center - Vector2(0, 2), 23, hue)
	draw_arc(center - Vector2(0, 2), 20, PI * 1.12, PI * 1.85, 18, hue.lightened(0.65), 3, true)
	ink = hue.lightened(0.82)
	if tile_kind >= 20:
		for ray in range(12):
			var angle := ray * TAU / 12
			draw_circle(center + Vector2.from_angle(angle) * 21, 4, Color.from_hsv(float(ray) / 12, 0.8, 1.0))
		for i in range(8):
			var angle := i * PI / 4
			draw_line(center + Vector2.from_angle(angle) * 9, center + Vector2.from_angle(angle) * 22, ink, 4, true)
		draw_circle(center, 8, ink)
	elif tile_kind >= 10:
		draw_circle(center + Vector2(0, 3), 13, dark)
		draw_circle(center + Vector2(-4, -1), 4, ink)
		draw_polyline(PackedVector2Array([center + Vector2(5, -8), center + Vector2(8, -18), center + Vector2(17, -20)]), ink, 3, true)
		draw_line(center + Vector2(16, -26), center + Vector2(16, -14), ink, 2)
	else:
		match tile_kind:
			0:
				draw_rect(Rect2(center - Vector2(20, 12), Vector2(40, 24)), ink)
				draw_line(center - Vector2(20, 0), center + Vector2(20, 0), dark, 2)
				draw_line(center, center + Vector2(0, 12), dark, 2)
				draw_line(center - Vector2(10, 12), center - Vector2(10, 0), dark, 2)
			1:
				draw_rect(Rect2(center - Vector2(14, 20), Vector2(28, 40)), ink)
				draw_line(center - Vector2(6, 15), center + Vector2(-3, 15), dark, 2)
				draw_line(center + Vector2(5, -15), center + Vector2(8, 15), dark, 2)
			2:
				draw_colored_polygon(PackedVector2Array([center + Vector2(0, -22), center + Vector2(19, 0), center + Vector2(0, 22), center + Vector2(-19, 0)]), ink)
				draw_line(center + Vector2(-4, -9), center + Vector2(7, 3), dark, 3, true)
			3:
				draw_arc(center - Vector2(0, 5), 14, PI, TAU, 20, ink, 3, true)
				draw_rect(Rect2(center - Vector2(16, 6), Vector2(32, 24)), ink)
				draw_line(center + Vector2(-10, 1), center + Vector2(10, 1), dark, 3)
			4:
				for offset in [Vector2(-16, -16), Vector2(2, -16), Vector2(-16, 2), Vector2(2, 2)]:
					draw_rect(Rect2(center + offset, Vector2(14, 14)), ink)
	if weed and not rubble:
		draw_line(Vector2(5, 56), Vector2(55, 12), Color("246b31"), 6, true)
		for i in range(4):
			draw_circle(Vector2(12 + i * 10, 48 - i * 9), 6, Color("92e650"))
	if weed and rubble:
		for i in range(3):
			var point := Vector2(13 + i * 16, 48 + (i % 2) * 5)
			draw_colored_polygon(PackedVector2Array([point + Vector2(-10, 5), point + Vector2(-7, -6), point + Vector2(4, -9), point + Vector2(11, 4)]), Color("ae9b87"))
			draw_line(point + Vector2(-7, -6), point + Vector2(4, -9), Color("f3ddbc"), 2, true)
	if delivery:
		draw_circle(Vector2(49, 48), 12, Color("ffc34d"))
		draw_circle(Vector2(49, 48), 5, Color("3b4163"))
		draw_line(Vector2(49, 48), Vector2(49, 61), Color.WHITE, 2)
