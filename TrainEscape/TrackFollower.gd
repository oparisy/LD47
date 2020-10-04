extends Node

var level_data
var level_view

# An array of Vector2 representing waypoints
var track:Array

# Where we started tracking
var init_x
var init_y

# Call this once
func setup(level_data, level_view, init_x, init_y):
	self.level_data = level_data
	self.level_view = level_view
	self.init_x = init_x
	self.init_y = init_y

	self.track = _build_curve(init_x, init_y)
	var kind:String = level_data.get_at(init_x, init_y).kind
	print('Set up on a %s at (%d,%d)' % [kind, init_x, init_y])


# "Allocate" a new tracking entity at start location
func track_new() -> Dictionary:
	var entity = {}
	entity.x = init_x
	entity.y = init_y
	
	# Current track segment; we are between idx and (idx+1)%count
	entity.idx = 0
	
	# Current length crossed on this segment so far
	entity.seg_crossed_already = 0
	entity.direction = Vector2(0, 1) # Downward

	entity.world_pos = level_view.get_cell_worldpos(init_x, init_y)
	return entity


# Move entity along the path by "to_cross" linear units
# var speed = 5
# var to_cross = delta * speed
func advance(entity, to_cross):
	var remaining = to_cross
	if remaining <= 0:
		# Should not happen but hey
		return

	var p0:Vector2
	var p1:Vector2
	var seg:Vector2
	var seg_len

	while remaining > 0:
		# Get the length of the current segment
		p0 = track[entity.idx]
		p1 = track[(entity.idx + 1) % track.size()]
		seg = p1 - p0
		seg_len = seg.length()
		
		# Substract already crossed length
		var remaining_seg = seg_len - entity.seg_crossed_already
		
		if remaining_seg > remaining:
			# We've found the proper segment
			entity.seg_crossed_already += remaining
			remaining = 0
		else:
			# We need to go further
			remaining -= remaining_seg
			entity.seg_crossed_already = 0
			entity.idx = (entity.idx + 1) % track.size()

	# We found the proper segment
	# Deduce a position from how much it is crossed already
	var pos = p0.linear_interpolate(p1, entity.seg_crossed_already / seg_len)
	entity.world_pos = Vector3(pos.x, entity.world_pos.y, pos.y)
	var dir2d = seg.normalized()
	entity.direction = seg.normalized()


# Build a list of points approximating this track
func _build_curve(start_x, start_y) -> Array:
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
		
		var left:Vector2 = c_2d + Vector2(-1, 0)
		var right:Vector2 = c_2d + Vector2(1, 0)
		var top:Vector2 = c_2d + Vector2(0, -1)
		var bottom:Vector2 = c_2d + Vector2(0, 1)
		
		var bottom_left = c_2d + Vector2(-1, 1)
		var bottom_right = c_2d + Vector2(1, 1)
		var top_right = c_2d + Vector2(1, -1)
		var top_left = c_2d + Vector2(-1, -1)
		
		var diag = cos(PI/4) * szby2 # x/y rel coord of "circle middle"

		match kind:
			'rail_straight_topbottom', 'rail_straight_leftright':
				# A single point should be enough
				curve.append(c_2d)
			'rail_90deg_topleft':
				# Approximate curves with two segments
				var mid = bottom_right + Vector2(-diag, -diag)
				if direction == 'up':
					curve.append(bottom)
					curve.append(mid)
					curve.append(right)
				else:
					curve.append(right)
					curve.append(mid)
					curve.append(bottom)
			'rail_90deg_topright':
				var mid = bottom_left + Vector2(diag, -diag)
				if direction == 'up':
					curve.append(bottom)
					curve.append(mid)
					curve.append(left)
				else:
					curve.append(left)
					curve.append(mid)
					curve.append(bottom)
			'rail_90deg_bottomleft':
				var mid = top_right + Vector2(-diag, diag)
				if direction == 'down':
					curve.append(top)
					curve.append(mid)
					curve.append(right)
				else:
					curve.append(right)
					curve.append(mid)
					curve.append(top)
			'rail_90deg_bottomright':
				var mid = top_left + Vector2(diag, diag)
				if direction == 'down':
					curve.append(top)
					curve.append(mid)
					curve.append(left)
				else:
					curve.append(left)
					curve.append(mid)
					curve.append(top)

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
