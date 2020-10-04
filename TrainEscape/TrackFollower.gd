extends Spatial

onready var capsule = $MeshInstance

var level_data
var level_view

# Current cell we are on (level coordoniates)
var x
var y

# Current position (world coordinates)
var world_pos

# Current length crossed on this cell (from its "entry side")
var lin_pos

func setup(level_data, level_view, init_x, init_y):
	self.level_data = level_data
	self.level_view = level_view
	self.x = init_x
	self.y = init_y
	
	var kind:String = level_data.get_at(init_x, init_y).kind
	print('Set up on a %s at (%d,%d)' % [kind, init_x, init_y])
	
	self.lin_pos = 0.5
		
	self.world_pos = level_view.get_cell_worldpos(init_x, init_y)
	self.translate(world_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
