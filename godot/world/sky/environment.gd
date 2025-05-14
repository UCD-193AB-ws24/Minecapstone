@tool
extends WorldEnvironment

enum SunPhase { Day, Night, Sunrise, Sunset }

# Sun & Moon
@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon

# Low graphics mode
@export var low_graphics_mode: bool = true

# Time settings
@export var day_duration_seconds: float = 30.0
@export var night_duration_seconds: float = 30.0
@export var time_scale: float = 1.0

# Celestial parameters
@export_range(-90.0, 90.0) var latitude: float = 0.0
@export_range(-180.0, 180.0) var axial_tilt: float = 23.44

# Cloud settings
@export_range(0.0, 1.0) var clouds_cutoff: float = 0.3
@export_range(0.0, 1.0) var clouds_weight: float = 0.0


var elapsed_time: float = 0.0
var previous_elevation: float = 0.0


func _ready():
	if low_graphics_mode:
		self.environment = load("res://world/sky/nosky.tres")
		$Water.visible = false
	else:
		self.environment = load("res://world/sky/sky.tres")
		$Water.visible = true
	
	# Get the initial sun elevation for phase detection
	var sun_direction = sun.global_transform.basis.z.normalized()
	previous_elevation = asin(sun_direction.y)
	
	# Keep the default y rotation but maintain current x rotation
	sun.rotation.y = deg_to_rad(180.0)
	moon.rotation.x = -sun.rotation.x
	moon.rotation.y = sun.rotation.y - deg_to_rad(180.0)
	
	_update_shader_parameters()


func _process(delta):
	if Engine.is_editor_hint(): return

	# Update time
	elapsed_time += delta * time_scale
	
	# Get the current phase before updating positions
	var current_phase = determine_sun_phase()
	
	# Calculate rotation speed based on current phase (day or night)
	var rotation_speed: float
	if current_phase == SunPhase.Day or current_phase == SunPhase.Sunrise:
		rotation_speed = deg_to_rad(180.0) / day_duration_seconds  # 180 degrees for day portion
	else:
		rotation_speed = deg_to_rad(180.0) / night_duration_seconds  # 180 degrees for night portion
	
	# Update sun rotation
	sun.rotation.x += rotation_speed * delta * time_scale
	sun.rotation.y = deg_to_rad(180.0)
	
	# Keep sun rotation within range to prevent float precision issues over time
	if sun.rotation.x > 2 * PI:
		sun.rotation.x -= 2 * PI
	
	# Update moon rotation (opposite X rotation)
	moon.rotation.x = -sun.rotation.x
	moon.rotation.y = sun.rotation.y - deg_to_rad(180.0)
	
	# Update environment
	_update_shader_parameters()


func determine_sun_phase(debug=false) -> SunPhase:
	var sun_direction = sun.global_transform.basis.z.normalized()
	var elevation = asin(sun_direction.y)
	
	const DAY_THRESHOLD = deg_to_rad(5.0)
	const NIGHT_THRESHOLD = deg_to_rad(-5.0)
	
	var phase: SunPhase
	if elevation > DAY_THRESHOLD:
		phase = SunPhase.Day
	elif elevation < NIGHT_THRESHOLD:
		phase = SunPhase.Night
	else:
		# Transition detection based on the change in elevation
		if elevation > previous_elevation:
			phase = SunPhase.Sunrise
		else:
			phase = SunPhase.Sunset
	
	# Debug information
	if debug:
		var phase_str: String = ""
		match phase:
			SunPhase.Day:
				phase_str = "Day"
			SunPhase.Night:
				phase_str = "Night"
			SunPhase.Sunrise:
				phase_str = "Sunrise"
			SunPhase.Sunset:
				phase_str = "Sunset"
		print("Current sun phase: ", phase_str)
	
	previous_elevation = elevation
	return phase


func _update_shader_parameters():
	if not environment.sky: return
	
	environment.sky.sky_material.set_shader_parameter("clouds_cutoff", clouds_cutoff)
	environment.sky.sky_material.set_shader_parameter("clouds_weight", clouds_weight)