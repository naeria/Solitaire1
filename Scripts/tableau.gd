extends Node2D


# Called when the node enters the scene tree for the first time.
# Attach this script to Tableau to auto-position piles
func _ready():
	var spacing = 150
	for i in range(7):
		var pile = get_node("Pile" + str(i + 1))
		pile.position = Vector2(100 + spacing * i, 300)
