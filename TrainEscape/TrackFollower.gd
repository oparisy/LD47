extends Spatial

onready var capsule = $MeshInstance

var level_data
var level_view

var track:Array # An array of Vector2

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

# Build a list of points approximating this track
func build_curve(start_x, start_y) -> Array:
	var curve:Array = []

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
				curve.append(c_2d)
			'rail_90deg_topleft':
				curve.append(c_2d)
			'rail_90deg_topright':
				curve.append(c_2d)
			'rail_90deg_bottomleft':
				curve.append(c_2d)
			'rail_90deg_bottomright':
				curve.append(c_2d)

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

var t = 0.0
var speed = 5

 # Current track segment; we are between idx and (idx+1)%count
var idx = 0

# Current length crossed on this segment so far
var seg_crossed_already = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	# How much we want to cross at this step
	t += delta
	var to_cross = delta * speed

	var remaining = to_cross
	if remaining <= 0:
		# Should not happen but hey
		pass

	var p0:Vector2
	var p1:Vector2
	var seg_len

	while remaining > 0:
		# Get the length of the current segment
		p0 = track[idx]
		p1 = track[(idx+1) % track.size()]
		var seg:Vector2 = p1 - p0
		seg_len = seg.length()
		
		# Substract already crossed length
		var remaining_seg = seg_len - seg_crossed_already
		
		if remaining_seg > remaining:
			# We've found the proper segment
			seg_crossed_already += remaining
			remaining = 0
		else:
			# We need to go further
			remaining -= remaining_seg
			seg_crossed_already = 0
			idx = (idx+1) % track.size()

	# We found the proper segment
	# Deduce a position from how much it is crossed already
	var pos = p0.linear_interpolate(p1, seg_crossed_already / seg_len)
	var world_pos = Vector3(pos.x, self.translation.y, pos.y)
	self.set_translation(world_pos)
