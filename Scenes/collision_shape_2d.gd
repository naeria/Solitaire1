extends CollisionShape2D

var collision_shape: CollisionShape2D

func _ready():
	# Now you can safely get the node and perform operations on it.
	collision_shape = get_node_or_null("CollisionShape2D")
	
	if collision_shape:
		# Get the current size of the collision shape
		var original_size = collision_shape.shape.size
		
		# Set a larger size (e.g., 2x the original size)
		var new_size = Vector2(original_size.x * 2, original_size.y * 2)
		collision_shape.shape.size = new_size
