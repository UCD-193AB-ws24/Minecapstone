extends Node3D

@export var voronoi_noise: FastNoiseLite
@export var temperature_noise: FastNoiseLite
@export var precipitation_noise: FastNoiseLite
@export var height_noise: FastNoiseLite

const SIZE = 1024
const BIOME_NAMES = [
	"desert",
	"savanna",
	"tropical_woodland",
	"tundra",
	"seasonal_forest",
	"rainforest",
	"temperate_forest",
	"temperate_rainforest",
	"boreal_forest"
]
const BIOME_COLORS = [
	Color(1.0, 1.0, 0.698), # desert
	Color(0.722, 0.784, 0.384), # savanna
	Color(0.737, 0.631, 0.208), # tropical_woodland
	Color(0.745, 1.0, 0.949), # tundra
	Color(0.416, 0.565, 0.149), # seasonal_forest
	Color(0.129, 0.302, 0.161), # rainforest
	Color(0.337, 0.702, 0.416), # temperate_forest
	Color(0.133, 0.239, 0.208), # temperate_rainforest
	Color(0.137, 0.447, 0.369)  # boreal_forest
]

var biome_indices = []
var generation_thread: Thread
var _threaded_biome_texture: ImageTexture

func _ready():
	# Load and process TP_map into biome indices
	var tp_image = Image.load_from_file("res://assets/TP_map.png")
	tp_image.decompress()
	if tp_image.get_format() != Image.FORMAT_RGBA8:
		tp_image.convert(Image.FORMAT_RGBA8)
	
	biome_indices.resize(256)
	for x in 256:
		biome_indices[x] = []
		biome_indices[x].resize(256)
		for y in 256:
			var color = tp_image.get_pixel(x, y)
			var index = get_biome_index(color)
			biome_indices[x][y] = index
	
	generate()

func get_biome_index(color: Color) -> int:
	var min_dist = INF
	var best_index = 0
	for i in BIOME_COLORS.size():
		var biome_color = BIOME_COLORS[i]
		var dist = sqrt(pow(color.r - biome_color.r, 2) + pow(color.g - biome_color.g, 2) + pow(color.b - biome_color.b, 2))
		if dist < min_dist:
			min_dist = dist
			best_index = i
	return best_index

func generate():
	print("Generating world...")
	# Prevent concurrent generation
	if generation_thread and generation_thread.is_alive():
		return
	generation_thread = Thread.new()
	generation_thread.start(Callable(self, "_threaded_generate"))

func _threaded_generate():
	# Compute mask, averages, and final biome map image
	var land_ocean_mask = create_land_ocean_mask(height_noise)
	
	# Compute average temperature and precipitation per Voronoi cell
	var temperature_averages = average_voronoi(temperature_noise)
	var precipitation_averages = average_voronoi(precipitation_noise)
	
	display_noise(temperature_noise, Vector3(0, 7, 0))
	display_dict(temperature_averages, Vector3(0, 0, 0))

	display_noise(precipitation_noise, Vector3(7, 7, 0))
	display_dict(precipitation_averages, Vector3(7, 0, 0))
	
	display_noise(height_noise, Vector3(14, 7, 0))
	display_dict(land_ocean_mask, Vector3(14, 0, 0))

	display_voronoi(Vector3(21, 7, 0))
	
	# Generate biome map
	var biome_map_image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for x in SIZE:
		for y in SIZE:
			var pos = Vector2(x, y)
			var is_land = land_ocean_mask[pos]
			if not is_land:
				biome_map_image.set_pixel(x, y, Color(0, 0, 1))  # Ocean color
				continue
			
			var temp = temperature_averages[pos]
			var precip = precipitation_averages[pos]
			
			# Quantize to 0-255
			var quant_temp = int((temp + 1.0) * 127.5)
			quant_temp = clamp(quant_temp, 0, 255)
			var quant_precip = int((precip + 1.0) * 127.5)
			quant_precip = clamp(quant_precip, 0, 255)
			quant_precip = 255 - quant_precip  # Invert precipitation axis
			
			var biome_index = biome_indices[quant_temp][quant_precip]
			var color = BIOME_COLORS[biome_index]
			biome_map_image.set_pixel(x, y, color)

	# TODO: Normal mapping with the height map
	
	var biome_texture = ImageTexture.create_from_image(biome_map_image)
	_threaded_biome_texture = biome_texture
	call_deferred("_finalize_generation")

func _finalize_generation():
	# Create new sprite with the generated texture
	var sprite = Sprite3D.new()
	sprite.texture = _threaded_biome_texture
	sprite.pixel_size = 0.006
	sprite.position = Vector3(21, 0, 0)
	call_deferred("add_child", sprite)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		generate()

func average_voronoi(data):
	var voronoi_data = {}
	# First pass: Store voronoi hash for each coordinate
	for x in range(SIZE):
		for y in range(SIZE):
			var pos = Vector2(x, y)
			var value = voronoi_noise.get_noise_2d(x, y)
			voronoi_data[pos] = hash(value)

	# Group positions by their voronoi hash
	var hash_groups = {}
	for pos in voronoi_data:
		var h = voronoi_data[pos]
		if not hash_groups.has(h):
			hash_groups[h] = []
		hash_groups[h].append(pos)

	# Calculate averages for each group
	var averages = {}
	for h in hash_groups:
		var positions = hash_groups[h]
		var total = 0.0

		# Sum all values in this group
		for pos in positions:
			total += data.get_noise_2d(pos.x, pos.y)

		# Calculate average
		var avg = total / positions.size()

		# Assign average to all positions in group
		for pos in positions:
			averages[pos] = avg

	return averages


func display_dict(dict, offset:Vector3):
	var voronoi_texture = ImageTexture.create_from_image(dict_to_image(dict))
	var sprite = Sprite3D.new()
	sprite.texture = voronoi_texture
	sprite.pixel_size = 0.006
	sprite.position += offset
	call_deferred("add_child", sprite)


func dict_to_image(data):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SIZE):
		for y in range(SIZE):
			var value = data[Vector2(x, y)]

			var color_value = (float(value) + 1) * 0.5
			image.set_pixel(x, y, Color(color_value, color_value, color_value, 1.0))
	return image

func display_noise(data:Noise, offset:Vector3):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for x in range(SIZE):
		for y in range(SIZE):
			var value = data.get_noise_2d(x, y)

			var color_value = (value + 1) * 0.5
			image.set_pixel(x, y, Color(color_value, color_value, color_value, 1.0))

	var texture = ImageTexture.create_from_image(image)
	var sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = 0.006
	sprite.position += offset
	call_deferred("add_child", sprite)


func display_voronoi(offset):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for x in range(SIZE):
		for y in range(SIZE):
			var value = voronoi_noise.get_noise_2d(x, y)
			# Generate consistent color from averaged Voronoi value
			var h = hash(value)
			var r = float((h >> 16) & 0xFF) / 255.0
			var g = float((h >> 8) & 0xFF) / 255.0
			var b = float(h & 0xFF) / 255.0
			image.set_pixel(x, y, Color(r, g, b))

	var voronoi_texture = ImageTexture.create_from_image(image)
	var sprite = Sprite3D.new()
	sprite.texture = voronoi_texture
	sprite.pixel_size = 0.006
	sprite.position += offset
	call_deferred("add_child", sprite)


func create_land_ocean_mask(data: Noise):
	var mask = {}
	for x in range(SIZE):
		for y in range(SIZE):
			var value = data.get_noise_2d(x, y)
			mask[Vector2(x, y)] = value > 0.0 # Land if value > 0, ocean otherwise
	return mask

func display_land_ocean(mask, offset: Vector3):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SIZE):
		for y in range(SIZE):
			var is_land = mask[Vector2(x, y)]
			var color = Color(0, 0, 1, 1) if not is_land else Color(0, 1, 0, 1) # Blue for ocean, green for land
			image.set_pixel(x, y, color)
	var texture = ImageTexture.create_from_image(image)
	var sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = 0.006
	sprite.position += offset
	call_deferred("add_child", sprite)
