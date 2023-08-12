extends Control

@export var trackDis = [10,0]
@export var timeDis = 800
@export_range(0.,1.) var noteSize = 1.0
@export_range(0.,1.) var noteAlpha = 0.9
@export var ColorRandomYN : bool = true
@export var nodeArea := Vector2(60,120):
	set(val):
		nodeArea = val
		keyMainTransform(nodeArea)
#		emit_signal("trans")
@export var nowTime:float = 0.0
@export var foreTime = 15
@export var waitTime = 1.


#signal trans
var data
var tracklist:Array = []#track的node
var notePosList:Array = []#按track
var allNote:Array = []#按时间
var unShowedNote :Array = []
var sPerTick = 0.
var toneMark
var ColorMap = []

var allowArea = [-500,0]
var nowNote: Dictionary = {}
var playingNote : Dictionary = {}
var sizePerNote
var KeyBoardNode 
var audioNode 

func keyMainTransform(nodeArea):
	var parentNode = $".."
	var noteNum = nodeArea.y - nodeArea.x
	parentNode.size.x = sizePerNote * 128 * (128/noteNum)
#	print( sizePerNote * 128,"dada", -sizePerNote * nodeArea.x)
	parentNode.position.x = -sizePerNote * nodeArea.x
	KeyBoardNode.size.x = sizePerNote * 132 * (128/noteNum)
#	KeyBoardNode.position.x = 0
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$track/note.visible = false
	$track.visible = false
	data  = $"../../01".parsedData
	var parentNode = $".."
	sizePerNote = parentNode.size.x / 128
	KeyBoardNode = $"../KeyBoard"
	audioNode = $"../Audio"
#	print(data)
	sPerTick = data["每tick的微秒"]/1000000
	print(data["每tick的微秒"])
#	toneMark = data["调号"]
	setTrack()
	
#	print("track号，位置，时长，音高，音量, 通道号")
	for i in range(len(tracklist)):
		listMidinote(i+1)


	for i in notePosList:
		for j in i[0]:
			allNote.append(j)
	allNote.sort_custom(sort_ascending) #获得排序
	unShowedNote = allNote.duplicate() #排序后的Note
	
	
	if ColorRandomYN: randomColor()
	
	var midiNoteOffest = 0
	var midiNoteStartPos = 0
	keyMainTransform(nodeArea)
	showAreaNote(midiNoteOffest,midiNoteStartPos)
	

func showAreaNote(midiNoteOffest,midiNoteStartPos):
	var popNum = 0
	for iS in range(len(unShowedNote)):#i:track号，位置，时长，音高，音量, 通道号
		var i = unShowedNote[iS]
		var headIn = (i[1] >= allowArea[0]) && ( i[1] <= allowArea[1] )
		if headIn && (nowNote.find_key(i)== null): #进入领域并且没有被记录过
			var creaNewNote = createNote(i,midiNoteOffest,midiNoteStartPos)
			nowNote[creaNewNote] = i
#			print(nowNote)
		elif !headIn:
			popNum = iS
			break #在领域之外的部分
	for i in range(popNum):
		unShowedNote.pop_front()
		
	for k in nowNote.keys():#已经显示的部分
		var i = nowNote[k]#i:track号，位置，时长，音高，音量, 通道号
		var tailOut = (i[1] + i[2]) <=allowArea[0]
		if tailOut :#尾巴出去了
#			print(i[1] + i[2],allowArea)
			nowNote.erase(k)#从列表取出
			k.queue_free()#释放资源
		else :#显示部分是否正在播放
			var playing = (nowTime/sPerTick >= i[1]) && (nowTime/sPerTick <=  i[1]+i[2])
#			print(playingNote,playingNote.find_key(i),playing,[nowTime/sPerTick,i[1]])
			if playing && (playingNote.find_key(i)== null): #正在播放且没有被记录
				playingNote[k] = i
				keyBoardPlaying(true,i)
#				print(playingNote,1)
			elif !playing && !(playingNote.find_key(i)== null):#没在播放且在播放列表中
				playingNote.erase(k)
				keyBoardPlaying(false,i)
#				print(playingNote,2)

func keyBoardPlaying(On,i):#i:track号，位置，时长，音高，音量, 通道号
	var pitch = i[3]
	var octNum = i[3]/12
	var pitchName = i[3]%12
#	print(KeyBoardNode.get_children())
	var keyNote = KeyBoardNode.get_children()[octNum].get_children()[0].get_children()[pitchName]
	if On :
		keyNote.modulate = Color(0.8,0.7,0.6,1.0)

	else:
		keyNote.modulate = Color(1.0,1.0,1.0,1.0)		
	keyNote.notePlaying(On)
#	print(pitch,On,"",keyNote,pitchName)
	
		
		
	
		
func createNote(i,midiNoteOffest,midiNoteStartPos):#i:track号，位置，时长，音高，音量, 通道号
	var midiNote = $track/note.duplicate()
	var trackNote = tracklist[i[0]-1]
	var NoteColor = ColorMap[i[0]-1]
	#位置
	midiNote.visible = true
#	midiNote.size.x = trackNote.size.x/128. * noteSize
	midiNote["anchor_left"] = (i[3])/128.
	midiNote["anchor_right"] = (i[3]+1.)/128.
#	midiNote["anchor_left"] = 0
#	midiNote["anchor_right"] = 1.
#	print(midiNote["anchor_left"],midiNote["anchor_right"] )
	
	var midiNote_size_y = i[2] * sPerTick* timeDis
	var midiNote_yAncher_delta = float(midiNote_size_y)/trackNote.size.y
	midiNoteOffest = i[1] * sPerTick* timeDis#随轨道位置往后
	midiNoteOffest = float(midiNoteOffest)/trackNote.size.y
	
	midiNote["anchor_left"] = (i[3])/128.	
	midiNoteStartPos = midiNoteStartPos + 1.#最底下
	midiNote["anchor_bottom"] = midiNoteStartPos - midiNoteOffest
	midiNote["anchor_top"] = midiNoteStartPos - midiNoteOffest - midiNote_yAncher_delta
#	midiNoteStartPos = midiNoteStartPos + trackNote.position.y + trackNote.size.y#最底下
#	midiNote.position.y = midiNoteStartPos - midiNote.size.y - midiNoteOffest #往上
#	midiNote.position.x = i[3]*trackNote.size.x/128.
	
	if  ColorRandomYN:
		midiNote["self_modulate"] =  Color(NoteColor[0],NoteColor[1],NoteColor[2],noteAlpha)

	trackNote.add_child(midiNote)
	return midiNote



func randomColor():
	for i in tracklist:
		var rawColor = [randf_range(0.4,1),randf_range(0.4,1),randf_range(0.4,1)]
		var added = (rawColor[0] + rawColor[1]+ rawColor[2]) / 2. # rgb总值
		ColorMap.append([rawColor[0]/added,rawColor[1]/added,rawColor[2]/added])
		

func listMidinote(tr):	
	var track = tr
	var noteoffset = 0
	var noteOnly = []#去掉计时
	var notePos = []#把同种音高的放一起
	var noteSet = [] #track号，位置，时长，音高，音量 
	var others = []
	for i in range(128):
		notePos.append([])#按照音高建立
	for i in data["轨道"][track]:#仅含note
		if str(i[0]) == "tick数":
			noteoffset +=i[1]
		elif int(i[0]) == 0 || int(i[0]) == 1 :
			i.append(noteoffset)
			noteOnly.append(i)
		else:
			others.append([noteoffset,i])
	for i in noteOnly:
		notePos[i[1]].append(i)#音高轨
	for i in notePos:
		if i != []:
			var pos = 0
			var nlen = 0
			var pit = 0
			var vol = 0
			var channelDic :Dictionary
			for j in i :#分note
				if j[0] == 1:#开音符
					pos = j[4]
					nlen = 0
					pit = j[1]
					vol = j[2]
					channelDic[j[3]] = [pos,pit,vol]#本通道开始位置，音高，音量
				else:
					var noteNow = channelDic[j[3]]
					nlen = j[4] - noteNow[0]
					noteSet.append([track,noteNow[0],nlen,noteNow[1],noteNow[2],j[3]])
					pos = 0
					pit = 0
					vol = 0
					channelDic[j[3]] = [pos,pit,vol]#本通道开始位置，音高，音量
					
#	noteSet.reverse()
	notePosList.append([noteSet,others]) 
				
func sort_ascending(a, b):
	if a[1] < b[1]:
		return true
	return false

	
	
func setTrack():
	var trackNum = 0
	var trackOffset = [0,0]
	for i in data["轨道"]:
		if trackNum != 0:
			var trackNode:Control = $track.duplicate()
			trackNode.visible = true
			trackOffset[0] += trackDis[0]
			trackOffset[1] += trackDis[1]
			trackNode.position.x += trackOffset[0]
			trackNode.position.y += trackOffset[1]
			
			tracklist.append(trackNode)
			add_child(trackNode)
		trackNum += 1
		



var start = false
var played = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if start == true:
		if audioNode.playing == false && played == false:
			audioNode.play()
			played = true
			
	if played == true :
		nowTime = audioNode.time
	
#	print(nowTime)
	allowArea[1] = (nowTime + foreTime)/sPerTick
	allowArea[0] = (nowTime - waitTime) /sPerTick
#	print(allowArea,nowTime)
	showAreaNote(0,0)
	
	for t in tracklist:
		t.position = Vector2(0, timeDis * nowTime)
#	print(nowTime,allowArea,unShowedNote[1])

func _on_timer_timeout():
	start = true
	pass # Replace with function body.
