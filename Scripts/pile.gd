extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_outline():
	print("Called update_outline on", name)
	var card_count = 0
	for child in get_children():
		if child.is_in_group("cards"):
			card_count += 1

	var drop_area = get_node_or_null("DropArea")
	if drop_area:
		var outline = drop_area.get_node_or_null("OutlineRect2D")
		if outline:
			outline.visible = card_count == 0
			print("Outline for", name, "visible:", outline.visible)
