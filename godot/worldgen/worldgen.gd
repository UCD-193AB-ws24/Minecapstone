extends Node3D

signal world_generated

@export var voronoi_noise: FastNoiseLite
@export var temperature_noise: FastNoiseLite
@export var precipitation_noise: FastNoiseLite
@export var height_noise: FastNoiseLite
var smooth_height_noise: FastNoiseLite

@onready var SIZE = 32 * 16
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
var debug = true

# func _input(event: InputEvent) -> void:
# 	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
# 		generate()

var temperature_averages
var precipitation_averages
var combined_height_image
var land_ocean_mask

func _get_biome_index(x: int, y: int) -> int:
	var pos = Vector2(x, y)
	# If the point isn't generated or out of bounds, return unknown.
	if not land_ocean_mask.has(pos):
		return -1
	# If it's not land, return ocean.
	if not land_ocean_mask[pos]:
		return -1
	
	# Retrieve average noise values
	var temp = temperature_averages.get(pos, 0.0)
	var precip = precipitation_averages.get(pos, 0.0)
	
	# Quantize the values (0-255 range)
	var quant_temp = clamp(int((temp + 1.0) * 127.5), 0, 255)
	var quant_precip = clamp(int((precip + 1.0) * 127.5), 0, 255)
	quant_precip = 255 - quant_precip  # invert the precipitation axis
	
	# Get biome index from the precomputed biome indices array
	var index = biome_indices[quant_temp][quant_precip]
	return index

func get_biome_color(x: int, y: int) -> Color:
	var index = _get_biome_index(x, y)
	return BIOME_COLORS[index]

func get_biome(x: int, y: int) -> String:
	var index = _get_biome_index(x, y)
	return BIOME_NAMES[index]

func generate():
	world_generated.is_null()
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
			var index = _get_biome_index_from_color(color)
			biome_indices[x][y] = index
			
	smooth_height_noise = height_noise.duplicate()
	smooth_height_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	smooth_height_noise.domain_warp_amplitude = 0.0
	
	print("Generating world...")
	_handle_loading_screen()

	# Prevent concurrent generation
	if generation_thread and generation_thread.is_alive():
		return
	generation_thread = Thread.new()
	generation_thread.start(Callable(self, "_threaded_generate"))

func _threaded_generate():
	# Debug voronoi noise
	_display_voronoi()

	# Compute average temperature per Voronoi cell
	_display_noise(temperature_noise)
	temperature_averages = _average_voronoi(temperature_noise)
	_display_dict(temperature_averages)

	# Compute average precipitation per Voronoi cell
	_display_noise(precipitation_noise)
	precipitation_averages = _average_voronoi(precipitation_noise)
	_display_dict(precipitation_averages)

	# Compute mask, averages, and final biome map image
	_display_noise(height_noise)
	land_ocean_mask = _create_land_ocean_mask(height_noise)
	_display_dict(land_ocean_mask)

	# Combine the smoothened and detailed height maps between land and ocean
	_display_noise(smooth_height_noise)
	combined_height_image = _create_combined_height_image()
	_display_image(combined_height_image)

	var biome_map = _create_biome_map_image()
	_display_image(biome_map)

	call_deferred("_handle_loading_screen", null, false)
	
	# Emit signal when world generation is complete
	call_deferred("emit_signal", "world_generated")

func _create_combined_height_image() -> Image:
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RF)
	for x in SIZE:
		for y in SIZE:
			var pos = Vector2(x, y)
			var is_land = land_ocean_mask[pos]
			var detailed_value = height_noise.get_noise_2d(x, y)
			var smooth_value = smooth_height_noise.get_noise_2d(x, y)
			var combined_value = detailed_value if is_land else smooth_value
			image.set_pixel(x, y, Color(combined_value, combined_value, combined_value))
	
	# Normalize to 0-1 range
	image.convert(Image.FORMAT_RGBA8)
	for x in SIZE:
		for y in SIZE:
			var value = image.get_pixel(x, y).r
			var normalized_value = (value + 1.0) / 2.0
			image.set_pixel(x, y, Color(normalized_value, normalized_value, normalized_value))

	return image

func _create_biome_map_image() -> Image:
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for x in SIZE:
		for y in SIZE:
			var pos = Vector2(x, y)
			var is_land = land_ocean_mask[pos]
			if is_land:
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

				# TODO: properly adjust height factor based on biome
				var height_value = height_noise.get_noise_2d(x, y)
				var height_factor = clamp((height_value + 1.0) * 0.5, 0.2, 1.0)
				color.r *= height_factor
				color.g *= height_factor
				color.b *= height_factor
				image.set_pixel(x, y, color)
			else: # is_ocean
				var ocean_color = Color(0.0, 0.0, 1)
				var smooth_value = smooth_height_noise.get_noise_2d(x, y)
				var height_factor = clamp((smooth_value + 1.0) * 0.5, 0.2, 1.0)
				ocean_color.r *= height_factor
				ocean_color.g *= height_factor
				ocean_color.b *= height_factor
				image.set_pixel(x, y, ocean_color)

	call_deferred("_handle_loading_screen", ImageTexture.create_from_image(image))
	return image

func _get_biome_index_from_color(color: Color) -> int:
	var min_dist = INF
	var best_index = 0
	for i in BIOME_COLORS.size():
		var biome_color = BIOME_COLORS[i]
		var dist = sqrt(pow(color.r - biome_color.r, 2) + pow(color.g - biome_color.g, 2) + pow(color.b - biome_color.b, 2))
		if dist < min_dist:
			min_dist = dist
			best_index = i
	return best_index

func _average_voronoi(data):
	var sums = {}      # key: voronoi hash, value: sum of noise values
	var counts = {}    # key: voronoi hash, value: count
	var pos_hash = {}  # key: position, value: voronoi hash
	
	# First pass: collect sums, counts, and store hash per position
	for x in range(SIZE):
		for y in range(SIZE):
			var pos = Vector2(x, y)
			var h = voronoi_noise.get_noise_2d(x, y)
			pos_hash[pos] = h
			var value = data.get_noise_2d(x, y)
			if not sums.has(h):
				sums[h] = value
				counts[h] = 1
			else:
				sums[h] += value
				counts[h] += 1
	
	# Compute averages per Voronoi key
	var averages = {}
	for h in sums.keys():
		averages[h] = sums[h] / counts[h]
	
	# Assign resulting average to each position
	var result = {}
	for pos in pos_hash.keys():
		result[pos] = averages[pos_hash[pos]]
	
	return result

func _display_noise(data:Noise):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for x in range(SIZE):
		for y in range(SIZE):
			var value = data.get_noise_2d(x, y)
			var color_value = (value + 1) * 0.5
			image.set_pixel(x, y, Color(color_value, color_value, color_value, 1.0))
			
	var texture = ImageTexture.create_from_image(image)
	call_deferred("_handle_loading_screen", texture)

func _display_dict(dict):
	var texture = ImageTexture.create_from_image(_dict_to_image(dict))
	call_deferred("_handle_loading_screen", texture)

func _dict_to_image(data):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SIZE):
		for y in range(SIZE):
			var value = data[Vector2(x, y)]
			var color_value = (float(value) + 1) * 0.5
			image.set_pixel(x, y, Color(color_value, color_value, color_value, 1.0))
	return image

func _display_image(image):
	var texture = image if image is ImageTexture else ImageTexture.create_from_image(image)
	call_deferred("_handle_loading_screen", texture)

func _display_voronoi():
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
	
	var texture = ImageTexture.create_from_image(image)
	call_deferred("_handle_loading_screen", texture)

func _create_land_ocean_mask(data: Noise):
	var mask = {}
	for x in range(SIZE):
		for y in range(SIZE):
			var value = data.get_noise_2d(x, y)
			mask[Vector2(x, y)] = value > 0.0 # Land if value > 0, ocean otherwise
	return mask

func _display_land_ocean(mask):
	var image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SIZE):
		for y in range(SIZE):
			var is_land = mask[Vector2(x, y)]
			var color = Color(0, 0, 1) if not is_land else Color(0, 1, 0) # Blue for ocean, green for land
			image.set_pixel(x, y, color)
	var texture = ImageTexture.create_from_image(image)
	call_deferred("_handle_loading_screen", texture)
	
func _handle_loading_screen(texture: ImageTexture = null, enabled: bool = true) -> void:
	if enabled:
		$LoadingScreen.visible = true
		$"LoadingScreen/CenterContainer/MarginContainer/TextureRect".texture = texture
	else:
		$LoadingScreen.visible = false
		$"LoadingScreen/CenterContainer/MarginContainer/TextureRect".texture = null
