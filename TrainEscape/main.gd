extends Spatial

onready var level_data = $"levelLoader"
onready var tileset = $"tileset"
onready var level_view = $"levelView"
# onready var track_follower = $"trackFollower"

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set up subnodes
	level_view.setup(level_data, tileset)
	
	var track_follower = preload("res://TrackFollower.tscn").instance()
	track_follower.setup(level_data, level_view, 13, 21)
	add_child(track_follower)

	#for i in range(0, level_data.get_width() - 1):
	#	for j in range(0, level_data.get_height() - 1):
	#		var track_follower = preload("res://TrackFollower.tscn").instance()
	#		track_follower.setup(level_data, level_view, i, j)
	#		add_child(track_follower)
