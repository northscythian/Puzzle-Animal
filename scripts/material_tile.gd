extends Button

const ATLAS = preload("res://assets/tiles/materials.webp")
var tile_kind := 0:
	set(value):
		tile_kind = value
		queue_redraw()
var weed := false
var rubble := false
var delivery := false

func sprite(index: int, rect: Rect2) -> void:
	var cell := Vector2(ATLAS.get_width() / 4.0, ATLAS.get_height() / 2.0)
	var source := Rect2(Vector2(index % 4, index / 4) * cell, cell)
	draw_texture_rect_region(ATLAS, rect, source)

func _draw() -> void:
	var material := clampi(tile_kind % 10, 0, 4)
	var index := 6 if tile_kind >= 20 else (5 if tile_kind >= 10 else material)
	var edge := minf(size.x, size.y) - 6.0
	var rect := Rect2((size - Vector2.ONE * edge) / 2.0, Vector2.ONE * edge)
	sprite(index, rect)
	# Bonuses retain a material badge: color still matters to matching rules.
	if tile_kind >= 10:
		var badge := edge * 0.34
		sprite(material, Rect2(rect.position + Vector2(0, edge - badge), Vector2.ONE * badge))
	# Overlay coordinates scale with both desktop and touch-sized cells.
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(65, 65))
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
	draw_set_transform(Vector2.ZERO)
