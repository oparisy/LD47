extends Spatial

onready var capsule = $MeshInstance

var level_data
var level_view

var track:Curve2D

# Current cell we are on (level coordinates)
var x
var y

# Current position (world coordinates)
var world_pos

# Current length crossed on this cell (from its "entry side")
var lin_pos

func setup(level_data, level_view, init_x, init_y):
	self.level_data = level_data
	self.level_view = level_view

	self.track = build_curve(init_x, init_y)
	
	self.x = init_x
	self.y = init_y
	
	var kind:String = level_data.get_at(init_x, init_y).kind
	print('Set up on a %s at (%d,%d)' % [kind, init_x, init_y])
	
	self.lin_pos = 0.5
		
	self.world_pos = level_view.get_cell_worldpos(init_x, init_y)
	self.translate(world_pos)

# Build a curve approximating this track
func build_curve(start_x, start_y) -> Curve2D:
	var curve:Curve2D = Curve2D.new()

	var kind:String = level_data.get_at(start_x, start_y).kind
	if kind != 'rail_straight_topbottom':
		push_error('Curve setup did not start on a proper cell!')
		return curve

	var tile_worldsize = level_view.get_tile_worldsize()
	var szby2 = tile_worldsize / 2

	var x = start_x
	var y = start_y
	var direction = 'down'

	while true:
		# Add control points for the current cell and direction
		var center_world:Vector3 = level_view.get_cell_worldpos(x, y)
		var c_2d:Vector2 = Vector2(center_world.x, center_world.z)
		match kind:
			'rail_straight_topbottom', 'rail_straight_leftright':
				# A single point should be enough
				curve.add_point(c_2d)
			'rail_90deg_topleft':
				curve.add_point(c_2d)
			'rail_90deg_topright':
				curve.add_point(c_2d)
			'rail_90deg_bottomleft':
				curve.add_point(c_2d)
			'rail_90deg_bottomright':
				curve.add_point(c_2d)

		# Change direction according to current cell, if needed
		match kind:
			'rail_90deg_topleft':
				direction = 'right' if direction == 'up' else 'down'
			'rail_90deg_topright':
				direction = 'left' if direction == 'up' else 'down'
			'rail_90deg_bottomleft':
				direction = 'right' if direction == 'down' else 'up'
			'rail_90deg_bottomright':
				direction = 'left' if direction == 'down' else 'up'

		# Compute next cell coordinates according to new direction
		match direction:
			'left':
				x -= 1
			'right':
				x += 1
			'up':
				y -= 1
			'down':
				y += 1

		# Fetch new cell kind
		kind = level_data.get_at(x, y).kind

		# print('Now on a %s at (%d,%d)' % [kind, x, y])

		# Are we back to start coordinates?
		if x == start_x && y == start_y:
			break
	return curve

# See https://spencermortensen.com/articles/bezier-circle/
func add_quadrant_control_points(curve, center, radius):
	# Those are for a top right corner
	var c = 0.551915024494
	var P0 = Vector2(0, 1) * radius
	var P1 = Vector2(c, 1) * radius
	var P2 = Vector2(1, c) * radius
	var P3 = Vector2(1, 0) * radius
	
	# We want the curbe to be on the bottom left => translate
	var shift = Vector2(-1, -1)
	# TODO rotate
	
	# Translate
	P0 += center
	P1 += center
	P2 += center
	P3 += center
	
	curve.add_point(P0)
	curve.add_point(P1)
	curve.add_point(P2)
	curve.add_point(P3)

var t = 0.0
var speed = 0.05

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# We want constant speed along the curve, see:
	# https://docs.godotengine.org/en/3.2/tutorials/math/beziers_and_curves.html#traversal
	# TODO Do we need to call .tesselate() before baking?
	t += delta * speed
	
	# Poor man's frac()
	while t > 1:
		t -= 1
	var pos = track.interpolate_baked(t * track.get_baked_length(), true)
	var world_pos = Vector3(pos.x, self.translation.y, pos.y)
	self.set_translation(world_pos)
