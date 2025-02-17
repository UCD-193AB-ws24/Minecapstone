extends WorldEnvironment

@onready var sun: DirectionalLight3D = $Sun
@onready var moon: DirectionalLight3D = $Moon

enum SunPhase { Day, Night, Sunrise, Sunset }

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

# Shader control
@export var use_elapsed_time_for_shader: bool = false

var elapsed_time: float = 0.0
var previous_elevation: float = 0.0

func _ready():
	_update_shader_parameters()

func _process(delta):
	# Update time
	elapsed_time += delta * time_scale
	
	# Calculate rotation speed based on day/night cycle
	# TODO: use SunPhase to give day and night different speeds
	var cycle_duration = day_duration_seconds + night_duration_seconds
	var rotation_speed = deg_to_rad(360.0) / cycle_duration
	
	# Update sun rotation
	sun.rotation.x += rotation_speed * delta * time_scale
	sun.rotation.y = deg_to_rad(180.0)
	# sun.rotation.z = 0
	
	# Update moon rotation (opposite X rotation)
	moon.rotation.x = -sun.rotation.x
	moon.rotation.y = sun.rotation.y - deg_to_rad(180.0)
	# moon.rotation.z = 0
	
	# Update environment
	# var current_phase = determine_sun_phase()
	#modify_sky(current_phase)
	_update_shader_parameters()

func determine_sun_phase() -> SunPhase:
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
		phase = SunPhase.Sunrise if elevation > previous_elevation else SunPhase.Sunset

	var phase_str: String
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

# func modify_sky(phase: SunPhase):
# 	# Sky modification logic here based on phase
# 	# eg adjust light energy based on sun elevation
# 	var sun_direction = sun.global_transform.basis.z.normalized()
# 	sun.light_energy = smoothstep(-0.1, 0.1, sun_direction.y)
# 	moon.light_energy = smoothstep(-0.1, 0.1, moon.global_transform.basis.z.normalized().y)

func _update_shader_parameters():
	environment.sky.sky_material.set_shader_parameter("clouds_cutoff", clouds_cutoff)
	environment.sky.sky_material.set_shader_parameter("clouds_weight", clouds_weight)
	
	if use_elapsed_time_for_shader:
		environment.sky.sky_material.set_shader_parameter("overwritten_time", elapsed_time * 100.0)
	else:
		environment.sky.sky_material.set_shader_parameter("overwritten_time", 0.0)
