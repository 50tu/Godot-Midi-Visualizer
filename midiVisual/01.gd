extends Node2D

var filePath = "res://res/midi/60.mid"
var file
const MidiStart = "4d 54 68 64" #MThd
const trackStart = "4d 54 72 6b" #MTrk
const trackEnd = "ff 2f 00" #MTrk
var midiType :int#0: 单轨，1：多轨同时，2：多轨一个接一个
var midiTrackNum : int#轨道数
var baseTime:Array #[事件类型，去掉高位,后面全部加起来]
var trackList:Array #[MidiTrack类，，，]
var parsedData :Dictionary


class MidiTrack:
	var trackData
	static var trackLength:int
	var blockData = []#事件解析
	func _init(data,Num):
		trackLength = readByte2Int(0,4,data)
#const trackEnd = "ff 2f 00" #MTrk		
		var end = "".join(trackEnd.split(" "))
		if (data.find(end)-8)/2 +3 != trackLength:
			print("轨道长度不对")
		else :
			trackData = readByteString(4,4+trackLength-3,data)	
		
		var nowPos = 0
		while nowPos < trackLength-4:
			if is_meta(nowPos):
				nowPos = readByteMeta(nowPos,trackData)
			else:
				nowPos =  readByteTime(nowPos,trackData)#读取tick
				var is_note = on_off(nowPos)#音符开关判定加元素并返回位置
				if is_note == -1:#不是音符
					print("note事件有问题")
				else :
					nowPos = is_note #跳位置
#		print("分析后轨道： %s, 轨道长度： %s，轨道内容： %s"%[blockData,trackLength,trackData])
	func on_off(now):
		var newByte = readByteString(now,now+1,trackData)
		match newByte[0]:
			"8":#关音符
				var pitch = readByte2Int(now+1,now+2,trackData)
				var volum = readByte2Int(now+2,now+3,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([0,pitch,volum,channel])
#				print([0,pitch,volum,channel,newByte],)
				return now+3
			"9":#开音符
				var pitch = readByte2Int(now+1,now+2,trackData)
				var volum = readByte2Int(now+2,now+3,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([1,pitch,volum,channel])
#				print([1,pitch,volum,channel,newByte])
				return now+3
			"a":#压力值改变
				var note = readByte2Int(now+1,now+2,trackData)
				var press = readByte2Int(now+2,now+3,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([10,note,press,channel])
#				print([10,note,press,channel,"压力变化"])
				return now+3
			"b":#控制器改变
				var controllernum = readByte2Int(now+1,now+2,trackData)
				var value = readByte2Int(now+2,now+3,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([11,controllernum,value,channel])
#				print([11,controllernum,value,channel,"控制器变化"])
				return now+3
			"c":#音色改变
				var value = readByte2Int(now+1,now+2,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([12,value,channel])
#				print([12,value,channel,"音色变化"])
				return now+2
			"d":#通道压力
				var value = readByte2Int(now+1,now+2,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([13,value,channel])
#				print([13,value,channel,"通道压力"])
				return now+2
			"e":#弯音
				var value1 = readByte2Int(now+1,now+2,trackData)
				var value2 = readByte2Int(now+2,now+3,trackData)
				var channel = newByte[1].hex_to_int()
				blockData.append([14,value1,value2,channel])
#				print([14,value1,value2,channel,"弯音"])
				return now+3
			"f":#系统用
				match newByte[1]:
					"0":
						var pointer = now + 1
						var nextByte = readByteString(pointer,pointer+1,trackData)
						while (nextByte != "f7"):
							pointer += 1
							nextByte = readByteString(pointer,pointer+1,trackData)
#							print(nextByte)
						return pointer + 1
					"f":
#						print(readByteString(now-2,now+4,trackData),"重置事件",newByte)
						now = readByteMeta(now-1,trackData)
						return now 
					_:
						print(readByteString(now,now+2,trackData),"系统")
						return -1
						
				
			_:
				print(readByteString(now,now+2,trackData))
				return -1
			
	func is_meta(now):
		var  a = readByteString(now,now+2,trackData)
		return readByteString(now,now+2,trackData) == "00ff"
	func metaParse(nowPos,type,data):
		match type:
			2: #版权信息
				var metaLength = readByte2Int(nowPos+3,nowPos+4,data)
				var Content = readByteString(nowPos+4,nowPos+4+metaLength,data)
				return [nowPos+4+metaLength,[Content.hex_decode().get_string_from_utf8(),"版权信息,顺便说，本工程由50兔制作"]]
			3: #命名
				var metaLength = readByte2Int(nowPos+3,nowPos+4,data)
				var Content = readByteString(nowPos+4,nowPos+4+metaLength,data)
				return [nowPos+4+metaLength,[Content.hex_decode().get_string_from_utf8(),"轨道名称"]]
			4: #乐器名
				var metaLength = readByte2Int(nowPos+3,nowPos+4,data)
				var Content = readByteString(nowPos+4,nowPos+4+metaLength,data)
				return [nowPos+4+metaLength,[Content.hex_decode().get_string_from_utf8(),"乐器名"]]
			5: #歌词
				var metaLength = readByte2Int(nowPos+3,nowPos+4,data)
				var Content = readByteString(nowPos+4,nowPos+4+metaLength,data)
				return [nowPos+4+metaLength,[Content.hex_decode().get_string_from_utf8(),"歌词"]]
			6: #标记
				var metaLength = readByte2Int(nowPos+3,nowPos+4,data)
				var Content = readByteString(nowPos+4,nowPos+4+metaLength,data)
				return [nowPos+4+metaLength,[Content.hex_decode().get_string_from_utf8(),"标记"]]
			7: #剪辑提示
				var metaLength = readByte2Int(nowPos+3,nowPos+4,data)
				var Content = readByteString(nowPos+4,nowPos+4+metaLength,data)
				return [nowPos+4+metaLength,[Content.hex_decode().get_string_from_utf8(),"剪辑提示"]]
			81: #音符控制 0x51
				match readByteString(nowPos+3,nowPos+4,data):
					"03":#音符速度标志
						var Content = readByte2Int(nowPos+4,nowPos+7,data)#四分音符 微秒时长
						return [nowPos+7,[3,Content,"四分音符时长（微秒）"]]
					_:
						return [nowPos+3,"不认识的记号，直接按tick读取了"]
					
			88: #有拍号 0x58
				match readByteString(nowPos+3,nowPos+4,data):
					"04":#拍号
						var Content = readByteString(nowPos+4,nowPos+8,data)#拍号
						var top = readByte2Int(0,1,Content)#分子
						var deno = pow(2,readByte2Int(1,2,Content))#分母
						var clockTickNum = readByte2Int(2,3,Content)#每个时钟的tick数
						var clockNoteNum = readByte2Int(3,4,Content)#每24个时钟对应的32分音符数
						Content = [top,deno,clockTickNum,clockNoteNum,"拍号分子、分母，每时钟tick数，每24时钟的32分音符数"]
						return [nowPos+8,[04,Content]]
					_:
						return [nowPos+3,"不认识的记号，直接按tick读取了"]
			89: #升降号 0x59
				match readByteString(nowPos+3,nowPos+4,data):
					"02":#拍号
						var Content = readByteString(nowPos+4,nowPos+6,data)#拍号
						var sharp = readByteString(0,1,Content)#升降号
						var minor = readByte2Int(1,2,Content)#大小调 0大调
						Content = [sharp,minor,"升降号，大小调"]
						return [nowPos+6,[02,Content]]
					_:
						return [nowPos+3,"不认识的记号，直接按tick读取了"]
			_:
				print(readByteString(nowPos-2,nowPos+2,data),[readByteString(nowPos,nowPos+1,data)])
				return [nowPos+3,"不认识的记号，直接按tick读取了"]
	func readByteMeta(n,data):
		var nowPos = n
		var metaType = readByte2Int(nowPos+2,nowPos+3,data)
#		print(readByteString(nowPos,nowPos+3,data))
		var metaConParse = metaParse(nowPos,metaType,data)
		var eventParse = [metaType,metaConParse[1]]
		blockData.append(eventParse)
		nowPos = metaConParse[0]
		print("发生事件： %s， 当前位置：%s"%[eventParse,nowPos])
		return nowPos
	func readByteTime(n,data) :
		var now = n
		var nowByte = readByte2Int(now,now+1,data)#先读
		var readNum = 0 #当前的数
		var commandType = true
		
		while commandType :
			if nowByte >= 128:#如果是高位
				commandType = true#最高位1 高位数字 允许读下一个
				nowByte -=128
				now += 1 #读下一个数字用
				readNum = readNum *128 +nowByte #之前的进位，本次加上
				nowByte = readByte2Int(now,now+1,data) #读下一个
			else:
				commandType = false#最后一次读取
				readNum = readNum *128 +nowByte
				now += 1	
		blockData.append(["tick数",readNum])
#		print("现在读出的字节是：%s,当前位置：%s，所得时间为 %s"%[readByteString(n,now,data),now,readNum])
		return now
	
	func readByteString(start,end,data)->String:
		var stringhead = ""
		for i in range(start*2 , end *2):
			stringhead += data[i]
		return stringhead
	func readByte2Int(start,end,data)->int:
		var stringhead = ""
		for i in range(start*2 , end *2):
			stringhead += data[i]
		return stringhead.hex_to_int()

func _ready():
	readfile()
#	print(parsedData)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func readByte2Int(start,end)->int:
	var stringhead = "0x"
	for i in range(start*2 , end *2):
		stringhead += file[i]
	return stringhead.hex_to_int()
func readByteString(start,end)->String:
	var stringhead = ""
	for i in range(start*2 , end *2):
		stringhead += file[i]
	return stringhead
func readByteEvent(start,end) ->Array:
	var readSplitByte = readByteString(start,end).hex_decode()#[8位数字的int, ,]
#	var readSplitByte = "01e0".hex_decode()#[8位数字的int, ,]
	var commandType = false
	if readSplitByte[0] >= 128:
		commandType = true
		readSplitByte[0] = readSplitByte[0] - 128
	var eventNum :int = 0
	for i in readSplitByte:
		eventNum = eventNum * 256 +i 
	return [commandType,readSplitByte,eventNum]
		

func readfile():
	file = FileAccess.get_file_as_bytes(filePath).hex_encode() 
	if file == "":
		print("没有这个文件，路径错误")
	var track = "".join(trackStart.split(" "))
	var start = "".join(MidiStart.split(" "))
	var headlength ="0x"
	var MidiHead = ""
	
	if file.find(start) == 0:
		print("Midi读取成功")
	else :
		print("不是标准Midi文件",readByteString(0,8))
		
	headlength = readByte2Int(4,8)#头长
	MidiHead = readByteString(8,8+headlength)#头内容
	midiType = readByte2Int(8,10)#midi播放类型
	midiTrackNum = readByte2Int(10,12)#轨道数
	baseTime = readByteEvent(12,14)#[事件类型，去掉高位,后面全部加起来]
	var timeString = ""
	

	if baseTime[0] :#高位1
		timeString = "每秒帧数 %s,每帧tick数 %s"%[baseTime[1][0],baseTime[1][1]]
		
	else :#高位0
		timeString = "四分音符tick数 %s"%baseTime[2]
		

	var tracksData:Array = file.split(track)
	tracksData.remove_at(0)
	var trackOrder = 0
	trackList = []
	for i in tracksData:
		trackOrder += 1
		trackList.append(MidiTrack.new(i,trackOrder).blockData)
		pass

	parsedData["midi播放类型"] = midiType
	parsedData["实际轨道数"] = midiTrackNum -1
	parsedData["时间计数方式"] = baseTime
	parsedData["轨道"] = trackList
	
	
	if baseTime[0] :#高位1
		timeString = "每秒帧数 %s,每帧tick数 %s"%[baseTime[1][0],baseTime[1][1]]
		
		parsedData["每tick的微秒"] = 1.0/(baseTime[1][0] * baseTime[1][1]) #1.0/每秒tick数
		
	else :#高位0
		var timePerQuarter = []
		for j in trackList:
			for i in j:
				if int(i[0]) == 81:
#					print(timePerQuarter,"sdfsfdssadada",i)
					if i[1][0] == 3:
						timePerQuarter.append(i[1][1])
#						print(timePerQuarter,"sdfsfds",i)
		parsedData["每tick的微秒"] = float(timePerQuarter[0])/baseTime[2]
		print(timePerQuarter)
		timeString = "四分音符tick数 %s"%baseTime[2]
	var sharpMinor
	for i in trackList[0]:
#		print(i)
		if int(i[0]) == 89:
			if i[1][0] == 2:
				sharpMinor = i[1][1]
				parsedData["调号"] = sharpMinor
#	print("Midi头长度为： %s,内容为： %s \n 播放类型为： %s，轨道数为： %s, 基础时间为： %s
#Track分别为%s"%
#	[headlength,MidiHead,midiType,midiTrackNum,timeString,tracksData])
