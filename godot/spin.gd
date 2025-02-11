extends Sprite3D
var time = 0;
func _process(delta: float) -> void:
	var deg_per_sec = 290.0
	rotate_y(delta * deg_to_rad(deg_per_sec))
	var frequency = 1.0
	var amplitude = 0.002
	time += delta * frequency
	self.position += Vector3(0,sin(time) * amplitude,0)
	if time >= 6.28318531: # approxmate value of 2 * pi
		time -= 6.28318531
