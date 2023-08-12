extends Control
@onready var audioNode =  $"../main/Audio"
var bars
var barList = [[],[]]
var barSize = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	
	bars = audioNode.bars
	$Stereo/l/bar.visible =false
	$Stereo/l/bar.modulate = Color.from_hsv(randf(),randf()*0.5+0.3,.92,.3)
	$Stereo/r/bar.visible =false
	$Stereo/r/bar.modulate = Color.from_hsv(randf(),randf()*0.6+0.3,.92,.3)
	$Stereo/l.position.x += size.x/bars *0.25
	$Stereo/r.position.x -= size.x/bars *0.25
#	print($Stereo/l.position.x,$Stereo/r.position.x )
	
	for i in range(bars):
		var bar = $Stereo/l/bar.duplicate()
		var bar2 = $Stereo/r/bar.duplicate()
		barList[0].append(bar)
		barList[1].append(bar2)
		bar.visible = true
		bar2.visible = true
		$Stereo/l.add_child(bar)
		$Stereo/r.add_child(bar2)
#	print(barList)	
	
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var barVList = audioNode.barList	
#			mag = [linear_to_db(mag[0]),linear_to_db(mag[1])]
	for i in range(bars):
#		print(barVList)
		if barVList[i][0] > 0: #按频谱，按左右
			barList[0][i].get_child(0)["offset_top"] = linear_to_db(barVList[i][0])*barSize #左右 谱
		if barVList[i][1] > 0:
			barList[1][-i-1].get_child(0)["offset_top"] = linear_to_db(barVList[i][1])*barSize #先左右，谱

#	for i in barList[0]:
#		print(i.get_child(0))

	pass
