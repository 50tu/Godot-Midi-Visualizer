extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	$parPos/GPUParticles2D.emitting = false
	$parPos/GPUParticles2D.modulate = Color.from_hsv(randf(),randf()*.5 +0.5,.5,.25)*4
#	print($parPos/GPUParticles2D.modulate)
	pass # Replace with function body.

func notePlaying(On):
	if On :
		$parPos/GPUParticles2D.emitting = true
	else:
		$parPos/GPUParticles2D.emitting = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
