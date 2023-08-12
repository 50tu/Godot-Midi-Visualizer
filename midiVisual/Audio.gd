extends AudioStreamPlayer2D

@onready var spect  = AudioServer.get_bus_effect_instance(0,0)
var time = 0.0
# Called when the node enters the scene tree for the first time.

@export var freqArea := [20.,20000]
@export var bars :int= 20

var barList=[]

func _ready():
	for i in range(bars):
		barList.append([0,0])


func _process(delta):
	if playing:
		time = get_playback_position() + AudioServer.get_time_since_last_mix()
		#延迟让播放变慢
		time -= AudioServer.get_output_latency()
#		print("Time is: ", time)
#	print(spect)
	var nowFreq = freqArea[0]
	var freqDis = (freqArea[1]-freqArea[0])/bars
	for i in range(bars):
		var mag = spect.get_magnitude_for_frequency_range(nowFreq,nowFreq+ freqDis)
#		mag = [linear_to_db(mag[0]),linear_to_db(mag[1])]
		nowFreq += freqDis	
		barList[i] = mag
		
#	print(barList)
