extends Node2D

var cards_in_pile: int = 0
var cards_up_in_pile: int = 0
var pile_index: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_amount() -> int:
	return cards_in_pile

func get_up_amount() -> int:
	cards_up_in_pile = 0
	for child in get_children():
		if child.is_in_group("cards"):
			if child.is_face_up:
				cards_up_in_pile += 1
	print("pile: " + str(pile_index) + "     cards_up: " + str(cards_up_in_pile))
	return cards_up_in_pile

func update_outline():
	cards_in_pile = 0
	for child in get_children():
		if child.is_in_group("cards"):
			cards_in_pile += 1
	
	var drop_area = get_node_or_null("DropArea")
	if drop_area:
		var outline = drop_area.get_node_or_null("OutlineRect2D")
		if outline:
			outline.visible = cards_in_pile == 0
