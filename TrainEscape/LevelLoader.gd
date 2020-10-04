extends Node

export var path = 'res://assets/level.png'

var width
var height

# An array of array of dictionary
var data:Array = []

# Load level bitmap data, fill data structures
func _ready():

	# Load the level bitmap
	var image:Image = load(path)
	image.lock() # Required for reading pixels
	width = image.get_width()
	height = image.get_height()
	print('Level bitmap size: (', width, ',', height, ')')

	# Loop on image data to instanciate tiles
	for x in range(0, width - 1):
		data.append([])
		for y in range(0, height - 1):
			var entry = {}
			data[x].append(entry)
			
			var color:Color = image.get_pixel(x, y)
			var rgba:int = color.to_rgba32()
			match rgba:
				0x00000000:
					entry.kind = 'base'
				0x000000ff:
					entry.kind = 'rock'
				0xfbf236ff:
					entry.kind = 'rail_90deg_topleft'
				0xeec39aff:
					entry.kind = 'rail_90deg_topright'
				0xac3232ff:
					entry.kind = 'rail_90deg_bottomleft'
				0xdf7126ff:
					entry.kind = 'rail_90deg_bottomright'
				0x323c39ff:
					entry.kind = 'rail_straight_leftright'
				0x37946eff:
					entry.kind = 'rail_straight_topbottom'
				_:
					print('Unhandled bitmap color: %08x' % rgba)

func get_width():
	return width

func get_height():
	return height

func get_at(x, y):
	return data[x][y]
