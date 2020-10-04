extends Spatial

onready var level_data = $"levelLoader"
onready var tileset = $"tileset"
onready var level_view = $"levelView"

var track_follower

var bogies = []
var bogies_count = 9
var speed = 5
var gap = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up subnodes
	level_view.setup(level_data, tileset)

	track_follower = preload("res://TrackFollower.tscn").instance()
	track_follower.setup(level_data, level_view, 13, 21)

	for i in range(bogies_count):
		var bogie = {}
		bogie.tracking_info = track_follower.track_new()
		bogie.view = preload('res://TrackPlaceholder.tscn').instance()
		bogie.view.set_translation(bogie.tracking_info.world_pos)
		track_follower.advance(bogie.tracking_info, i * gap)
		bogies.append(bogie)
		add_child(bogie.view)

func _process(delta):
	var to_cross = delta * speed
	for bogie in bogies:
		track_follower.advance(bogie.tracking_info, to_cross)
		bogie.view.set_translation(bogie.tracking_info.world_pos)

	#for i in range(0, level_data.get_width() - 1):
	#	for j in range(0, level_data.get_height() - 1):
	#		var track_follower = preload("res://TrackFollower.tscn").instance()
	#		track_follower.setup(level_data, level_view, i, j)
	#		add_child(track_follower)
