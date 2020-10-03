extends Spatial


# Called when the node enters the scene tree for the first time.
func _ready():
	# Load and instanciate imported tiles scene
	# (there is not much than can be done with a PackedScene)
	var scene = preload("res://tileset.tscn").instance()
	print('Scene instance children: ', scene.get_child_count())
	
	# Find first child
	var firstChild = scene.get_child(0)

	# Required or pack() will not save grandchildren and below
	# https://godotengine.org/qa/903/how-to-save-a-scene-at-run-time
	# "A node can have any other node as owner (as long as it is a valid parent,
	# grandparent, etc. ascending in the tree). When saving a node (using
	# PackedScene), all the nodes it owns will be saved with it"
	setChildrenOwner(firstChild)
	# add_child(firstChild)

	# Build a PackedScene to store this child
	var newScene = PackedScene.new()
	var result = newScene.pack(firstChild)
	if result != OK:
		push_error("An error occured while packing the scene")

	# Save the generated scene (testing purpose)
	var error = ResourceSaver.save("res://testSave.scn", newScene)
	if error != OK:
		push_error("An error occurred while saving the scene to disk.")

	# Instanciate and add nodes to current scene
	var newInstance:Spatial = newScene.instance()
	add_child(newInstance)
	var newInstance2:Spatial = newScene.instance()
	newInstance2.translate(Vector3(2,0,0))
	add_child(newInstance2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Recursively set the "owner" property of children of this node
func setChildrenOwner(root):
	setChildrenOwnerRec(root.get_children(), root)

func setChildrenOwnerRec(nodes, root):
	for node in nodes:
		node.set_owner(root)
		setChildrenOwnerRec(node.get_children(), root);
