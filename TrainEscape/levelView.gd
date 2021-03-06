extends Spatial

var level_data

# The width and height in world units of a tile
var tile_worldsize = 2

func setup(level_data, tileset):
	self.level_data = level_data

	# Load and prepare imported tiles scene
	# var scene = preload("res://tileset.tscn").instance()
	var tiles = loadTiles(tileset)

	# Remove any level placeholder (used to place camera properly in editor)	
	for child in self.get_children():
		(child as Node).queue_free()

	# Loop on level data to instanciate tiles
	var width = level_data.get_width()
	var height = level_data.get_height()
	print('Level size: (', width, ',', height, ')')
	for x in range(0, width - 1):
		for y in range(0, height - 1):
			var cell = level_data.get_at(x, y)
			var tr = get_cell_worldpos(x, y)
			addTileForCell(cell, tiles, self, tr)

func get_tile_worldsize() -> int:
	return tile_worldsize

# Return the translation from the origin to this cell
func get_cell_worldpos(x, y) -> Vector3:
	var width = level_data.get_width()
	var height = level_data.get_height()
	return Vector3(tile_worldsize*(x - width/2), 0, tile_worldsize*(y - height/2))

func addTileForCell(entry:Dictionary, tiles, level:Node, tr:Vector3):
	var kind:String = entry.kind
	var instance:Spatial
	var roty = 0
	match kind:
		'base':
			instance = tiles['base'].instance()
		'rock':
			instance = tiles['rock'].instance()
		'rail_90deg_topleft':
			# To bottom and right ("top left corner")
			instance = tiles['rail_90deg'].instance()
			roty = PI
		'rail_90deg_topright':
			# To bottom and left ("top right corner")
			instance = tiles['rail_90deg'].instance()
			roty = PI/2
		'rail_90deg_bottomleft':
			# To top and right ("bottom left corner")
			instance = tiles['rail_90deg'].instance()
			roty = 3*PI/2
		'rail_90deg_bottomright':
			# To top and left ("bottom right corner")
			instance = tiles['rail_90deg'].instance()
		'rail_straight_leftright':
			# Left to right
			instance = tiles['rail_straight'].instance()
			roty = PI/2
		'rail_straight_topbottom':
			#Top to bottom
			instance = tiles['rail_straight'].instance()
		_:
			print('Unhandled cell kind: %s' % kind)
			return

	instance.translate(tr)
	instance.rotate_y(roty) # This is applied first, and we reset x,z to 0

	level.add_child(instance)


# Build a name => PackedScene dictionnary for each direct child of this scene
# TODO It would be nie for a separate scene script to handle this
func loadTiles(scene:Node):
	var result = {}
	for child in scene.get_children():
		# Required or pack() will not save grandchildren and below
		# https://godotengine.org/qa/903/how-to-save-a-scene-at-run-time
		# "A node can have any other node as owner (as long as it is a valid parent,
		# grandparent, etc. ascending in the tree). When saving a node (using
		# PackedScene), all the nodes it owns will be saved with it"
		setChildrenOwner(child)
		
		# Reset location (so that we do not have to model tiles at the origin)
		var node:Spatial = child
		node.translation.x = 0
		node.translation.z = 0

		# Build a PackedScene to store this child
		var newScene = PackedScene.new()
		var status = newScene.pack(child)
		if status != OK:
			push_error("An error occured while packing the scene")

		# Save the generated scene (testing purpose)
		#var error = ResourceSaver.save("res://testSave.scn", newScene)
		#if error != OK:
		#	push_error("An error occurred while saving the scene to disk.")

		var name = child.get_name()
		result[name] = newScene
		print('Extracted tile ', name)
	return result

# Recursively set the "owner" property of children of this node
func setChildrenOwner(root):
	setChildrenOwnerRec(root.get_children(), root)

func setChildrenOwnerRec(nodes, root):
	for node in nodes:
		node.set_owner(root)
		setChildrenOwnerRec(node.get_children(), root);
