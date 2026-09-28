extends Control

const BOTANICAL := preload("res://assets/decor/botanical_atlas.png")
const LAVENDER := preload("res://assets/decor/lavender_atlas.png")
const PROJECTS := ["cafe", "kite_workshop", "canal_cottage", "greenhouse", "observatory"]
static var texture_cache: Dictionary = {}
var before: Texture2D
var after: Texture2D
var completion := 0.0
var decor := 0

static func decorated_texture(original: Texture2D, choice: int) -> Texture2D:
	if original == null or choice == 0: return original
	var project := original.resource_path.get_file().trim_suffix("_after.png")
	var index := PROJECTS.find(project)
	if index < 0: return original
	var key := "%s_%d" % [project, choice]
	if not texture_cache.has(key):
		var sheet: Texture2D = BOTANICAL if choice == 1 else LAVENDER
		var cell := sheet.get_size() / Vector2(2, 3)
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(index % 2, index / 2) * cell + Vector2(3, 3), cell - Vector2(6, 6))
		texture_cache[key] = atlas
	return texture_cache[key]

func _draw() -> void:
	var inner := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	draw_rect(Rect2(Vector2.ZERO, size), Color("ffd166"))
	if before: draw_texture_rect_region(before, inner, source_region(before, inner.size))
	if after and completion > 0:
		var finished := decorated_texture(after, decor)
		var width := inner.size.x * clampf(completion, 0, 1)
		var source := source_region(finished, inner.size)
		source.size.x *= clampf(completion, 0, 1)
		draw_texture_rect_region(finished, Rect2(inner.position, Vector2(width, inner.size.y)), source)
		if completion < 1: draw_line(Vector2(width + 3, 3), Vector2(width + 3, size.y - 3), Color("ffd166"), 2)

func source_region(texture: Texture2D, dimensions: Vector2) -> Rect2:
	var original := texture.get_size()
	var factor := maxf(dimensions.x / original.x, dimensions.y / original.y)
	var crop := dimensions / factor
	return Rect2((original - crop) / 2, crop)
