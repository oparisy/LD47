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
		bogie.view = preload('res://bogie.tscn').instance()
		# bogie.view = preload('res://TrackPlaceholder.tscn').instance()
		track_follower.advance(bogie.tracking_info, i * gap)
		update_bogie_view(bogie)
		bogies.append(bogie)
		add_child(bogie.view)

func update_bogie_view(bogie):
	var tp = bogie.tracking_info.world_pos
	var pos_node:Spatial = bogie.view.get_child(0) # glb import adds an extra level (root Spatial)
	var pos = Vector3(tp.x, pos_node.translation.y, tp.z) # Preserve elevation
	var rot = (bogie.tracking_info.direction as Vector2).angle_to(Vector2(0, 1))

	pos_node.set_translation(pos)
	pos_node.set_rotation(Vector3(0, rot, 0))

func _process(delta):
	var to_cross = delta * speed
	for bogie in bogies:
		track_follower.advance(bogie.tracking_info, to_cross)
		update_bogie_view(bogie)
