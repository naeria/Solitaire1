extends Node2D

var CARD_OFFSET: float = Global.card_offset

var CardScene := preload("res://Scenes/Card.tscn")
var suits := ["spades", "hearts", "diamonds", "clubs"]
var deck := []

func _ready():
	seed(11111)
	
	generate_deck()
	shuffle_deck()
	deal_to_tableau()

func generate_deck():
	deck.clear()
	for suit in suits:
		for rank in range(1, 14):  # 1 (Ace) to 13 (King)
			var card = CardScene.instantiate()
			card.suit = suit
			card.rank = rank
			deck.append(card)

func shuffle_deck():
	deck.shuffle()

func deal_to_tableau():
	for i in range(7):
		var pile_name = "Pile" + str(i + 1)
		var pile = $Tableau.get_node(pile_name)
		var total_cards = i + 1
		var y_offset = 0  # start offset for vertical stacking

		for j in range(total_cards):
			if deck.size() == 0:
				return  # or break

			var card = deck.pop_front()
			pile.add_child(card)

			var is_top = (j == total_cards - 1)
			card.set_face_up(is_top)

			# If it's a single-card pile, place at y = 0
			if total_cards == 1:
				card.position = Vector2(0, 0)
			else:
				card.position = Vector2(0, y_offset)

			card.z_index = j

			# Only increase offset if this is not a single-card pile
			if total_cards != 1:
				y_offset += CARD_OFFSET


func _on_drop_area_mouse_entered() -> void:
	pass # Replace with function body.


func _on_drop_area_mouse_exited() -> void:
	pass # Replace with function body.
